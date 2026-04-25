import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import * as schema from "./schema.js";
import { ddl } from "./schema.js";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_PATH = process.env.GLOBE_DB_PATH ?? path.join(__dirname, "../../globe.db");

const sqlite = new Database(DB_PATH);
sqlite.pragma("journal_mode = WAL");
sqlite.pragma("foreign_keys = ON");

// Apply DDL idempotently before first query.
sqlite.exec(ddl);

/* Forward-compatible additive migration for DBs created before Phase 4.5
 * (alerts table predates `severity / source / signature`). SQLite has no
 * `ADD COLUMN IF NOT EXISTS`, so we introspect first. */
function ensureColumn(table: string, column: string, ddl: string): void {
  const cols = sqlite
    .prepare(`PRAGMA table_info(${table})`)
    .all() as { name: string }[];
  if (!cols.some((c) => c.name === column)) {
    sqlite.exec(`ALTER TABLE ${table} ADD COLUMN ${ddl}`);
  }
}

ensureColumn("alerts", "severity", "severity TEXT NOT NULL DEFAULT 'low'");
ensureColumn("alerts", "source", "source TEXT NOT NULL DEFAULT 'seed'");
ensureColumn("alerts", "signature", "signature TEXT");
sqlite.exec(
  `CREATE UNIQUE INDEX IF NOT EXISTS idx_alerts_user_signature
     ON alerts(user_id, signature) WHERE signature IS NOT NULL;`
);

export const db = drizzle(sqlite, { schema });
export { sqlite };
