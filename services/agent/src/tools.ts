import { randomUUID } from "node:crypto";
import { lookup as dnsLookup } from "node:dns/promises";
import { isIP } from "node:net";
import { z, type ZodRawShape } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";
import type { SseEvent } from "@openlive/shared";

export type Emit = (e: SseEvent) => Promise<void> | void;

export interface TaktTool {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
  execute: (args: any) => Promise<ToolResult>;
}
export interface ToolResult {
  output: string;
  images?: { data: string; mime: string }[];
  isError?: boolean;
}

const text = (t: string): ToolResult => ({ output: t });

// Minimal HTML → text for fetch_url: drop script/style, strip tags, unescape
// common entities, collapse whitespace.
export function htmlToText(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">").replace(/&#39;/g, "'").replace(/&quot;/g, '"')
    .replace(/\s+/g, " ")
    .trim();
}

// Zod shape → JSON Schema for the model. Inline refs and drop $schema so every
// provider adapter accepts it.
function params(shape: ZodRawShape): Record<string, unknown> {
  const js = zodToJsonSchema(z.object(shape), { $refStrategy: "none" }) as Record<string, unknown>;
  delete js.$schema;
  return js;
}

// fetch_url SSRF guard: block loopback / private / link-local / metadata hosts.
function isPrivateIp(ip: string): boolean {
  if (ip === "::1" || ip.startsWith("fe80:") || ip.startsWith("fc") || ip.startsWith("fd")) return true;
  const p = ip.split(".").map(Number);
  if (p.length !== 4 || p.some((n) => Number.isNaN(n))) return false;
  return p[0] === 127 || p[0] === 10 || p[0] === 0 ||
    (p[0] === 169 && p[1] === 254) ||           // link-local + cloud metadata
    (p[0] === 172 && p[1]! >= 16 && p[1]! <= 31) ||
    (p[0] === 192 && p[1] === 168);
}
async function hostIsPrivate(hostname: string): Promise<boolean> {
  if (isIP(hostname)) return isPrivateIp(hostname);
  if (/^(localhost|.*\.local)$/i.test(hostname)) return true;
  try { const { address } = await dnsLookup(hostname); return isPrivateIp(address); }
  catch { return true; } // unresolvable → refuse
}

// The generic tool set the live agent always has. `look` (camera) is injected
// per-session by LiveSession; register your own tools by passing them to the
// turn runner's `extraTools`.
export function buildTaktTools(ctx: { emit: Emit }): TaktTool[] {
  const { emit } = ctx;

  const updateTodos: TaktTool = {
    name: "update_todos",
    description: "Publish/update a short checklist (3+ steps) shown in the UI; mark items done as you go. Skip for simple answers.",
    parameters: params({ items: z.array(z.object({ text: z.string(), done: z.boolean() })).min(1).max(8) }),
    execute: async (args) => {
      const items = Array.isArray(args?.items) ? args.items.map((i: any) => ({ text: String(i.text ?? ""), done: !!i.done })).filter((i: any) => i.text) : [];
      await emit({ type: "todos", items });
      return text("Checklist updated.");
    },
  };

  const fetchUrl: TaktTool = {
    name: "fetch_url",
    description: "Fetch a public web page and return its readable text. Use when the user asks about a specific URL. Returns plain text (scripts/markup stripped).",
    parameters: params({ url: z.string().describe("The absolute http(s) URL to fetch") }),
    execute: async (args) => {
      const id = randomUUID();
      const raw = String(args.url ?? "").trim();
      await emit({ type: "tool_start", id, tool: "fetch_url", summary: raw });
      let url: URL;
      try { url = new URL(raw); } catch { await emit({ type: "tool_done", id, detail: "bad url" }); return text(`"${raw}" is not a valid URL.`); }
      if (url.protocol !== "http:" && url.protocol !== "https:") { await emit({ type: "tool_done", id, detail: "blocked" }); return text("Only http(s) URLs are allowed."); }
      if (await hostIsPrivate(url.hostname)) { await emit({ type: "tool_done", id, detail: "blocked" }); return text("That host is not allowed (private/loopback/metadata address)."); }
      try {
        const res = await fetch(url, { signal: AbortSignal.timeout(15_000), redirect: "manual", headers: { "user-agent": "OpenLiveBot/1.0" } });
        if (res.status >= 300 && res.status < 400) { await emit({ type: "tool_done", id, detail: "redirect" }); return text("The URL redirected; pass the final URL directly."); }
        if (!res.ok) { await emit({ type: "tool_done", id, detail: `HTTP ${res.status}` }); return text(`Fetch failed: HTTP ${res.status}.`); }
        const body = htmlToText(await res.text()).slice(0, 20_000);
        await emit({ type: "tool_done", id, detail: `${body.length} chars` });
        return text(body || "(no readable text found)");
      } catch (e: any) { await emit({ type: "tool_done", id, detail: "error" }); return text(`Could not fetch: ${String(e?.message ?? e)}`); }
    },
  };

  return [fetchUrl, updateTodos];
}
