# GlobeID — Tomorrow's Mega Backlog

Ambitious, concrete, real items only. Grouped by domain. Each item should be actionable in a single PR or a small slice. Numbered for easy checking off.

---

## A. Critical fixes & lurking bugs

1. Audit every `<motion.button drag="…">` and `<motion.div drag="…">` on the entire codebase for scroll capture; either remove drag or wrap in a small handle child.
2. Replace any `setInterval` polling in components (countdown, sync badge) with `requestAnimationFrame` + visibility-aware throttling.
3. Verify all lazy-loaded routes have `<ErrorBoundary>` and `<Suspense fallback={<RouteSkeleton />}>` wrappers.
4. Fix any `<button>` with non-button children (e.g. nested QR + actions) → switch to `role="button"` div with explicit handlers.
5. Remove every remaining `cursor-pointer` from non-`hover:hover` devices via `@media (hover: hover) { .interactive { cursor: pointer; } }`.
6. Hunt down `position: fixed` chrome that misses safe-area insets (top theme toggle, sync badge, FAB, sheets).
7. Find and fix every horizontal-scroll regression (`min-w-0` on flex children, `text-balance`, long IBAN/MRZ wrapping).
8. Standardise on a single z-index ladder (toast > sheet > nav > FAB > banner) — no more ad-hoc `z-[60]`/`z-50`.
9. Verify all `useEffect` cleanups for timers, network listeners, MotionValues, R3F frames.
10. `npm run typecheck` should be wired into CI (currently only ESLint + tests).

## B. Wiring / cross-system integration

11. Boarding-pass document → `WalletStore.passes` two-way sync (today only one-way).
12. Trip detail "Verify at gate" button on past trips → audit log entry in lifecycleStore.
13. AI assistant "open my profile" / "open settings" intents (currently only navigate to top-level).
14. Voice intent for "show my receipts" / "show my expenses" → analytics view with appropriate filter.
15. Settings → "Sign out" must wipe `userStore.documents`, `walletStore`, `lifecycleStore` and revoke any cached tokens.
16. Reset onboarding flow should also clear `notificationsStore` read state.
17. Document vault item delete → cancel any scheduled local notifications (visa expiry).
18. Trip lifecycle delete → cancel boarding/departure reminders.
19. Currency engine refresh → broadcast invalidation to receipt store, spending breakdown, hotel quote.
20. Capacitor `App.addListener("appStateChange")` → re-hydrate stores when app comes back to foreground.
21. `appUrlOpen` (deep links) → route handler that maps `globeid://trip/<id>`, `globeid://pass/<code>`.
22. Push notification token refresh → API client header (`X-Push-Token`).

## C. Wallet system depth (Apple/Google Wallet level)

23. Pass colour theming derived from issuer/airline brand (deterministic gradient from IATA code).
24. Pass back-side: tap to flip → reveal terms, conditions, support phone, e-receipt.
25. Pass-card depth: parallax tilt on device tilt (`@capacitor/motion` accelerometer).
26. Pass groups: collapse multi-leg trip into a "trip wallet" with paginated cards.
27. Add to Apple Wallet `.pkpass` export (iOS web fallback).
28. Add to Google Wallet via Google Pay API for Passes (issuer JWT).
29. Pass auto-pin to top when departure within 24h.
30. Pass live-refresh: WebSocket push when gate/seat changes.
31. Pass dim-on-screen-off — auto-restore brightness when leaving PassDetail.
32. Pass haptic pulse when QR is being scanned (subtle "did you copy that").
33. Loyalty card: airline frequent-flyer numbers + status tier.
34. Vault: passport face image cropping + OCR rectification.
35. Vault: visa stamp browser (chronological montage of past visa images).
36. Vault: "scan and forget" mode — auto-categorise, auto-tag, auto-link to trip.
37. Vault: encrypted backup export (.zip with passphrase) + restore.
38. Vault: per-document share with TTL link (e.g. share visa with embassy for 24h).

## D. Trip system depth

39. Trip planner: multi-leg itinerary builder with airport autocomplete (existing IATA list).
40. Trip planner: drag-to-reorder legs.
41. Trip planner: budget input + per-leg cost breakdown.
42. Trip detail: weather forecast for arrival city (free Open-Meteo API).
43. Trip detail: time-zone delta vs home + local time card.
44. Trip detail: currency converter prefilled with destination currency.
45. Trip detail: visa/passport requirements for citizen → destination (lookup table).
46. Trip detail: "What to pack" checklist driven by destination weather + duration.
47. Trip detail: FX rate alerts ("EUR dropped 2% — buy now?").
48. Trip detail: airport map / terminal info link (deep link to FlightAware / SkyTeam).
49. Trip detail: ground transport options (Uber/Bolt/local) with deep-link.
50. Trip detail: lounge access lookup by alliance + airport.
51. Trip detail: post-trip auto-recap card (places visited, photos imported, total spend).
52. Trip detail: "Add companion" — share read-only trip with another user.
53. Trip detail: live flight tracking visual (mini globe of just this leg, animated plane along arc).
54. Trip detail: PDF export "Trip dossier" (boarding passes + visas + hotel + insurance).
55. Trip card: hero image from Unsplash by destination IATA.
56. Trip card: airline logo via `airline-logos` CDN with offline fallback.

## E. Identity / Documents

57. Identity score: explanation drawer with each factor + how to improve.
58. Identity score: weekly delta sparkline.
59. Biometric vault re-lock after 5 minutes of inactivity.
60. Biometric vault: enrolment flow (set passphrase + biometric).
61. Document vault: bulk-export to encrypted PDF.
62. Document vault: detect duplicate scans (perceptual hash) and offer merge.
63. Document vault: drag-to-reorder pinned documents.
64. Document vault: per-document tags + filter chips.
65. NFC passport read (Capacitor `@capacitor-community/nfc`) — fallback when MRZ OCR fails.
66. eID/digital identity import (mDL ISO 18013-5 outline, real spec).
67. Selfie liveness check during onboarding (camera + simple blink detection on-device).
68. Identity verification status badge (Tier 0 / Tier 1 / Tier 2) with upgrade path.

## F. Scanner / OCR / Camera

69. Edge-detection visual overlay (Sobel filter draw on canvas) during document framing.
70. Auto-capture when document is steady + framed (no shutter button needed).
71. Document cropping post-capture with corner handles.
72. OCR: switch from Tesseract to MRZ-only pipeline (faster, more accurate for passports).
73. OCR: fallback `paddleocr-wasm` for non-Latin text.
74. Receipt OCR: line-item extraction → expense entries auto-created.
75. Business-card OCR → contact import + store under "Contacts" tab.
76. QR scanner: torch toggle (`@capacitor/camera-preview`).
77. QR scanner: result classifier (boarding pass / payment URL / Wi-Fi / VCard).
78. Multi-page document scan + auto-PDF export.

## G. Globe / 3D / Cinematic

79. Real Earth diffuse + bump + clouds + city-lights textures (free under license, ~10–20 MB).
80. Day/night terminator line driven by current UTC time.
81. Country borders as picky regions (click → country detail).
82. Animated arc traversal: airplane sprite leaves a smooth contrail.
83. Atmosphere shader: refined Fresnel + scattering + sun position.
84. Star background driven by real star catalog (Yale BSC, ~9k stars).
85. Aurora shader at high latitudes (animated procedural mesh).
86. Travel heatmap layer toggle (Visx hex bins).
87. Ground-fog layer for night side.
88. Camera presets: "home view", "next trip view", "flight tracker".
89. Cinematic intro sequence on first launch (fly-in from space → settle on home airport).
90. R3F scene graph optimisation: instanced meshes for airport markers (~10k friendly).
91. Hi-DPI / 120Hz tuning: `dpr={[1, 2]}` adaptive, throttle when battery saver on.
92. Globe lazy-load via IntersectionObserver (only mount canvas when scrolled into view).
93. WebGPU path for supported browsers (`@react-three/fiber` 9 + WebGPU renderer).

## H. Voice / Conversational

94. Voice wake-word "hey globe" always-listening (only on Capacitor + opt-in).
95. Voice intent: numeric ("trip 3", "pass 2") → resolve from current list view.
96. Voice intent: "translate this to French" → trigger translation overlay over the active screen.
97. Voice intent: "remind me to pack at 7pm" → schedule a local notification.
98. Voice intent: multi-step ("book a hotel in Tokyo for next Friday") → command palette pre-filled.
99. Voice tutorial overlay: list every command grouped by domain.
100. Voice "did you mean" disambiguation when transcript matches no rule but partial.
101. Multi-language voice (i18n grammar packs for ES/FR/DE/JA).

## I. AI / Intelligence (deterministic — no fake LLM)

102. Smart suggestions on Home: "Your visa expires in 14 days" / "Currency dropped 3%".
103. Trip recap: weekly digest of upcoming + past trips, push every Sunday.
104. Reminder cadence: nightly check for documents expiring in <30 days.
105. Spend anomaly detector: weekly merchant pattern → flag a 3σ spike.
106. Travel-pattern insight: "You spend most in Tokyo on weekends".
107. Itinerary optimisation: detect tight connections + suggest rebooking.
108. Carbon footprint: per-flight CO₂ estimate + monthly chart.
109. Frequent-route detector + "save this route" CTA.
110. Predictive notifications: nudge to leave for the airport based on traffic + airport drive time.

## J. Mobile / 120Hz / UX polish

111. Audit all icons: minimum 24px, 1.8 stroke for legibility.
112. Audit all touch targets: minimum 44×44 css px (`iconButtonSize` token).
113. Pull-to-refresh applied to: Wallet, Trips, Documents, Feed, Notifications.
114. Bottom-sheet snap points (25% / 60% / 95%) using `@use-gesture` + framer drag.
115. Page transitions: shared element layoutId for trip card → trip detail.
116. Page transitions: named presets (slide / fade / scale-from-anchor).
117. Toast styling refinement (glass tint + accent border per type).
118. Empty states: illustrations + tertiary CTAs on Trips, Wallet, Documents, Feed.
119. Skeleton loading states applied to: Wallet first paint, Insights, Feed, Notifications.
120. Onboarding refresh: 4-screen carousel with Lottie + permission prompts.
121. Tutorial coachmarks for first-launch Globe interaction.
122. Search bar: pull-down on Home for quick command palette.
123. Cmd-K / Ctrl-K command palette (already in `CommandPalette.tsx`) — fuzzy ranking + recent commands.
124. Haptics audit: every long-press, swipe-action, and confirm action gets `haptics.medium()`.
125. Gesture system: pinch-to-zoom on globe, two-finger rotate, double-tap to home.
126. Edge-swipe-back from trip detail / pass detail (already in `useEdgeSwipeBack` — verify all routes).

## K. Animation & Motion

127. Lottie animation system + 5–10 integrated animations (success check, empty box, loading planet, trip booked, payment confirmed).
128. Rive interactive controllers as upgrade path (later).
129. Motion timeline coordinator: serialise route enter / exit / FAB collapse / banner show into a single GSAP timeline so animations don't fight each other.
130. Parallax scroll on Wallet (cards drift vs background atmosphere).
131. Spring config presets per surface: navigate, modal, sheet, FAB, toast.
132. `useReducedEffects` (already exists) applied to: Atmosphere, Globe, BottomNav, FAB, Skeleton.
133. Scroll-driven theme tint (background hue shifts with scroll progress on Home).
134. Animated number tickers for wallet balance, trip count, identity score.
135. Confetti on achievements (first trip, first scan, 10 countries).

## L. Theming, color, design tokens

136. Theme accent picker: 8 brand options + custom HSL slider.
137. Auto theme by time of day (light during day, dark after sunset; user can override).
138. Color-token expansion: brand-50 through brand-950, surface-1 through surface-5.
139. Dark / light parity audit (every screen rendered in both, screenshot diff in CI).
140. High-contrast theme for accessibility.
141. Reduce-transparency theme (replaces glass with solid surfaces).
142. Per-screen theme tweaks (Wallet warmer, Identity cooler).
143. Design tokens published to a Figma library plugin via `style-dictionary`.

## M. Performance

144. Memoise Globe arc generators (`useMemo` keyed on routes hash).
145. Lazy-load `jspdf` only when receipt export is invoked.
146. Lazy-load Three globe via IntersectionObserver.
147. Code-split per-route bundles (current `index-OG0Q6BSC.js` is 1 MB — too big).
148. Image lazy-loading with `loading="lazy"` + LQIP placeholders.
149. PWA precache audit — strip dev-only assets, drop unused fonts.
150. Bundle analyzer baseline + per-PR budget enforcement.
151. Web Workers for OCR (Tesseract already supports worker mode) + heavy filters.
152. Wasm SIMD for arc/curve generation (long-tail).
153. React 19 compiler / `useDeferredValue` audit.
154. RAF-driven UI updates instead of state for transient values (countdown ticker).
155. Long-list virtualisation on Notifications, Feed, Receipts (`react-window`).

## N. Offline / Sync

156. Service worker offline page with cached recent trips.
157. Background sync queue for offline mutations (`workbox-background-sync`).
158. IndexedDB-backed mutation queue (currently in-memory zustand persist).
159. Conflict resolver UI: server vs local diff with side-by-side picker.
160. Sync status mini-timeline in profile (last 20 sync events).
161. Optimistic UI for every store mutation with rollback on server reject.
162. Resume scanner mid-capture if app is backgrounded.

## O. Notifications / Reminders

163. Quiet hours (no notifications between 23:00 and 07:00 user-local).
164. Per-channel notification preferences (boarding / delays / digests / marketing).
165. In-app notification centre (already exists) → group by trip.
166. Push notification rich body (image + actions).
167. Scheduled "leave for airport" alarm based on configured commute time.
168. Daily digest at user-chosen time.
169. Trip reminder snooze (1h / 3h / morning).
170. iOS Live Activity / Android Live Notification for active flight.

## P. Security / Privacy

171. App-lock biometric required after 30s background.
172. Screen recording / screenshot blocking on PassDetail (Capacitor `setSecureFlag` on Android).
173. Vault data at rest encrypted with libsodium / WebCrypto.
174. Privacy-aware analytics opt-out toggle.
175. Audit log for vault access (who/when).
176. Secure clipboard: copied passport numbers auto-clear after 30s.
177. Suspicious-trip detector (impossible-travel pattern → re-auth prompt).
178. Threat-model doc + STRIDE table.

## Q. Backend / Server (`globeid-server`)

179. Real authentication (currently demo) — Lucia / better-auth + email magic link.
180. WebSocket real-time channel for flight status push.
181. Postgres parity layer (Drizzle already supports it; add a switchable adapter).
182. API rate limiting middleware.
183. Server-side rendered share URLs (`/share/trip/<id>` → OpenGraph card).
184. Background worker queue (`bullmq` or `pgmq`) for emails, digests, sync.
185. Audit log table + endpoints (security item P175 backend).
186. Multi-tenant scoping (per user data isolation tests).
187. OpenAPI spec generation + typed client (`hono-openapi` + `openapi-typescript`).
188. Healthcheck + Prometheus `/metrics` endpoint.
189. SSE endpoint for AI assistant streaming responses.
190. Backup snapshot job: daily SQLite/Postgres dump to S3-compatible bucket.

## R. Native Capacitor plugin coverage

191. `@capacitor/camera` — already, audit usage.
192. `@capacitor/share` — already, audit usage.
193. `@capacitor/local-notifications` — already, audit usage.
194. `@capacitor/push-notifications` — wire FCM/APNS.
195. `@capacitor-community/biometric-auth` — already, audit usage.
196. `@capacitor-community/screen-brightness` — already, optional.
197. `@capacitor-community/nfc` — for NFC passport (item 65).
198. `@capacitor/geolocation` — current city detection for time zone & weather.
199. `@capacitor/motion` — accelerometer for pass parallax (item 25).
200. `@capacitor/filesystem` — for PDF export, .ics save, vault backup.
201. `@capacitor/network` — already wired in OfflineBanner.
202. `@capacitor/keyboard` — manage IME for forms.
203. `@capacitor/status-bar` — auto-tint by route theme.
204. `@capacitor/splash-screen` — branded splash.
205. `@capacitor/app` — appStateChange + appUrlOpen (item 20–21).

## S. Testing

206. Unit tests for: `relativeDate`, `documentExpiry`, `mrzToDocument`, `voiceIntents` (overlap matrix), `audioFeedback` (mock AudioContext).
207. Integration test: Wallet renders boarding-pass entries from userStore.
208. Integration test: Globe arc tap navigates to trip detail.
209. Integration test: HybridScanner save → vault state.
210. Snapshot tests for Wallet, Trips, Profile in dark + light + reduced-motion.
211. Visual regression with Playwright on key routes.
212. E2E flow tests with Playwright: onboarding → scan → save → wallet → trip detail → kiosk verify.
213. Lighthouse CI per-PR with budgets.
214. Accessibility audit with `axe-core` per route.
215. Performance budget: bundle size + LCP < 2.5s + INP < 200ms.
216. Native build smoke test (`npx cap run android` headless via emulator in CI).

## T. CI / DevOps

217. Add `npm run typecheck` to CI matrix.
218. Cache `~/.npm` in android-apk workflow.
219. Cache `node_modules` keyed on lockfile hash.
220. Multi-job CI: lint, typecheck, test, build, e2e, android in parallel.
221. Per-PR preview deploy (Vercel / Netlify static).
222. Per-PR Capacitor APK artifact upload.
223. Renovate / Dependabot config for weekly dep updates.
224. Stale PR / branch cleanup workflow.
225. Release workflow: changelog generator + GitHub Release with APK.
226. Tag protection + signed commits.

## U. Docs / DX

227. README architecture section + component map diagram.
228. CONTRIBUTING.md with PR checklist + commit conventions.
229. `.editorconfig` for consistent indentation.
230. ADR (Architecture Decision Record) folder for big calls.
231. Storybook for the design system primitives (Surface / Button / Pill / Pass / Toast).
232. Mintlify or Docusaurus dev portal.
233. Per-screen Figma → code parity checklist.
234. Capacitor live-reload doc + Android emulator setup.
235. Lighthouse target doc.
236. MOBILE_UX.md doc — 120Hz / safe-area / hit-target rules.

## V. Brand-new feature pillars

237. Trip booking marketplace (flights / hotels / rides) — affiliate API with deep-links.
238. Group trips: invite friends, shared expenses, split logic (Splitwise-like).
239. Travel feed: Instagram-style chronological with photos + captions, real social store (already in `socialStore`).
240. AR boarding pass scan (`@capacitor-community/ar` exploration).
241. Maps mode: Mapbox/Maplibre 2D map for street-level navigation.
242. Trip lifecycle: post-trip insurance claim flow.
243. Loyalty aggregator: link FF programs, show tier progress.
244. Cards-in-wallet: virtual debit/credit linked via Stripe Issuing.
245. Multi-currency wallet: real top-up + spend (later).
246. Crypto bridge: optional crypto wallet view (read-only Etherscan).
247. eSIM marketplace integration (Airalo / Saily affiliate API).
248. Translator overlay (camera + on-device translation MLKit).
249. SOS / emergency contacts screen with embassy lookup by destination.
250. Health / vaccination requirements per destination (deterministic table).

---

# Suggested first slice for tomorrow (top-of-list, high-impact, ship-able in one PR)

- Items 1–10 (critical fix audit pass)
- Items 79–82 (Earth textures + day/night terminator)
- Items 23, 26, 29 (Wallet depth: brand colour theming, trip groups, auto-pin)
- Items 102–104 (deterministic AI suggestions)
- Items 127, 131 (Lottie + spring presets)
- Items 144–147 (perf: memo + lazy-load)
- Items 206–210 (tests for everything new)
