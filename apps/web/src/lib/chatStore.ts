"use client";

import { create } from "zustand";
import type { SseEvent } from "@openlive/shared";

// Minimal transcript store for the live call. useLiveSession drives it
// imperatively (liveUserTurn / liveSetText / liveApply / liveFinish); the
// TranscriptPanel reads it via useChat(). Assistant text is set word-by-word,
// paced to the VOICE (not the generated stream), so it always equals what was
// actually spoken — honest on barge-in.

export interface ToolUse { id?: string; tool: string; summary?: string; detail?: string }
export interface ChatMsg {
  id: string;
  role: "user" | "assistant";
  text: string;
  tools: ToolUse[];
  done: boolean;
}

interface ChatState {
  byChat: Record<string, ChatMsg[]>;
  _set: (chatId: string, fn: (msgs: ChatMsg[]) => ChatMsg[]) => void;
}

let seq = 0;
const nextId = () => `m${++seq}`;

const useChatState = create<ChatState>((set) => ({
  byChat: {},
  _set: (chatId, fn) =>
    set((s) => ({ byChat: { ...s.byChat, [chatId]: fn(s.byChat[chatId] ?? []) } })),
}));

function patch(chatId: string, id: string, fn: (m: ChatMsg) => ChatMsg) {
  useChatState.getState()._set(chatId, (msgs) => msgs.map((m) => (m.id === id ? fn(m) : m)));
}

export const chatStore = {
  // Commit a completed user turn and open a fresh assistant turn; returns its id.
  liveUserTurn(chatId: string, _slug: string | null, text: string): string {
    const userId = nextId();
    const asstId = nextId();
    useChatState.getState()._set(chatId, (msgs) => [
      ...msgs,
      { id: userId, role: "user", text, tools: [], done: true },
      { id: asstId, role: "assistant", text: "", tools: [], done: false },
    ]);
    return asstId;
  },
  // Set the full spoken-so-far text of an assistant turn.
  liveSetText(chatId: string, id: string, text: string) {
    patch(chatId, id, (m) => (m.text === text ? m : { ...m, text }));
  },
  // Fold a non-text SSE event (tool activity) into the assistant turn.
  liveApply(chatId: string, id: string, e: SseEvent) {
    if (e.type === "tool_start") {
      patch(chatId, id, (m) => ({ ...m, tools: [...m.tools, { id: e.id, tool: e.tool, summary: e.summary }] }));
    } else if (e.type === "tool_done") {
      patch(chatId, id, (m) => ({ ...m, tools: m.tools.map((t) => (t.id === e.id ? { ...t, detail: e.detail } : t)) }));
    }
  },
  liveFinish(chatId: string, id: string) {
    patch(chatId, id, (m) => (m.done ? m : { ...m, done: true }));
  },
  reset(chatId: string) {
    useChatState.getState()._set(chatId, () => []);
  },
};

const EMPTY: ChatMsg[] = [];
/** Subscribe a component to a chat's transcript. */
export function useChat(chatId: string): ChatMsg[] {
  return useChatState((s) => s.byChat[chatId] ?? EMPTY);
}
