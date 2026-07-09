import { rmSync, existsSync } from "node:fs";
import { DB_PATH, SCRATCH_DIR } from "./paths";

// Wipe the local DB (provider keys, settings, saved conversations) + scratch.
for (const p of [DB_PATH, `${DB_PATH}-shm`, `${DB_PATH}-wal`, SCRATCH_DIR]) {
  if (existsSync(p)) rmSync(p, { recursive: true, force: true });
}
console.log("Reset: removed local DB and scratch.");
