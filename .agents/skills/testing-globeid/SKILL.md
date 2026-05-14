# Testing GlobeID 2.0

## What it is
React + React Router + Three.js (`@react-three/fiber` + `drei`) + Tailwind + Framer Motion. Wrapped with Capacitor for Android APK export. Vite dev server, no backend / auth in this repo.

## Run it
```
npm install
npm run dev   # http://localhost:8080
npm run build # production bundle into dist/
npm test      # vitest, ~11 tests
npm run lint  # ~16 pre-existing errors are out of scope unless the task is lint cleanup
```
No CI workflows are configured in this repo — there is no automated gate to wait on after creating a PR.

## How to drive the running browser for tests
The Devin Chrome instance exposes CDP at `http://localhost:29229`. Prefer this over `computer` interactions for any DOM / wheel / drag assertion — it is deterministic and does not fight window focus.

```js
import { chromium } from 'playwright';
const browser = await chromium.connectOverCDP('http://localhost:29229');
const ctx = browser.contexts()[0];
const page = ctx.pages().find(p => p.url().includes('localhost:8080')) || await ctx.newPage();
await page.goto('http://localhost:8080/intelligence');
```
Install once with `npm install playwright --no-save` in `/home/ubuntu` (NOT inside the repo, to keep the diff clean).

For mobile-UA paths gated by `useReducedEffects`, override the UA on a fresh page:
```js
const mobile = await ctx.newPage();
const cdp = await ctx.newCDPSession(mobile);
await cdp.send('Network.setUserAgentOverride', { userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1' });
await mobile.setViewportSize({ width: 390, height: 844 });
await mobile.goto('http://localhost:8080/');
```

## R3F canvas / touch-action gotcha
`@react-three/fiber`'s `<Canvas>` applies the inline `style` prop to its outer wrapper div, NOT to the inner `<canvas>` element. So checking `document.querySelector('canvas').style.touchAction` will always look like `""` / `"auto"` even when the page sets `touch-action: none`. Walk the parent chain:
```js
const c = document.querySelector('canvas');
let n = c;
for (let i = 0; i < 6 && n; i++) { console.log(n.tagName, n.style.touchAction, getComputedStyle(n).touchAction); n = n.parentElement; }
```
Expected on `/map` (interactive globe): one of the ancestors has `touch-action: none`. Expected on `/intelligence` (decorative globe header): the `div.relative.h-56.overflow-hidden` wrapper has `touch-action: pan-y` and OrbitControls has `enableRotate={false} enableZoom={false}`.

## Testing the headline behaviours
- **Scroll-hijack fix on `/intelligence`** — synthesise a `WheelEvent` at the centre of `div.relative.h-56.overflow-hidden`, dispatch on `document.elementFromPoint`, and assert `defaultPrevented === false`. Also do a real visual scroll via `page.mouse.wheel` to confirm the destination cards come into view.
- **`/map` interactivity (regression)** — drag the canvas with `page.mouse.move + down + move + up`, take before/after `page.screenshot()`s, and assert the byte arrays differ. The globe rotates → screenshots will not be byte-identical.
- **`AtmosphereLayer` mobile swap** — desktop UA: `div.fixed.inset-0.pointer-events-none.overflow-hidden.-z-5` has 22 children. Mobile UA: exactly 2 children, no `transform` style. If both match, `useReducedEffects` is wired up correctly.
- **Vendor chunks** — after `npm run build`, `dist/assets/` should contain `vendor-three-*.js`, `vendor-motion-*.js`, `vendor-charts-*.js`, `vendor-radix-*.js`, `vendor-icons-*.js` and the `index-*.js` entry should be < 320 KB. If a single >900 KB index appears, `vite.config.ts` `manualChunks` was lost.

## Lazy-loaded routes
Most screens (everything except `/`) are `React.lazy`. After navigating, wait for the route's chunk to mount before asserting on its DOM (`page.waitForSelector('canvas')` for globe screens, `networkidle` is also fine).

`/intelligence` additionally has a manual `Tap to load globe` button before the globe canvas mounts. Click it and `await page.waitForTimeout(1500)` before asserting on the canvas.

## Mobile detection
`src/hooks/useReducedEffects.ts` returns `true` when any of: mobile UA, Capacitor runtime, `prefers-reduced-motion: reduce`. To exercise the reduced path without an Android device, override the UA via CDP (above). To exercise the desktop path, use any normal Chromium UA.

## Devin Secrets Needed
None — frontend only, no auth, no API.

## Out of scope (don't burn time on these unless asked)
- Real Android / Capacitor APK behaviour. There is no Android Studio in the Devin VM. Flag hardware verification on the PR checklist instead.
- The 16 pre-existing ESLint errors. Not related to most tasks.
- The `bun.lock` file. The repo uses `npm` (`package-lock.json`).
