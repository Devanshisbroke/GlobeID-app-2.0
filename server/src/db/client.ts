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

// Apply DDL idempotently before first query
sqlite.exec(ddl);

export const db = drizzle(sqlite, { schema });
export { sqlite };
