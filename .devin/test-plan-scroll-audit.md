# Test Plan — Scroll integrity + Accent picker round-trip

Branch: `devin/1777712240-scroll-audit-and-more`
Target: local dev server (Vite) at `http://localhost:8080`
Viewport: mobile (Pixel 7 — 412×915 — via DevTools device toolbar)

## What changed (summary)
1. Profile screen got a new **Appearance** section with an accent picker (8 swatches, horizontal scroll), reduce-transparency toggle, quiet-hours toggle + start/end hour selects.
2. `secureCopy()` lib + PassDetail now uses it for the copy-code button.
3. Threat-model markdown doc.
4. `<html>` gets a `data-reduce-transparency` attribute when toggle is on; CSS overrides glass surfaces.

The user's explicit request: **"Check the scroll"** — verify the user-reported scroll regression has not returned with these changes.

## Scope (one primary flow + one targeted regression)
This is a **scroll regression check** PR — the test scope is intentionally narrow. Do NOT test:
- Wallet pass back-flip (already tested in PR #30)
- Lottie burst on scan (already tested in PR #30)
- Smart suggestions
- Globe terminator

## Pass / fail criteria

### Test 1 — Wallet vertical scroll works (the user's original bug)
**Why this exists**: The user reported scroll was broken, fixed in PR #29 by switching `overflow-x: hidden` → `clip` and replacing `<motion.button drag="y">` with `<motion.div drag="x" dragDirectionLock>`. Need to confirm this PR did NOT regress it.

Steps:
1. Navigate to `/wallet` (Wallet screen).
2. Wallet shows 3 tabs: Balance / Documents / Analytics. Default is Balance.
3. Page must scroll vertically by:
   - Touch/pointer-drag the page upward in the centre of the screen (not on the boarding-pass tile).
   - Page contents must move up; the boarding-pass tile must NOT swipe horizontally during a vertical drag (because the drag is `dragDirectionLock`).

**Pass if**: After a vertical drag of ~200 px, the *body of the page has scrolled* such that elements previously below the viewport (Balance card OR Total Balance value OR the analytics graph if any) come into view, AND the active boarding-pass tile is still on the same currency / index it started at (no accidental horizontal swipe).
**Fail if**: Page does not scroll vertically (the original bug). Also fail if the pass tile drifts horizontally during a vertical drag.

### Test 2 — Profile screen scroll works through the new Appearance section
**Why this exists**: The Appearance section was added inside Profile right between hero and existing settings. If anything in that section captures vertical scroll (e.g. the horizontal swatch row over-eagerly absorbing pan-y), Profile would stop scrolling at the swatch row.

Steps:
1. Navigate to `/profile`.
2. Scroll page down to the Appearance section (the section visible mid-page with "Accent" caption).
3. Continue scrolling down through the Appearance section, past the quiet-hours rows, to reach the existing Settings sections (Security / Preferences / Developer) below.

**Pass if**: All Settings sections below Appearance become visible after scrolling. Specifically: "Replay onboarding" row at the very bottom of the page must become visible.
**Fail if**: Page stops scrolling when the swatch row is in the centre of the viewport, or attempting to scroll while pointer is over the swatch row only moves swatches horizontally without scrolling the page when finger leaves the swatch row.

### Test 3 — Home screen vertical scroll works
**Why this exists**: Home was modified earlier in this branch chain (smart suggestions, animated balance ticker downstream). Sanity check it still scrolls.

Steps:
1. Navigate to `/`.
2. Scroll vertically — content should move up.

**Pass if**: Bottom of Home (e.g. quick actions, trip cards) becomes visible after dragging.
**Fail if**: Vertical drag does not scroll the page.

### Test 4 — Accent picker round-trip + persistence
**Why this exists**: Confirms the new picker actually rebrands the UI and persists.

Steps:
1. Open `/profile`, scroll to Appearance.
2. Note default accent (azure — blue ring around the first swatch).
3. Tap the Violet swatch (8th).
4. The selected ring + check icon should jump to Violet swatch.
5. Brand-coloured UI elements anywhere visible (e.g. the brand icon halos, a "brand" CTA button) should now appear violet.
6. Reload the page (`Ctrl+R`).
7. After reload, the Violet ring should still be on the 8th swatch.

**Pass if**: Step 4: ring moves. Step 5: at least one visibly brand-colored element changes from blue to violet. Step 7: Violet remains selected after reload.
**Fail if**: Selection doesn't persist after reload (broken localStorage write), or selection moves but no on-screen brand colour changes (broken `--p7-brand` CSS write).

## Out of scope (not testing this run)
- Quiet hours behaviour (already covered by 5 unit tests + would require manipulating the system clock to verify visually)
- Reduce-transparency mode end-to-end (works at CSS level — visible-but-subtle change; toggle is wired and unit-tested)
- Secure clipboard auto-clear (covered by 5 unit tests with fake timers)
- Wallet pass back-flip / Lottie burst / smart suggestions (covered in PR #30)

## Evidence
- Screenshots before/after for Tests 1, 2, 4
- Console state inspection: confirm `localStorage.getItem('globeid:themePrefs')` → `{"accentId":"violet",...}` after Test 4 step 6
