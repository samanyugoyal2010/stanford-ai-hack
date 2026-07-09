import Database from "better-sqlite3";
import { mkdirSync } from "node:fs";
import { DATA_DIR, DB_PATH, SCRATCH_DIR } from "./paths";
import { SCHEMA_SQL, migrate } from "./schema";

let db: Database.Database | null = null;

/** Process-wide singleton SQLite handle with schema applied. */
export function getDb(): Database.Database {
  if (db) return db;
  for (const dir of [DATA_DIR, SCRATCH_DIR]) {
    mkdirSync(dir, { recursive: true });
  }
  const handle = new Database(DB_PATH);
  handle.pragma("journal_mode = WAL");
  handle.pragma("foreign_keys = ON");
  handle.pragma("busy_timeout = 5000");
  handle.exec(SCHEMA_SQL);
  migrate(handle);
  db = handle;
  return db;
}
