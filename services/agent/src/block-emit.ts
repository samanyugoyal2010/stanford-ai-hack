import type { MessageBlock, SseEvent } from "@openlive/shared";

export type Emit = (e: SseEvent) => Promise<void> | void;

// Fold one SSE event into an ordered MessageBlock[] so a turn replays in order on
// reload. Shared by the HTTP chat server and the live-voice session (they used to
// each carry a copy). Pure — the caller owns forwarding over the wire + any gating.
export function foldBlock(blocks: MessageBlock[], e: SseEvent): void {
  switch (e.type) {
    case "text_delta":
    case "reasoning_delta": {
      const kind = e.type === "text_delta" ? "text" : "reasoning";
      const last = blocks[blocks.length - 1];
      if (last && last.type === kind) last.text += e.text;
      else blocks.push({ type: kind, text: e.text });
      break;
    }
    case "tool_start": blocks.push({ type: "tool", id: e.id, tool: e.tool, summary: e.summary, status: "done" }); break;
    case "tool_done": {
      const t = blocks.find((b) => b.type === "tool" && b.id === e.id);
      if (t && t.type === "tool") t.detail = e.detail;
      break;
    }
  }
}

// Fold + forward, serializing writes so concurrent emitters (main agent + a
// background canvas build) can't interleave a half-frame over the SSE stream.
export function makeBlockEmit(write: (e: SseEvent) => Promise<void> | void): { emit: Emit; blocks: MessageBlock[] } {
  const blocks: MessageBlock[] = [];
  let writeChain: Promise<void> = Promise.resolve();
  const emit: Emit = async (e) => {
    foldBlock(blocks, e);
    writeChain = writeChain.then(() => write(e));
    await writeChain;
  };
  return { emit, blocks };
}
