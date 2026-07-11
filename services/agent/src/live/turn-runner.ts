import { streamProvider, isReasoningModel, type Message, type Effort } from "@openlive/harness";
import { buildTaktTools, type TaktTool, type Emit } from "../tools.js";
import { collectTurn } from "../turn.js";
import { buildLivePrompt, type LivePromptOpts } from "../prompt.js";
import { resolveLive, resolveVision, type ResolvedLive } from "../providers.js";
import { runWorker } from "./worker.js";

const TALK_MAX_TOKENS = 384;
const OBSERVE_MAX_TOKENS = 80;
const DESCRIBE_MAX_TOKENS = 96;

type Frame = { data: string; mime: string; source?: "camera" | "screen" };

/** Have the dedicated vision model look at the frames and report what's there. */
export async function describeFrames(
  v: ResolvedLive,
  userText: string,
  frames: Frame[],
  sources: string,
  signal: AbortSignal,
  maxTokens = DESCRIBE_MAX_TOKENS,
): Promise<string> {
  const messages: Message[] = [
    { role: "system", text: `You are the eyes of a voice assistant. In 1-3 tight sentences, state exactly what is visible in the user's ${sources} right now — objects, on-screen text, layout, what the person is doing. No preamble, no "the image". If it's blank or unreadable, say so plainly.` },
    { role: "user", text: userText ? `The user said: "${userText}". What's visible?` : "What's visible right now?", images: frames.map((f) => ({ data: f.data, mime: f.mime })) },
  ];
  const turn = await collectTurn(
    streamProvider(v.provider, v.apiKey ?? undefined, { model: v.model, messages, tools: [], maxTokens }, signal),
    () => {},
  );
  return turn.text.trim();
}

/** Ollama vision / VL models reject the OpenAI `tools` parameter (HTTP 400). */
export function modelSupportsTools(providerId: string, model: string): boolean {
  if (providerId !== "ollama" && providerId !== "ollama-cloud") return true;
  return !/(^|[:/\-_])(vl|vision)([:/\-_]|$)/i.test(model)
    && !/qwen2\.5vl|qwen3-vl|llava|minicpm-v|moondream|llama3\.2-vision|gemma3:.*vision/i.test(model);
}

function isVisionModel(providerId: string, model: string): boolean {
  return !modelSupportsTools(providerId, model) || /vl|vision|llava|minicpm-v|moondream/i.test(model);
}

/** Parse streamed tool-arg JSON; tolerate an empty/blank string. */
function safeParseArgs(s: string): any {
  const t = (s ?? "").trim();
  if (!t) return {};
  try { return JSON.parse(t); } catch { return {}; }
}

function parseObserveReply(raw: string): { summary: string; speak: string; silent: boolean } {
  const text = raw.trim().replace(/^["'`]+|["'`]+$/g, "");
  const summaryM = text.match(/SUMMARY:\s*(.+?)(?:\n|$)/i);
  const speakM = text.match(/SPEAK:\s*([\s\S]*?)$/i);
  const summary = (summaryM?.[1] ?? "").trim();
  let speak = (speakM?.[1] ?? "").trim();
  if (!speakM) {
    // Fallback: old SILENCE-only replies
    if (/^SILENCE\b/i.test(text) && text.replace(/^SILENCE\b/i, "").trim().length === 0) {
      return { summary, speak: "", silent: true };
    }
    speak = text;
  }
  const silent = !speak || /^SILENCE\b/i.test(speak);
  if (silent) speak = "";
  else speak = speak.replace(/^SILENCE[,.:\s-]*/i, "").trim();
  return { summary, speak, silent };
}

// Lower than a text chat's step cap ON PURPOSE. Every tool round before the model
// speaks is dead air in a live call, so cap the worst case tightly.
const MAX_STEPS = 6;

const LIVE_TOOL_DENY = new Set<string>([]);

const OBSERVE_VISION_PROMPT = `Look at the student's screen right now.
Reply in EXACTLY this two-line format:
SUMMARY: <one short factual line of what is on screen>
SPEAK: SILENCE
or
SUMMARY: <one short factual line>
SPEAK: <one short Socratic hint or question, one sentence>

Prefer SPEAK: SILENCE when they are progressing, reading, or typing. No markdown.`;

export type ObserveVisionResult = {
  summary: string;
  speak: string;
  silent: boolean;
};

// A per-call LLM driver that keeps a growing Message[] across turns and injects the
// camera frame(s) onto each user turn.
export class LiveTurnRunner {
  private messages: Message[];

  constructor(private extraTools: TaktTool[], promptOpts: LivePromptOpts = {}) {
    this.messages = [{ role: "system", text: buildLivePrompt(promptOpts) }];
  }

  /** Swap the system prompt (Study Tutor config arriving after session open). */
  setPromptOpts(opts: LivePromptOpts) {
    const sys = this.messages[0];
    if (sys?.role === "system") sys.text = buildLivePrompt(opts);
    else this.messages.unshift({ role: "system", text: buildLivePrompt(opts) });
  }

  /** Seed prior conversation (text only) after the system prompt — used on
   *  reconnect so the agent doesn't forget what was already said in the call. */
  seed(history: Message[]) {
    this.messages.splice(1, this.messages.length - 1, ...history);
  }

  /** Prime the provider's prompt cache (system + tools) with a tiny request the
   *  moment the session opens, so the FIRST real user turn is a cache HIT instead of
   *  a cold prefill (the biggest first-token latency lever — see anthropic.ts). Best
   *  effort: if it fails the first turn just pays the normal cold price. */
  async warm(signal: AbortSignal): Promise<void> {
    let resolved;
    try { resolved = resolveLive(); } catch { return; }
    const { provider, model, apiKey } = resolved;
    if (!model || (!apiKey && !provider.keyless)) return;
    const useTools = modelSupportsTools(provider.id, model);
    const tools = useTools
      ? [...buildTaktTools({ emit: async () => {} }), ...this.extraTools].filter((t) => !LIVE_TOOL_DENY.has(t.name))
      : [];
    const toolDefs = tools.map(({ name, description, parameters }) => ({ name, description, parameters }));
    try {
      // maxTokens:1 — we only want the prefill (cache write); the output is discarded.
      const gen = streamProvider(provider, apiKey ?? undefined, { model, messages: this.messages, tools: toolDefs, maxTokens: 1 }, signal);
      for await (const ev of gen) { void ev; if (signal.aborted) break; }
    } catch { /* cold first turn is the fallback */ }
  }

  // Bound the per-call history so a long conversation doesn't grow `messages`
  // unboundedly (Anthropic caching helps but doesn't cap it, and OpenAI has no cache
  // on this path). Cut only at a USER boundary so an assistant tool_use is never
  // separated from its tool_result (providers 400 on an orphaned pair).
  private capHistory() {
    const CAP = 40, KEEP = 30;
    if (this.messages.length <= CAP) return;
    let cut = this.messages.length - KEEP;
    while (cut < this.messages.length && this.messages[cut]!.role !== "user") cut++;
    if (cut > 1 && cut < this.messages.length) this.messages.splice(1, cut - 1);
  }

  /** Resolve which model should "see" for Study Tutor observe (prefer dedicated vision). */
  resolveEyes(): ResolvedLive | null {
    const vision = resolveVision();
    if (vision) return vision;
    try {
      const live = resolveLive();
      if (isVisionModel(live.provider.id, live.model)) return live;
    } catch { /* */ }
    return null;
  }

  /** Fast screen describe for Study Tutor user turns / look tool (text only). */
  async describeScreen(
    frames: Frame[],
    userText: string,
    signal: AbortSignal,
  ): Promise<string> {
    const eyes = this.resolveEyes();
    if (!eyes || !frames.length) return "";
    const sources = [...new Set(frames.map((f) => f.source ?? "screen"))].join(" and ");
    try {
      return await describeFrames(eyes, userText, frames, sources, signal, DESCRIBE_MAX_TOKENS);
    } catch {
      return "";
    }
  }

  /**
   * Study Tutor observe: one short vision call. Parses SUMMARY + SPEAK.
   * Does not use the talk message history (keeps the voice model context small).
   */
  async runObserveVision(frames: Frame[], signal: AbortSignal): Promise<ObserveVisionResult> {
    const eyes = this.resolveEyes();
    if (!eyes || !frames.length) return { summary: "", speak: "", silent: true };
    const { provider, model, apiKey } = eyes;
    if (!model || (!apiKey && !provider.keyless)) return { summary: "", speak: "", silent: true };

    const sources = [...new Set(frames.map((f) => f.source ?? "screen"))].join(" and ");
    const messages: Message[] = [
      { role: "system", text: "You are the eyes of a study tutor. Be brief and factual. Never invent unreadable text." },
      {
        role: "user",
        text: `${OBSERVE_VISION_PROMPT}\n\n(You are looking at the user's ${sources} live.)`,
        images: frames.map((f) => ({ data: f.data, mime: f.mime })),
      },
    ];

    let buffered = "";
    let decided: ObserveVisionResult | null = null;
    const turn = await collectTurn(
      streamProvider(provider, apiKey ?? undefined, { model, messages, tools: [], maxTokens: OBSERVE_MAX_TOKENS }, signal),
      async (e) => {
        if (e.type !== "text_delta") return;
        buffered += e.text;
        // Once SPEAK: is present, decide early — abort remaining tokens if SILENCE.
        if (/SPEAK:\s*SILENCE\b/i.test(buffered)) {
          decided = parseObserveReply(buffered);
          // Can't abort the provider mid-stream via collectTurn easily without signal;
          // signal.abort would cancel the whole observe. Just stop caring about more text.
        } else if (/SPEAK:\s*\S+/i.test(buffered) && !/^SPEAK:\s*SILENCE/im.test(buffered)) {
          // Started a real speak line — keep collecting until done (short maxTokens).
          decided = null;
        }
      },
    );
    if (signal.aborted) return { summary: "", speak: "", silent: true };
    const parsed = decided ?? parseObserveReply(turn.text || buffered);
    return parsed;
  }

  async runTurn(
    userText: string,
    frames: { data: string; mime: string; source?: "camera" | "screen" }[],
    emit: Emit,
    signal: AbortSignal,
    opts: { preferCachedContext?: boolean; screenSummary?: string } = {},
  ): Promise<void> {
    const { provider, model, apiKey, effort } = resolveLive();
    if (!model) { await emit({ type: "error", message: "No model selected. Open Settings and pick a provider + model." }); return; }
    if (!apiKey && !provider.keyless) { await emit({ type: "error", message: `No API key for ${provider.name}. Add one in Settings.` }); return; }

    let text = userText;
    let imgs: { data: string; mime: string }[] | undefined;

    // Study Tutor fast path: text talk model + cached screen summary (no VL prefill).
    if (opts.preferCachedContext) {
      if (opts.screenSummary?.trim()) {
        text = `${userText}\n\n[Recent screen context (from your eyes — talk about it naturally, don't mention "the image"): ${opts.screenSummary.trim()}]`;
      }
      // Never attach raw frames on this path — that's what made VL talk slow.
    } else if (frames.length) {
      const sources = [...new Set(frames.map((f) => f.source ?? "camera"))].join(" and ");
      const vision = resolveVision();
      let described = "";
      if (vision && vision.model !== model) {
        try { described = await describeFrames(vision, userText, frames, sources, signal); } catch { /* fall back to frames */ }
        if (signal.aborted) return;
      }
      if (described) {
        text = `${userText}\n\n[A vision model is looking at the user's ${sources} live right now and reports: ${described}\nTalk about what's actually there, naturally — as what you're both looking at. Don't mention "the image" or that another model described it.]`;
      } else {
        text = `${userText}\n\n[You're viewing the user's ${sources} live right now — talk about what's actually there, not "the image". If you truly can't make it out or got no picture, say so plainly and never invent details.]`;
        imgs = frames.map((f) => ({ data: f.data, mime: f.mime }));
      }
    }

    this.messages.push({ role: "user", text, images: imgs });
    // Keep frames only on the most recent user turn (cost + latency).
    const withImgs = this.messages.filter((m) => m.role === "user" && m.images?.length);
    for (const m of withImgs.slice(0, -1)) if (m.role === "user") m.images = undefined;

    const useTools = modelSupportsTools(provider.id, model);
    const tools = useTools
      ? [...buildTaktTools({ emit, signal, runWorker }), ...this.extraTools].filter((t) => !LIVE_TOOL_DENY.has(t.name))
      : [];
    const toolDefs = tools.map(({ name, description, parameters }) => ({ name, description, parameters }));

    const reasons = isReasoningModel(model);
    const reasoning = !reasons ? {}
      : effort ? (provider.protocol === "openai" ? { reasoningEffort: effort as string } : { effort: effort as Effort })
        : provider.protocol === "openai" ? { reasoningEffort: "minimal" as const }
          : {};

    let partial = "";
    const track: Emit = (e) => { if (e.type === "text_delta") partial += e.text; return emit(e); };

    try {
      for (let step = 0; step < MAX_STEPS; step++) {
        if (signal.aborted) return;
        partial = "";
        const turn = await collectTurn(
          streamProvider(provider, apiKey ?? undefined, { model, messages: this.messages, tools: toolDefs, ...reasoning, maxTokens: TALK_MAX_TOKENS }, signal),
          track,
        );
        this.messages.push({
          role: "assistant",
          text: turn.text,
          reasoning: turn.reasoning || undefined,
          reasoningSignature: turn.reasoningSignature,
          toolCalls: turn.toolCalls.length ? turn.toolCalls : undefined,
        });
        await emit({ type: "usage", contextTokens: turn.usage.input, outputTokens: turn.usage.output, costUsd: 0 });
        if (!turn.toolCalls.length) break;
        const runOne = async (tc: (typeof turn.toolCalls)[number]) => {
          const tool = tools.find((t) => t.name === tc.name);
          if (!tool) return { tc, res: { output: `Unknown tool "${tc.name}".`, isError: true as const } };
          try { return { tc, res: await tool.execute(safeParseArgs(tc.arguments)) }; }
          catch (e: any) { return { tc, res: { output: `Error: ${String(e?.message ?? e)}`, isError: true as const } }; }
        };
        const results = await Promise.all(turn.toolCalls.map(runOne));
        if (signal.aborted) return;
        for (const { tc, res } of results) {
          this.messages.push({ role: "tool", callId: tc.id, name: tc.name, result: res.output, images: res.images, isError: res.isError });
        }
      }
    } catch (e: any) {
      if (signal.aborted) {
        if (partial.trim()) this.messages.push({ role: "assistant", text: partial.trim() });
        return;
      }
      const raw = String(e?.message ?? e);
      const msg = /quota|insufficient|billing/i.test(raw)
        ? `${provider.name}: API quota exhausted — add billing, or pick a different model in Settings.`
        : /invalid api key|authentication|401|403|unauthor|x-api-key|forbidden/i.test(raw)
          ? `${provider.name} rejected the API key — update it in Settings.`
          : `Live model error: ${raw}`;
      await emit({ type: "error", message: msg });
    }
    this.capHistory();
  }
}
