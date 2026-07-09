import { randomUUID } from "node:crypto";
import type {
  Provider, ChatSummary, ChatMessage,
  ProviderKind, MessageBlock, MessageRole,
} from "@openlive/shared";
import { getDb } from "./connection";
import { encryptSecret, decryptSecret } from "./crypto";

const db = () => getDb();

// ─── Providers ─────────────────────────────────────────────────────────────
function rowToProvider(r: any): Provider {
  return {
    id: r.id, name: r.name, kind: r.kind,
    keyLast4: r.keyLast4, hasKey: !!r.hasKey, isDefault: !!r.isDefault,
  };
}

export function listProviders(): Provider[] {
  return (db().prepare(
    `SELECT id, name, kind, key_last4 AS keyLast4,
            (api_key_ciphertext IS NOT NULL) AS hasKey, is_default AS isDefault
     FROM providers ORDER BY is_default DESC, name`,
  ).all() as any[]).map(rowToProvider);
}

export function createProvider(p: {
  name: string; kind: ProviderKind; apiKey?: string | null; isDefault?: boolean;
}): Provider {
  const id = randomUUID();
  const key = p.apiKey?.trim() || null; // trim: pasted keys often carry a stray space/newline → 401
  const ciphertext = key ? encryptSecret(key) : null;
  const last4 = key ? key.slice(-4) : null;
  if (p.isDefault) db().prepare(`UPDATE providers SET is_default = 0`).run();
  db().prepare(
    `INSERT INTO providers (id, name, kind, api_key_ciphertext, key_last4, is_default)
     VALUES (?,?,?,?,?,?)`,
  ).run(id, p.name, p.kind, ciphertext, last4, p.isDefault ? 1 : 0);
  return listProviders().find((x) => x.id === id)!;
}

export function updateProvider(id: string, p: {
  name?: string; apiKey?: string | null; isDefault?: boolean;
}): Provider | undefined {
  if (p.name !== undefined) db().prepare(`UPDATE providers SET name=? WHERE id=?`).run(p.name, id);
  const key = p.apiKey?.trim(); // trim: pasted keys often carry a stray space/newline → 401
  if (key) {
    db().prepare(`UPDATE providers SET api_key_ciphertext=?, key_last4=? WHERE id=?`)
      .run(encryptSecret(key), key.slice(-4), id);
  }
  if (p.isDefault) {
    db().prepare(`UPDATE providers SET is_default = 0`).run();
    db().prepare(`UPDATE providers SET is_default = 1 WHERE id=?`).run(id);
  }
  return listProviders().find((x) => x.id === id);
}

/** Remove a provider's stored key (so a wrong/stale one can be cleared). */
export function clearProviderKey(id: string): Provider | undefined {
  db().prepare(`UPDATE providers SET api_key_ciphertext=NULL, key_last4=NULL WHERE id=?`).run(id);
  return listProviders().find((x) => x.id === id);
}

/** Server-only: decrypt a provider's API key. Never exposed over HTTP.
 * Tolerant of a decrypt failure (e.g. the enc-key changed after a restart):
 * returns null so the app degrades to "no key set" instead of throwing. */
export function getProviderApiKey(id: string): string | null {
  const row = db().prepare(`SELECT api_key_ciphertext AS c FROM providers WHERE id=?`).get(id) as { c: string | null } | undefined;
  if (!row?.c) return null;
  try { return decryptSecret(row.c); } catch { return null; }
}

// ─── Chats + messages ──────────────────────────────────────────────────────
export function createChat(id?: string, title = "Live conversation"): ChatSummary {
  const chatId = id ?? randomUUID();
  db().prepare(`INSERT OR IGNORE INTO chats (id, title) VALUES (?,?)`).run(chatId, title);
  return db().prepare(
    `SELECT id, title, created_at AS createdAt FROM chats WHERE id=?`,
  ).get(chatId) as ChatSummary;
}

export function listChats(): ChatSummary[] {
  return db().prepare(
    `SELECT id, title, created_at AS createdAt FROM chats ORDER BY created_at DESC`,
  ).all() as ChatSummary[];
}

export function renameChat(id: string, title: string): void {
  db().prepare(`UPDATE chats SET title=? WHERE id=?`).run(title, id);
}

export function deleteChat(id: string): void {
  db().prepare(`DELETE FROM chats WHERE id=?`).run(id);
}

// ─── Settings (key/value) ──────────────────────────────────────────────────
export function getSetting(key: string): string | undefined {
  return (db().prepare(`SELECT value FROM settings WHERE key=?`).get(key) as { value: string } | undefined)?.value;
}

export function setSetting(key: string, value: string): void {
  db().prepare(`INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value`).run(key, value);
}

export function getAllSettings(): Record<string, string> {
  const rows = db().prepare(`SELECT key, value FROM settings`).all() as { key: string; value: string }[];
  return Object.fromEntries(rows.map((r) => [r.key, r.value]));
}

export function addMessage(chatId: string, role: MessageRole, content: MessageBlock[], live = false): ChatMessage {
  const id = randomUUID();
  db().prepare(`INSERT INTO messages (id, chat_id, role, content_json, live) VALUES (?,?,?,?,?)`)
    .run(id, chatId, role, JSON.stringify(content), live ? 1 : 0);
  return db().prepare(
    `SELECT id, chat_id AS chatId, role, content_json AS content, live, created_at AS createdAt FROM messages WHERE id=?`,
  ).get(id) as any as ChatMessage;
}

export function listMessages(chatId: string): ChatMessage[] {
  const rows = db().prepare(
    // `created_at` is second-granularity, so live-mode turns written in the same
    // second tie. `rowid` (insertion order) breaks the tie so a reloaded live chat
    // keeps user→assistant order.
    `SELECT id, chat_id AS chatId, role, content_json AS content, live, created_at AS createdAt
     FROM messages WHERE chat_id=? ORDER BY created_at, rowid`,
  ).all(chatId) as any[];
  return rows.map((r) => ({ ...r, live: !!r.live, content: JSON.parse(r.content) as MessageBlock[] }));
}

/** Overwrite a message's blocks. */
export function updateMessage(id: string, content: MessageBlock[]): void {
  db().prepare(`UPDATE messages SET content_json=? WHERE id=?`).run(JSON.stringify(content), id);
}
