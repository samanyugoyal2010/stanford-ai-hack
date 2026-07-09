// Domain types shared across the web app and agent service.

// A provider id from the harness registry (BUILTIN_PROVIDERS): "anthropic",
// "openai", "minimax".
export type ProviderKind = string;
export type MessageRole = "user" | "assistant" | "tool";

export interface Provider {
  id: string;
  name: string;
  kind: ProviderKind;
  /** Masked for display — never the plaintext key. */
  keyLast4: string | null;
  hasKey: boolean;
  isDefault: boolean;
}

export interface ChatSummary {
  id: string;
  title: string;
  createdAt: string;
}

/** A persisted/transported message. `content` is an array of blocks (below). */
export interface ChatMessage {
  id: string;
  chatId: string;
  role: MessageRole;
  content: MessageBlock[];
  live?: boolean;
  createdAt: string;
}

export type MessageBlock =
  | { type: "text"; text: string }
  | { type: "reasoning"; text: string }
  | { type: "tool"; id?: string; tool: string; summary?: string; detail?: string; status: "running" | "done" };
