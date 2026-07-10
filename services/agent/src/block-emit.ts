import type { MessageBlock, SseEvent } from "@openlive/shared";

// Fold one agent event into an ordered MessageBlock[] so a turn replays in order on
// reload. Pure — the live session owns forwarding over the wire + any gating.
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
