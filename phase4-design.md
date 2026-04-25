# Phase 4 — Backend System + Real Data Engine — DESIGN DOC

Status: design only. **No code until approval.**

---

## 0. Boundary

What this phase MUST do:
- Replace zustand-as-source-of-truth with **backend-as-source-of-truth**.
- Keep zustand as the UI cache layer (read-through cache, optimistic updates).
- Cover all 7 modules from the directive: User, Identity, Travel/Trips, Planner, Wallet, Alerts, Copilot.
- Be runnable locally with one command, and reachable from a Capacitor APK on a real device.

What this phase MUST NOT do (per directive):
- Break frontend behavior or remove zustand.
- Rewrite frontend.
- Introduce auth complexity beyond a lightweight token.
- Re-add the parity gaps Phase 3 just closed.

---

## 1. Stack recommendation

| Layer | Choice | Why |
|---|---|---|
| Runtime | **Node 20** | Same language/tooling as the Vite frontend (TS), no context switch for the team. |
| Web framework | **Hono** | ~14 KB, native TS types, runs on Node + Bun + Cloudflare Workers (future-proofs the demo deploy). Express works too but Hono's typed routes feed directly into the frontend client without a codegen step. |
| Database | **SQLite (better-sqlite3)** | Single file, zero ops, no migration tooling needed for a demo, drop-in to a Capacitor backend if we ever bundle. Easy upgrade path to Postgres later by swapping the data-access layer. |
| Schema/validation | **Zod** | Already used elsewhere; one schema definition is reused for runtime validation, OpenAPI gen, and frontend type inference. |
| ORM | **Drizzle** (or hand-rolled SQL helpers) | Drizzle is type-safe, generates SQL from schema, and keeps the SQLite story simple. If you'd rather avoid the dep, plain `better-sqlite3` + Zod parse is fine for a demo. |
| Auth | **Static demo token + bearer header** | One demo user (`demo@globe.id`), token issued on first hit, persisted in `globe-auth` zustand slice. Honors "lightweight token-based" from the directive without dragging in OAuth/JWT rotation. Upgrade path: swap the issuer for real JWT later. |
| Frontend client | **Hand-written `apiClient.ts` wrapping `fetch`** | One file, ~80 LOC, returns Zod-parsed responses. Avoids `@tanstack/react-query` complexity; we use zustand as the cache. |
| Deploy target | **Local dev: `npm run dev:server` on `:4000`. Capacitor APK: configurable `VITE_API_BASE_URL` env at build time.** | For real-device demo, expose via Cloudflare Tunnel (`cloudflared tunnel`) or Fly.io free tier — see §10. |

**Alternatives if you'd rather**: Express + SQLite (more familiar, ~25 LOC bigger), FastAPI + SQLite (Python — adds a second language), or in-memory JSON (zero persistence but kills the "real product" feel). Recommend Hono + SQLite + Drizzle.

---

## 2. Repo layout

```
GlobeID-app-2.0/
├── src/                        # existing frontend (untouched apart from §6)
├── server/                     # NEW
│   ├── src/
│   │   ├── index.ts            # Hono app entry
│   │   ├── db/
│   │   │   ├── schema.ts       # Drizzle schema
│   │   │   ├── client.ts       # better-sqlite3 connection
│   │   │   └── seed.ts         # seeds the demo data PR #5 currently hardcodes
│   │   ├── routes/
│   │   │   ├── user.ts
│   │   │   ├── trips.ts
│   │   │   ├── planner.ts
│   │   │   ├── wallet.ts
│   │   │   ├── alerts.ts
│   │   │   └── copilot.ts
│   │   ├── auth/
│   │   │   └── token.ts        # static demo token middleware
│   │   └── lib/
│   │       └── validate.ts     # Zod helpers
│   ├── migrations/             # drizzle-kit output
│   ├── tsconfig.json
│   └── globe.db                # SQLite file (gitignored)
├── shared/                     # NEW — shared between FE & BE
│   └── types/
│       ├── travel.ts           # TravelRecord, PlannedTrip, etc.
│       └── api.ts              # Request/Response zod schemas
├── package.json                # adds workspace scripts (root-level monorepo)
└── ...
```

Monorepo via npm workspaces (`workspaces: ["server"]`). `shared/types` referenced via TS path alias `@shared/*` from both sides — single source of truth for the `TravelRecord` shape Phase 3 just canonicalized.

---

## 3. Database schema

```sql
-- users
CREATE TABLE users (
  id            TEXT PRIMARY KEY,         -- 'usr_demo' for the demo user
  email         TEXT UNIQUE NOT NULL,
  full_name     TEXT NOT NULL,
  nationality   TEXT NOT NULL,
  passport_no   TEXT,
  date_of_birth TEXT,                     -- YYYY-MM-DD
  created_at    INTEGER NOT NULL          -- unix ms
);

-- travel_records  (canonical from Phase 3 — backend-authoritative now)
CREATE TABLE travel_records (
  id             TEXT PRIMARY KEY,        -- 'tr-f1' or 'tr-planner-<tripId>-<n>'
  user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_iata      TEXT NOT NULL,
  to_iata        TEXT NOT NULL,
  date           TEXT NOT NULL,           -- YYYY-MM-DD
  airline        TEXT NOT NULL,
  duration       TEXT NOT NULL,
  type           TEXT NOT NULL CHECK (type IN ('upcoming','past','current')),
  flight_number  TEXT,
  source         TEXT NOT NULL CHECK (source IN ('history','planner')),
  trip_id        TEXT REFERENCES planned_trips(id) ON DELETE CASCADE,
  created_at     INTEGER NOT NULL
);
CREATE INDEX idx_travel_records_user ON travel_records(user_id);
CREATE INDEX idx_travel_records_trip ON travel_records(trip_id);

-- planned_trips
CREATE TABLE planned_trips (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  theme         TEXT NOT NULL CHECK (theme IN ('vacation','business','backpacking','world_tour')),
  destinations  TEXT NOT NULL,            -- JSON array of IATA codes
  created_at    INTEGER NOT NULL
);

-- wallet_balances
CREATE TABLE wallet_balances (
  user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency       TEXT NOT NULL,
  amount         REAL NOT NULL,
  rate           REAL NOT NULL,            -- exchange rate to USD
  flag           TEXT NOT NULL,
  PRIMARY KEY (user_id, currency)
);

-- wallet_transactions
CREATE TABLE wallet_transactions (
  id           TEXT PRIMARY KEY,
  user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency     TEXT NOT NULL,
  amount       REAL NOT NULL,
  kind         TEXT NOT NULL CHECK (kind IN ('credit','debit')),
  description  TEXT NOT NULL,
  date         TEXT NOT NULL,
  created_at   INTEGER NOT NULL
);

-- wallet_state  (active country, default currency)
CREATE TABLE wallet_state (
  user_id           TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  active_country    TEXT,
  default_currency  TEXT NOT NULL DEFAULT 'USD'
);

-- alerts
CREATE TABLE alerts (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category    TEXT NOT NULL,
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  read_at     INTEGER,                    -- nullable
  dismissed   INTEGER NOT NULL DEFAULT 0  -- 0/1
);

-- copilot_messages  (history per user — needed so Copilot has memory)
CREATE TABLE copilot_messages (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('user','assistant')),
  content     TEXT NOT NULL,
  created_at  INTEGER NOT NULL
);
```

**Seed data**: `server/src/db/seed.ts` ports the current zustand defaults (10 travel records, 7 wallet balances, 4 alerts) into the database so the app behaves identically on first launch.

---

## 4. API surface

All routes are prefixed `/api/v1`. Auth via `Authorization: Bearer <token>` header. JSON request/response. Zod-validated.

| Method | Path | Purpose | Frontend caller |
|---|---|---|---|
| `POST` | `/auth/demo` | Issue static demo token (idempotent) | `apiClient.bootstrap()` on app start |
| `GET` | `/user` | Fetch profile + identity | `userStore.fetchProfile()` |
| `PATCH` | `/user` | Update profile fields | (currently unused — wired for future) |
| `GET` | `/trips` | List travel records (filterable: `type`, `source`) | `userStore.fetchTravelHistory()` |
| `POST` | `/trips` | Add records (used by planner save & manual seeding) | `userStore.addTravelRecords()` |
| `DELETE` | `/trips/:id` | Remove a record | `userStore.removeTravelRecord()` |
| `GET` | `/planner/trips` | List saved trips | `tripPlannerStore.fetchSavedTrips()` |
| `POST` | `/planner/trips` | Save a planned trip — backend expands into `travel_records` server-side, returns `{trip, legs}` | `tripPlannerStore.saveCurrentTrip()` |
| `DELETE` | `/planner/trips/:id` | Delete a planned trip + cascade legs (FK) | `tripPlannerStore.deleteTrip()` |
| `GET` | `/wallet` | Balances + transactions + active country | `walletStore.fetchAll()` |
| `PATCH` | `/wallet/active-country` | Set `active_country` | `walletStore.setActiveCountry()` |
| `POST` | `/wallet/transactions` | Append transaction (for future Services payments) | wired but unused |
| `GET` | `/alerts` | List alerts | `alertsStore.fetchAlerts()` |
| `PATCH` | `/alerts/:id` | Mark read / dismissed | `alertsStore.markRead/dismiss()` |
| `POST` | `/copilot/message` | Send user message → backend reads trips + wallet + alerts state, returns assistant reply (+ optional `actions[]` like "save planner trip") | `TravelCopilot.send()` |
| `GET` | `/copilot/history` | Fetch chat history | `TravelCopilot.mount()` |

**Response envelope** (consistent):
```ts
{ ok: true, data: T } | { ok: false, error: { code: string, message: string } }
```

**Status codes**: 200 / 201 / 400 (Zod validation fail) / 401 (missing/invalid token) / 404 / 500.

---

## 5. Backend logic engine

**Planner save flow** (the headline integration from Phase 3, now backend-authoritative):

```
Frontend                             Backend
────────                             ───────
POST /planner/trips                   ↓
  body: { name, theme, destinations }
                                     1. Insert into planned_trips
                                     2. For each consecutive pair:
                                        compute leg date offset
                                        insert into travel_records with
                                        source='planner', trip_id=...
                                     3. Return { trip, legs }
↓
Apply optimistic update first, then
reconcile with server response,
write to zustand cache.
```

The leg-date and ID-prefix logic (`tr-planner-<tripId>-<n>`, `+7+i*3 days`) moves to `server/src/routes/planner.ts:buildTripLegs()`. The frontend `tripPlannerStore.buildTripLegs` becomes a thin compatibility shim used only by the offline fallback (§7).

**Copilot context engine**: when `/copilot/message` is hit, the backend loads the user's recent trips + wallet active country + 5 latest alerts and stuffs them into the system prompt (or a deterministic rule engine if no LLM is wired). Either way, the response can include an `actions[]` array — e.g. `{type: 'save_planner_trip', payload: {...}}` — that the frontend executes by dispatching the corresponding store method, which itself goes back through `/planner/trips`. **Single round trip.**

---

## 6. Frontend integration

The diff is small per file but spans every store. Pattern, applied uniformly:

```ts
// store/userStore.ts (after Phase 4)
addTravelRecords: async (records) => {
  // 1. Optimistic local update
  set((s) => ({ travelHistory: dedupe([...records, ...s.travelHistory]) }));
  try {
    // 2. Server write
    const { data } = await api.trips.create(records);
    // 3. Reconcile (server-canonical IDs / fields)
    set((s) => ({
      travelHistory: mergeServer(s.travelHistory, data),
      syncStatus: 'synced',
    }));
  } catch (e) {
    set({ syncStatus: 'offline-pending' });
    // Local-only changes get queued in `pendingMutations`,
    // retried on reconnect.
  }
},
```

Each store gains:
- `syncStatus: 'idle' | 'loading' | 'synced' | 'offline-pending' | 'error'`
- A `hydrate()` method called once on app boot from `App.tsx`.
- A `pendingMutations[]` queue persisted to localStorage for offline writes.

**zustand `persist` middleware stays** — it acts as the L1 cache. Backend is L2 / source of truth.

**No store consumer in any screen changes** — all the optimistic updates make the UI feel identical to today. Loading skeletons only show on cold boot before the first `hydrate()` resolves.

---

## 7. Offline + resilience

| Failure mode | Behaviour |
|---|---|
| Cold boot + no network | Hydrate from `persist` cache, show "Offline" pill in BottomTabBar. All reads work. |
| Mutation while offline | Optimistic local update + push to `pendingMutations` queue. UI shows nothing different except optional "Will sync when online" toast. |
| Reconnect | Drain `pendingMutations` queue serially, reconcile any conflicts (last-write-wins on the demo user — only one user, so collisions are rare). |
| Server 500 on mutation | Roll back optimistic update, show error toast, leave queue intact. |
| Token invalid (401) | Re-call `/auth/demo` to mint a new token, retry once. |

---

## 8. Security

For Phase 4 (demo-grade):
- Static bearer token issued by `POST /auth/demo`. Stored in `globe-auth` zustand slice + localStorage.
- Token is HMAC-signed with a server-side secret (env var `GLOBE_TOKEN_SECRET`). Cheap, real signature, no JWT lib.
- CORS: `Access-Control-Allow-Origin` for `http://localhost:8080` in dev; configurable for production via `ALLOWED_ORIGIN`.
- Rate limit: 60 req/min per token, in-memory.
- Zod validation on all bodies (rejects malformed payloads with 400 before they hit the DB).

Out of scope (callouts so we don't pretend otherwise): real signup/login, password hashing, email verification, role-based access. The directive says "lightweight" — I'll keep it that way.

---

## 9. Performance

- All list endpoints paginated (`?limit=50&cursor=...`); defaults serve full demo data in one round trip.
- SQLite with `better-sqlite3` is synchronous and fast (<1 ms per query for the demo workload).
- Frontend: `apiClient` deduplicates concurrent identical GETs (single in-flight promise per URL). Mutations bypass dedup.
- ETag/`If-None-Match` on `GET /trips` and `GET /wallet` so refresh-on-focus is cheap.

---

## 10. Dev mode + APK reachability

**Local dev**:
```bash
npm install                # workspaces resolve server deps
npm run dev:server         # starts Hono on :4000, runs migrations + seed if globe.db absent
npm run dev                # starts Vite on :8080 (existing)
```

`VITE_API_BASE_URL=http://localhost:4000/api/v1` baked into `.env.development`.

**APK on a real Android device**:
- Option A (recommended for demo): expose the local dev server via `cloudflared tunnel --url http://localhost:4000`. Tunnel URL goes into `.env.production` before `npm run build && npx cap sync android`.
- Option B (production-grade): deploy `server/` to Fly.io free tier (one `Dockerfile`, ~5 min setup). Stable URL.
- Option C (offline-first demo): bundle the seeded SQLite DB in the APK and run a same-process JS server via Capacitor's HTTP plugin. **Heavier — recommend deferring.**

---

## 11. Validation plan (what I'll prove before declaring done)

| Check | How |
|---|---|
| Cold boot pulls from server, not seed | Wipe `localStorage`, hit `/`, see network request to `/api/v1/user` and `/api/v1/trips`, assert UI matches DB rows. |
| Planner save round-trips | Save `DXB→ICN→CDG`, see `POST /planner/trips`, assert SQLite `travel_records` table has 2 new rows with `source='planner'`, assert `/map` upcoming list reflects them after a navigate. |
| Refresh survives | Hard reload, assert UI rebuilds from server (not just from `persist` cache) — check `syncStatus` transitions `loading → synced`. |
| Offline write queues | Kill the server, save a planner trip, see optimistic update + "offline" pill, restart server, see queue drain + server now has the row. |
| Wallet active country syncs | Visit `/services` → `PATCH /wallet/active-country` fires → DB updated → reload `/wallet` and JPY/USD/whatever sorts to top from server state. |
| Copilot reads real state | Ask "what's my next trip?" — backend should respond with the actual next-trip row (T1 from Phase 3). |
| No regressions | Repeat Phase 3's T1–T5 against the new backend-driven flow. |

---

## 12. Migration order (proposed PR sequence)

This is too big for one PR. Splitting:

- **PR-A**: Server skeleton + DB schema + seed + `/auth/demo` + `/user` + `/trips`. Frontend `userStore` switches to API-driven (`hydrate`, `addTravelRecords`, `removeTravelRecord`). Phase 3's behaviour preserved end-to-end. No other store changes yet.
- **PR-B**: `/planner/trips` + `tripPlannerStore` integration. The headline planner→backend→travel_records flow.
- **PR-C**: `/wallet/*` + `/alerts/*` + their stores. Phase 3's parity gap stays closed because both sides now read the same `wallet_balances` table.
- **PR-D**: `/copilot/*` + Copilot rewrite to backend (with optional rule-engine fallback if no LLM key).

Each PR is independently testable, reversible, and reviewable. **If you'd rather one PR — say so and I'll deliver one big PR, but I recommend the sequence.**

---

## 13. Decisions I need from you (4 + 1)

1. **Stack**: Hono + SQLite + Drizzle as recommended? Or Express? Or FastAPI (Python)?
2. **Repo layout**: Monorepo with `server/` subfolder? Or separate `globeid-backend` repo?
3. **Hosting for APK demo**: Cloudflare Tunnel (cheapest), Fly.io deploy (most realistic), or in-APK SQLite (heaviest)?
4. **Auth scope**: Single demo user with static token (recommended)? Or fake login flow with email/password (no real verification)? Or real signup/login (significant scope creep)?
5. **PR strategy**: 4 incremental PRs (PR-A → PR-D, recommended)? Or one mega-PR? Or 2 (server-side + frontend-side)?

**Plus**: PR #5 is still **open and unmerged** — same as the Phase 1→2 boundary. Should be merged before Phase 4 branches off so the diffs don't tangle.

No code until you confirm.
