// Idempotent schema. OpenLive stores only app state: provider keys (encrypted),
// settings, and persisted live-voice conversations.
export const SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS providers (
  id                 TEXT PRIMARY KEY,
  name               TEXT NOT NULL,
  kind               TEXT NOT NULL,
  api_key_ciphertext TEXT,
  key_last4          TEXT,
  is_default         INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS chats (
  id         TEXT PRIMARY KEY,
  title      TEXT NOT NULL DEFAULT 'New chat',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS messages (
  id           TEXT PRIMARY KEY,
  chat_id      TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  role         TEXT NOT NULL,
  content_json TEXT NOT NULL,
  live         INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_id);

CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
`;

type MigrateHandle = {
  prepare: (s: string) => { all: () => unknown[] };
  exec: (s: string) => void;
};

export function migrate(_handle: MigrateHandle) {
  // Fresh schema — nothing to migrate. Kept as a hook for future additive changes.
}
