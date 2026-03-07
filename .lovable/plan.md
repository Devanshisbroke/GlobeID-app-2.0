

# GlobeID Phase 1 — Implementation Plan

## Overview
Build the complete foundation: dark glass design system, PWA configuration, 4-tab mobile shell, motion system, demo data, Lock Screen, Home Dashboard, AI assistant placeholder, and stub screens.

---

## 1. Design System & Theme Tokens

**Update `src/index.css`** — Replace the light/dark theme with GlobeID's dark-only palette:
- Dark base: `--background: 240 10% 1.6%` (#040406)
- Glass tokens: `--glass-bg`, `--glass-border`, `--glass-blur`
- Accent colors: indigo, cyan, teal for the neon gradient system
- Motion tokens as CSS variables: `--motion-micro: 160ms`, `--motion-small: 240ms`, `--motion-medium: 400ms`, `--motion-long: 800ms`
- Easing: `--ease-out-expo: cubic-bezier(0.22, 1, 0.36, 1)`
- Typography scale with `clamp()` for responsive sizing

**Update `tailwind.config.ts`** — Extend with GlobeID-specific colors (glass, neon-indigo, neon-cyan, neon-teal), custom keyframes (fade-in, scale-in, slide-up, glow-pulse, float — all transform/opacity only), and animation utilities.

## 2. PWA Configuration

- Install `vite-plugin-pwa`
- Configure in `vite.config.ts` with manifest, service worker, `navigateFallbackDenylist: [/^\/~oauth/]`
- Add PWA icons (placeholder SVGs) to `/public`
- Add mobile meta tags to `index.html` (apple-mobile-web-app, theme-color, viewport)
- Create `public/manifest.json` with app name "GlobeID", dark theme color, display standalone

## 3. Motion System — `src/hooks/useMotion.ts`

A centralized hook exposing:
- Timing tokens (`micro`, `small`, `medium`, `long`) read from CSS variables
- Easing curves
- Helper functions: `getTransition(duration)` returning CSS transition strings
- `prefersReducedMotion` boolean from `matchMedia`
- `animate(element, keyframes, options)` wrapper that respects reduced-motion

All components will import motion config from this single source.

## 4. Demo Data — `src/lib/demoData.ts`

Comprehensive mock data:
- User profile (avatar URL, name, identity level, country flags, identity score 0-100)
- Documents (passport, visa, national ID with metadata, expiry dates)
- Wallet balances (USD, EUR, INR, GBP) and transaction history
- Bookings (2 flights, 2 hotels with dates, confirmation codes)
- Activity feed (10+ recent items with types, timestamps)
- AI assistant sample conversations (3-4 demo exchanges)
- `DEMO_MODE` flag export

## 5. Core UI Components

| Component | File | Purpose |
|-----------|------|---------|
| GlassCard | `src/components/ui/GlassCard.tsx` | Reusable glass panel with backdrop-blur, neon border glow, inner reflection |
| BottomTabBar | `src/components/layout/BottomTabBar.tsx` | 4 tabs (Home, Identity, Wallet, Travel) with animated active indicator, safe-area padding |
| AppShell | `src/components/layout/AppShell.tsx` | Wraps screens with BottomTabBar, manages route transitions |
| FAB | `src/components/layout/FAB.tsx` | Floating action button — context-aware "Quick Scan" / "Quick Pay" with glow |
| IdentityScore | `src/components/ui/IdentityScore.tsx` | SVG radial donut with gradient stroke, animated fill |
| AnimatedPage | `src/components/layout/AnimatedPage.tsx` | Wrapper for page enter/exit transitions (fade + translateY) |
| AIAssistantButton | `src/components/ai/AIAssistantButton.tsx` | Floating chat bubble that opens a bottom-sheet chat composer |
| AIAssistantSheet | `src/components/ai/AIAssistantSheet.tsx` | Glass bottom sheet with message list, input, quick suggestion chips |

## 6. App Shell & Routing — `src/App.tsx`

- 4 main routes: `/`, `/identity`, `/wallet`, `/travel`
- Lock screen at `/lock` (initial landing)
- Profile at `/profile` (accessible from Home)
- All wrapped in `AppShell` with `BottomTabBar`
- Lock screen shown on first visit (state managed via localStorage flag)
- Lazy-load screens with `React.lazy` + `Suspense`

## 7. Screens

### Lock Screen (`src/screens/LockScreen.tsx`)
- Full-screen dark glass background with subtle animated gradient orbs (transform-only)
- Centered user avatar (blurred/masked), masked name "A***n S***h"
- Large "Scan Passport" CTA with indigo→cyan gradient border glow, pulse animation
- "Use Biometrics" button — simulates biometric prompt (overlay with fingerprint icon, auto-succeeds after 1.5s)
- Fallback PIN entry (4-digit input)

### Home Dashboard (`src/screens/Home.tsx`)
- Profile card (GlassCard): avatar, name, identity level badge, country flags, IdentityScore donut
- Quick actions grid (7 items): Scan Passport, Open Wallet, Book Hotel, Book Flight, Request Ride, Order Food, AI Assistant — each a GlassCard with icon and label
- Activity feed: scrollable list of GlassCard items showing recent events
- All data from `demoData.ts`

### Identity Stub (`src/screens/Identity.tsx`)
- GlassCard header with "Identity Vault" title
- List of documents from demo data (passport, visa, ID) as cards with security badge icons
- Tap to see detail overlay (metadata, dates) — basic but functional

### Wallet Stub (`src/screens/Wallet.tsx`)
- Balance display with multi-currency cards
- Transaction list with category icons
- "Send" and "Receive" buttons (non-functional, styled)

### Travel Stub (`src/screens/Travel.tsx`)
- "Flights" and "Hotels" tabs
- Mock booking cards from demo data
- Services section (Rides, Food) as sub-cards within Travel — merged per user request

### Profile (`src/screens/Profile.tsx`)
- Settings list: Security, Bank & KYC, Preferences, Developer
- Demo Mode toggle
- Glass-styled list items

## 8. AI Assistant Placeholder

- `AIAssistantButton` — fixed-position chat bubble (bottom-right, above tab bar)
- `AIAssistantSheet` — uses the existing Drawer component as a bottom sheet
- Shows 3 quick suggestion chips: "Find hotels", "Convert currency", "Summarize trips"
- Tapping a chip shows a demo response from `demoData.ts`
- Text input with send button (responds with canned demo reply)
- Architecture includes `src/hooks/useAI.ts` hook stub for future real API integration

## 9. Performance & Accessibility

- All animations: `transform` and `opacity` only — no layout-triggering properties
- `prefers-reduced-motion`: detected in `useMotion`, disables all non-essential animations
- Touch targets minimum 44x44px
- Proper `aria-label` on all interactive elements
- Focus rings visible on keyboard navigation

---

## Files Created/Modified

```text
MODIFIED:
  src/index.css          — GlobeID dark theme tokens
  tailwind.config.ts     — Extended colors, keyframes, animations
  vite.config.ts         — PWA plugin config
  index.html             — PWA meta tags, theme-color
  src/App.tsx            — New routing, AppShell wrapper
  package.json           — vite-plugin-pwa dependency

CREATED:
  public/manifest.json
  src/lib/demoData.ts
  src/hooks/useMotion.ts
  src/hooks/useAI.ts
  src/components/ui/GlassCard.tsx
  src/components/ui/IdentityScore.tsx
  src/components/layout/AppShell.tsx
  src/components/layout/BottomTabBar.tsx
  src/components/layout/FAB.tsx
  src/components/layout/AnimatedPage.tsx
  src/components/ai/AIAssistantButton.tsx
  src/components/ai/AIAssistantSheet.tsx
  src/screens/LockScreen.tsx
  src/screens/Home.tsx
  src/screens/Identity.tsx
  src/screens/Wallet.tsx
  src/screens/Travel.tsx
  src/screens/Profile.tsx
```

