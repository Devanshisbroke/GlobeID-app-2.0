# Phase 4.5 — Intelligence + Experience Evolution
## Audit & Execution Plan

> Scope: read-only audit of the merged main (post PR #6). No code changes proposed
> here — this is the design doc + decision points before any implementation.

---

## 1. System awareness (what's actually wired today)

### Sync engine (must not break)
- `userStore` is the **only** store currently backed by the API.
  - `hydrate()` fetches `/trips`, replaces `travelHistory`, then drains
    `pendingMutations[]`. Triggered from `App.tsx` on mount + `online` event.
  - `addTravelRecords` / `removeTravelRecord` are optimistic-with-queue.
  - `persist` v2 keeps `travelHistory + pendingMutations + lastSyncedAt`.
- `walletStore`, `alertsStore`, `tripPlannerStore` are **localStorage-only**
  (zustand `persist`, no backend round-trip). PR-A intentionally deferred them.
- `<SyncBadge />` only surfaces on `offline-pending` / `error`.

### Backend tables vs. routes (gap)
| Table | Schema | Routes today | Gap |
|------|--------|--------------|-----|
| users | ✅ | `GET /user` | — |
| travel_records | ✅ | `GET/POST/DELETE /trips` | — |
| planned_trips | ✅ | none | trips written client-only, server has zero PlannedTrip awareness |
| wallet_balances / wallet_transactions / wallet_state | ✅ | none | server can't reason about money |
| alerts | ✅ | none | UI shows hardcoded seed only |
| copilot_messages | ✅ | none | Copilot never persists |

### Existing client-side derivations (already do half the "insights" work)
- `selectVisitedCountries`, `selectUpcomingCountries`, `selectNextUpcoming`,
  `selectCurrentLocation` — `src/store/userStore.ts:246-361`
- `buildTimeline`, `computeStats`, `computeAchievements`, `getContinent` —
  `src/lib/travelTimeline.ts`
- `getTravelSuggestions`, `calculateTravelScore` — `src/lib/travelSuggestions.ts`
  (already a recommendations engine — just ungrounded in real wallet/alerts state)
- `detectCurrentLocation`, `getLocalizedServices` — `src/lib/locationEngine.ts`

These selectors are **good** — Phase 4.5 should not duplicate them. The work is
to (1) lift the *cross-store* logic (travel × wallet × alerts) to the backend
where it can be cached, persisted, and reasoned about as a single feed; and (2)
make Copilot able to read all three.

---

## 2. Three structural gaps preventing "intelligence"

### Gap A — Copilot is blind to user state
`TravelCopilot.tsx` parses prompts via `tripGenerator.parsePrompt`, generates a
fictional itinerary from `regionAirports`, and writes directly to
`tripPlannerStore`. It **never reads** `userStore.travelHistory`,
`walletStore.balances`, or `alertsStore.alerts`. So:
- "What's my next trip?" → can't answer.
- "Do I have JPY?" → can't answer.
- "Plan a continuation from my last trip" → can't anchor on real data.

Fix: server-side `POST /copilot/respond` reads DB context, returns
`{ message, action?, citations }`. Client renders message; action envelope can
trigger planner / navigate / open wallet converter — under the existing
optimistic-write rails so sync is unaffected.

### Gap B — Alerts are static seed data
`alertsStore.defaultAlerts[]` is 4 hardcoded entries (`alert-1..4`). They
never react to actual state. The "Trip to Japan upcoming — check JPY" example
in the directive is exactly the join `travel_records.upcoming ⨯ wallet_balances.JPY`
that the seed alerts only *pretend* to be.

Fix: `GET /alerts` returns persisted user alerts **plus** lazily-derived
system alerts. Derivation is idempotent (keyed by signature like
`sys-trip-currency:JPY:2026-03-20`) so re-deriving on re-hydrate doesn't
duplicate.

### Gap C — Timeline can't see "trips"
`buildTimeline()` returns a flat `TimelineEntry[]` per leg. A 3-stop planner
trip (`SIN → NRT → ICN`) shows as 3 disconnected rows. There's no notion of
"this is part of trip X, 67% complete, departing in 14 days." The DB has
`travel_records.tripId` but the client never groups on it (Phase 3 derived
the IDs from prefix only).

Fix: server `GET /insights/travel` returns trips grouped (`tripId` cluster +
progression %) so timeline can render multi-leg trips as one card with a
progress bar instead of 3 separate rows.

---

## 3. Friction & redundancy (that should be removed, not added to)

| # | Where | What | Fix |
|---|-------|------|-----|
| F1 | `Suggestions.tsx` → click navigates to `/map` | Doesn't pre-filter the map to the suggested country. Suggestion content lost. | Pass `?focus={iata}` param; GlobalMap zooms to it. |
| F2 | Copilot save flow | "Save" creates a planner trip but the user has no fast path to "continue this in /map" or "see in timeline." | Copilot success message gets a single CTA button via the action envelope. |
| F3 | `globe-alerts` localStorage entry never appears until first interaction (noted in PR #5 test) | persist writes lazily | Backend hydrate immediately writes seed → fixed for free. |
| F4 | `tripPlannerStore.savedTrips` lives only in localStorage | Logout / clear-storage drops them | PR #C: `POST /planner/trips` (DB already has `planned_trips` table). |
| F5 | Drain-after-hydrate race noted in PR #6 test | UI flicker after reconnect | Re-run `hydrate()` after a successful drain. Trivial. |

These are all **subtractions** — Step 13 of the directive. None of them add
new UI surface.

---

## 4. Tiered execution plan

Three PRs (folds the original PR-B/C/D from Phase 4 into a Phase-4.5-shaped
delivery; less work, cleaner story):

### PR Phase 4.5-A — Backend Intelligence Foundation
- **Backend**
  - `GET /insights/travel` — `{ totalCountries, totalFlights, totalDistanceKm, longestFlight, byContinent[], nextTrip, daysUntilNextTrip, tripClusters[] }`
  - `GET /insights/wallet` — `{ totalUSD, byCurrency[], dominantCurrency, inactiveCurrencies, lastTxByCurrency }`
  - `GET /insights/activity` — `{ tripsThisMonth, lastTripAt, plannedNextWeek, alertsUnread }`
  - `GET /recommendations` — `{ nextDestinations[], currencyActions[], tripContinuation[] }` (structured `Recommendation` envelope grounded in stored data)
  - `GET /alerts` + `PATCH /alerts/:id` (read/dismiss) + lazy system-alert derivation on read
  - In-memory 5s TTL cache per `userId × endpoint`
  - **Sync safety:** all read-only. No `pendingMutations` interaction. PATCH alerts uses the same optimistic+queue pattern as `userStore` for consistency.
- **Frontend**
  - `useInsightsStore` (hydrate-only, no mutations)
  - `useRecommendationsStore` (hydrate-only)
  - `useAlertsStore` extended with `hydrate()` (becomes server-backed, alongside existing `markRead` / `dismissAlert` which now optimistic-write)
  - Hydrations chained **after** `userStore.hydrate()` completes — never in parallel — to preserve the existing race-free boot.
  - **UI taps (≤5%)**: `ProfileCard` shows "Trip in N days" badge when `nextTrip` exists; `Suggestions` re-renders from `/recommendations` (same component, swapped data source); `Wallet` surfaces "inactive currencies" hint above the converter; `TravelAlerts` shows system-derived alerts marked with a `system` badge dot.
- **Closes**: F1 (Suggestion deep-link), F3 (alerts localStorage lazy write), F5 (drain race).

### PR Phase 4.5-B — Copilot Evolution
- **Backend**
  - `POST /copilot/respond` — body `{ prompt }`, response `{ message, action?, citations[] }`
    - Reads userStore + walletStore + alertsStore from DB to ground responses
    - Persists both user prompt and assistant reply into `copilot_messages`
  - `GET /copilot/history` — last N messages
  - Server still uses local `tripGenerator` logic for itinerary intent (no LLM dependency — directive says no external APIs)
- **Frontend**
  - `TravelCopilot.tsx` calls `/copilot/respond` instead of the local parser
  - **Offline fallback**: if API fails, falls back to current local `tripGenerator` path so demo still works on a plane
  - Action envelope dispatcher: handles `{ type: "open_planner", payload: { destinations } }` / `{ type: "navigate", payload: { path } }` / `{ type: "open_converter", payload: { from, to } }` — all client-side, no new screens
  - Backend reads context for queries like "what's my next trip", "do I have JPY", "where am I going next month", grounded in real data via citations array
- **Sync safety**: Copilot writes don't enter `pendingMutations`. If `/copilot/respond` fails, we don't queue (it's a query, not a mutation).
- **Closes**: Gap A.

### PR Phase 4.5-C — Trip clustering + planner persistence
- **Backend**
  - `POST /planner/trips` — persists `PlannedTrip` to `planned_trips` table; legs continue to flow through `/trips` so existing optimistic logic is unchanged
  - `GET /planner/trips` — returns saved trips
  - `DELETE /planner/trips/:id` — cascades on `tripId` to remove legs from `travel_records`
- **Frontend**
  - `tripPlannerStore` gains `hydrate()` + optimistic+queue pattern (mirrors `userStore`)
  - Timeline rewrite to render trip clusters: consecutive same-`tripId` legs render as one card with progression % and date range; standalone history legs render as today
  - Map's upcoming-flights panel shows trip names instead of generic "Planned" labels
- **UI taps (≤5%)**: trip-cluster card replaces the current per-leg card on `/timeline`; planner detail screen unchanged.
- **Closes**: Gap C, F2, F4.

---

## 5. Validation matrix (against directive Step 14)

| Check | How proven |
|-------|-----------|
| Backend still source of truth | Every new feature reads from DB or computes from DB |
| Offline queue works | Existing tests re-run; new mutations (alerts read/dismiss, planner trip save) follow same pattern |
| Hydration works | Insights / recommendations / alerts hydrate **after** `userStore.hydrate()` completes |
| No race conditions | Sequential chain in `App.tsx`; insights endpoints don't touch `userStore` |
| All existing features intact | Phase 1–4 tests carried forward; no UI structure changes |
| New features meaningful | Every endpoint backed by real stored data — no synthetic numbers |
| No UI clutter | ≤10% UI movement budget; no new screens |
| Performance stable | 5s in-memory TTL on insights; useMemo on consumers; lazy hydrate per screen |

---

## 6. Decisions to lock before any code

1. **PR scope** — 3 PRs as proposed (A: Backend Intelligence + Alerts, B: Copilot, C: Trip Clustering + Planner Persistence), or fold into 1 mega-PR / different split?
2. **Insights endpoints scope** — start with the 3 outlined (`/travel`, `/wallet`, `/activity`) + `/recommendations`, or include the timeline trip-cluster derivation in `/insights/travel` from PR-A (vs. deferring to PR-C)?
3. **Copilot offline fallback** — keep the local `tripGenerator` as a safety net (recommended, matches the offline-first ethos) or hard-require backend?
4. **Action envelope safety** — accept all action types listed (`open_planner`, `navigate`, `open_converter`), or restrict to `open_planner` only for v1?
5. **System-alert dedup key** — keyed by `(category, signature)` so re-deriving doesn't dup (recommended), or simple `INSERT OR IGNORE` on a content hash?
