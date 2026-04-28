import { sqliteTable, text, integer, real, primaryKey } from "drizzle-orm/sqlite-core";

export const users = sqliteTable("users", {
  id: text("id").primaryKey(),
  email: text("email").notNull().unique(),
  fullName: text("full_name").notNull(),
  nationality: text("nationality").notNull(),
  passportNo: text("passport_no"),
  dateOfBirth: text("date_of_birth"),
  createdAt: integer("created_at").notNull(),
});

export const travelRecords = sqliteTable("travel_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  fromIata: text("from_iata").notNull(),
  toIata: text("to_iata").notNull(),
  date: text("date").notNull(),
  airline: text("airline").notNull(),
  duration: text("duration").notNull(),
  type: text("type", { enum: ["upcoming", "past", "current"] }).notNull(),
  flightNumber: text("flight_number"),
  source: text("source", { enum: ["history", "planner"] }).notNull(),
  tripId: text("trip_id"),
  createdAt: integer("created_at").notNull(),
});

export const plannedTrips = sqliteTable("planned_trips", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  theme: text("theme", { enum: ["vacation", "business", "backpacking", "world_tour"] }).notNull(),
  destinations: text("destinations").notNull(),
  createdAt: integer("created_at").notNull(),
});

export const walletBalances = sqliteTable(
  "wallet_balances",
  {
    userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    currency: text("currency").notNull(),
    amount: real("amount").notNull(),
    rate: real("rate").notNull(),
    flag: text("flag").notNull(),
  },
  (t) => ({ pk: primaryKey({ columns: [t.userId, t.currency] }) })
);

export const walletTransactions = sqliteTable("wallet_transactions", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  currency: text("currency").notNull(),
  amount: real("amount").notNull(),
  kind: text("kind", { enum: ["credit", "debit"] }).notNull(),
  description: text("description").notNull(),
  date: text("date").notNull(),
  createdAt: integer("created_at").notNull(),
  // Slice-A: append-only ledger metadata. `idempotencyKey` is unique per
  // (user, key) and lets retried POSTs collapse onto a single row.
  idempotencyKey: text("idempotency_key"),
  txType: text("tx_type", {
    enum: ["payment", "send", "receive", "convert", "refund"],
  }),
  merchant: text("merchant"),
  category: text("category"),
  country: text("country"),
  countryFlag: text("country_flag"),
  icon: text("icon"),
  reference: text("reference"),
});

export const walletState = sqliteTable("wallet_state", {
  userId: text("user_id").primaryKey().references(() => users.id, { onDelete: "cascade" }),
  activeCountry: text("active_country"),
  defaultCurrency: text("default_currency").notNull().default("USD"),
});

export const alerts = sqliteTable("alerts", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  category: text("category").notNull(),
  title: text("title").notNull(),
  message: text("message").notNull(),
  severity: text("severity", { enum: ["low", "medium", "high"] }).notNull().default("low"),
  source: text("source", { enum: ["seed", "system"] }).notNull().default("seed"),
  signature: text("signature"),
  createdAt: integer("created_at").notNull(),
  readAt: integer("read_at"),
  dismissed: integer("dismissed").notNull().default(0),
});

export const copilotMessages = sqliteTable("copilot_messages", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  role: text("role", { enum: ["user", "assistant"] }).notNull(),
  content: text("content").notNull(),
  createdAt: integer("created_at").notNull(),
});

/* Slice-B — emergency contacts.
 *
 * Stored per user. Phone validation is done at the route layer (Zod E.164).
 * Soft-delete is a future concern; for now contacts are deleted outright. */
export const emergencyContacts = sqliteTable("emergency_contacts", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  relationship: text("relationship").notNull(),
  phoneE164: text("phone_e164").notNull(),
  email: text("email"),
  isPrimary: integer("is_primary").notNull().default(0),
  createdAt: integer("created_at").notNull(),
});

/* Slice-B — append-only loyalty ledger.
 *
 * Same pattern as wallet_transactions: a unique (user_id, idempotency_key)
 * index lets retried POSTs collapse onto a single row. Earn/redeem totals
 * derive from a SUM over `points` instead of a denormalised balance, so
 * the ledger is the single source of truth and can never disagree with
 * itself. */
export const loyaltyTransactions = sqliteTable("loyalty_transactions", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  /** Positive for earns, negative for redemptions. */
  points: integer("points").notNull(),
  kind: text("kind", {
    enum: ["wallet_payment", "trip_completion", "signup_bonus", "redemption", "adjustment"],
  }).notNull(),
  description: text("description").notNull(),
  reference: text("reference"),
  idempotencyKey: text("idempotency_key"),
  createdAt: integer("created_at").notNull(),
});

/* Slice-B — budget caps.
 *
 * One row per (user, scope) where scope is either a category or a tripId.
 * Aggregation happens in the route by SUMming wallet_transactions filtered
 * to the matching category/tripId. Caps live in the user's default currency
 * — we don't try to FX-convert each ledger row. The currency is denormalised
 * onto the row to make that explicit. */
export const budgetCaps = sqliteTable(
  "budget_caps",
  {
    userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    /** "category:food", "category:hotel", "trip:trip_abc", "global". */
    scope: text("scope").notNull(),
    capAmount: real("cap_amount").notNull(),
    currency: text("currency").notNull(),
    /** Notify when projected spend hits this fraction (0..1) of cap. */
    alertThreshold: real("alert_threshold").notNull().default(0.8),
    period: text("period", { enum: ["trip", "monthly", "yearly", "global"] }).notNull(),
    updatedAt: integer("updated_at").notNull(),
  },
  (t) => ({ pk: primaryKey({ columns: [t.userId, t.scope] }) }),
);

/** Raw DDL applied on boot before drizzle-kit migrations are introduced.
 *  Keeps PR-A self-contained without adding a migration step. */
export const ddl = `
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  nationality TEXT NOT NULL,
  passport_no TEXT,
  date_of_birth TEXT,
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS travel_records (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_iata TEXT NOT NULL,
  to_iata TEXT NOT NULL,
  date TEXT NOT NULL,
  airline TEXT NOT NULL,
  duration TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('upcoming','past','current')),
  flight_number TEXT,
  source TEXT NOT NULL CHECK (source IN ('history','planner')),
  trip_id TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_travel_records_user ON travel_records(user_id);
CREATE INDEX IF NOT EXISTS idx_travel_records_trip ON travel_records(trip_id);
CREATE TABLE IF NOT EXISTS planned_trips (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  theme TEXT NOT NULL CHECK (theme IN ('vacation','business','backpacking','world_tour')),
  destinations TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS wallet_balances (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency TEXT NOT NULL,
  amount REAL NOT NULL,
  rate REAL NOT NULL,
  flag TEXT NOT NULL,
  PRIMARY KEY (user_id, currency)
);
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency TEXT NOT NULL,
  amount REAL NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('credit','debit')),
  description TEXT NOT NULL,
  date TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  idempotency_key TEXT,
  tx_type TEXT CHECK (tx_type IN ('payment','send','receive','convert','refund')),
  merchant TEXT,
  category TEXT,
  country TEXT,
  country_flag TEXT,
  icon TEXT,
  reference TEXT
);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_user_created
  ON wallet_transactions(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_wallet_tx_user_idem
  ON wallet_transactions(user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
CREATE TABLE IF NOT EXISTS wallet_state (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  active_country TEXT,
  default_currency TEXT NOT NULL DEFAULT 'USD'
);
CREATE TABLE IF NOT EXISTS alerts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'low' CHECK (severity IN ('low','medium','high')),
  source TEXT NOT NULL DEFAULT 'seed' CHECK (source IN ('seed','system')),
  signature TEXT,
  created_at INTEGER NOT NULL,
  read_at INTEGER,
  dismissed INTEGER NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_alerts_user_signature
  ON alerts(user_id, signature) WHERE signature IS NOT NULL;
CREATE TABLE IF NOT EXISTS copilot_messages (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user','assistant')),
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone_e164 TEXT NOT NULL,
  email TEXT,
  is_primary INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user ON emergency_contacts(user_id);
CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('wallet_payment','trip_completion','signup_bonus','redemption','adjustment')),
  description TEXT NOT NULL,
  reference TEXT,
  idempotency_key TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_loyalty_user_created
  ON loyalty_transactions(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_loyalty_user_idem
  ON loyalty_transactions(user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
CREATE TABLE IF NOT EXISTS budget_caps (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scope TEXT NOT NULL,
  cap_amount REAL NOT NULL,
  currency TEXT NOT NULL,
  alert_threshold REAL NOT NULL DEFAULT 0.8,
  period TEXT NOT NULL CHECK (period IN ('trip','monthly','yearly','global')),
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, scope)
);
`;
