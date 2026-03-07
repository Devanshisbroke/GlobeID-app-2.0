

# Kiosk → App Identity Verification Flow — Implementation Plan

## Scope Assessment

This project has **no backend connected** (no Supabase). The implementation will be a **full client-side simulation** with realistic state machines, token structures, QR flows, and animations — structured so a real backend can be plugged in later. All verification logic, session lifecycle, and token signing will be simulated with demo data.

When you're ready to add a real backend, we'll connect Supabase and migrate the stubs to edge functions + database tables.

---

## What We'll Build

### 1. Verification Session State Machine
- `src/lib/verificationSession.ts` — TypeScript state machine managing the full lifecycle: `idle → pending → app_scanned → verified → expired/failed`
- Session model with `id`, `kioskToken`, `passportHash`, `countryCode`, `status`, `createdAt`, `expiresAt`, `receipt`
- TTL enforcement (30–120s configurable), auto-expiry timers
- Simulated signed tokens (JWT-like structure with `iss`, `kid`, `iat`, `exp`, `nonce`, `session_id`)

### 2. Token & Crypto Simulation
- `src/lib/tokenService.ts` — Generate demo JWS-like tokens, simulated HMAC signatures, nonce tracking
- Token format matches the spec: `{ iss: "terracore", kid, iat, exp, session_id, user_id, nonce }`
- Replay protection via nonce set (in-memory)
- Helper to generate QR payload strings from tokens

### 3. QR Code Display — Identity Link Screen
- Update `src/screens/Identity.tsx` to add a **"Link at Kiosk"** section with:
  - Dynamic QR code (SVG-based, no heavy library — use a lightweight QR encoder)
  - Auto-refresh every 25s with countdown timer
  - Pulse glow animation while waiting (`scale(1) → scale(1.02)`, 1400ms)
  - Status indicator: Waiting → Processing → Verified
  - 6-digit short code fallback for manual entry
- `src/hooks/useVerificationSession.ts` — hook managing QR generation, polling simulation, session state

### 4. Kiosk Simulator (Dev Tool)
- `src/screens/KioskSimulator.tsx` — accessible via `/kiosk-sim` route (dev only)
- UI sections:
  - **Passport Scan**: manual country/passport-hash entry or "Quick Scan" button
  - **App QR Scanner**: text input to paste QR payload, or button to simulate scanning the app's current QR
  - **Controls**: country code selector, toggle biometric pass/fail, inject delay, force signature error
  - **Session Monitor**: live session status, token details, timeline of events
- Connected to the same state machine as the app (shared via React context or a simple event bus)

### 5. Welcome Animation Sequence
- `src/components/identity/WelcomeOverlay.tsx` — full-screen overlay triggered on verification
- Animation sequence (all transform/opacity only):
  1. QR fade-out: 120ms
  2. Country flag reveal with scale + clip-path: 300ms
  3. Light sweep gradient (opacity + translateX): 250ms
  4. "Welcome to [Country]!" text fade-in + translateY(-8px): 280ms
  5. Dashboard reveal scale(0.98→1): 320ms
- Country-specific data: flag emoji, greeting text, local currency name, accent color hint
- `prefers-reduced-motion` fallback: skip animation, show static welcome card

### 6. Audit Event Log
- `src/lib/auditLog.ts` — in-memory audit trail: `kiosk_scan_received`, `app_qr_generated`, `session_verified`, `receipt_created`
- Viewable in Kiosk Simulator and Profile > Developer section

### 7. Demo Data Extensions
- Add to `demoData.ts`: verification sessions, country themes (IN, US, AE, SG, GB), kiosk definitions, sample receipts
- Country theme data: `{ code, name, flag, greeting, currency, accentColor }`

### 8. Shared Event Bus
- `src/lib/eventBus.ts` — simple pub/sub (`on`/`emit`/`off`) to simulate WebSocket-like real-time updates between kiosk simulator and app screens
- Events: `session:created`, `session:app_scanned`, `session:verified`, `session:failed`

---

## Files Created/Modified

```text
CREATED:
  src/lib/verificationSession.ts   — Session state machine + types
  src/lib/tokenService.ts          — Demo token generation + nonce tracking
  src/lib/auditLog.ts              — In-memory audit event log
  src/lib/eventBus.ts              — Pub/sub for simulated real-time updates
  src/lib/qrEncoder.ts             — Lightweight QR code SVG generator
  src/lib/countryThemes.ts         — Country-specific welcome data
  src/hooks/useVerificationSession.ts — Hook for identity link flow
  src/components/identity/WelcomeOverlay.tsx — Welcome animation
  src/components/identity/QRDisplay.tsx      — QR with pulse + countdown
  src/components/identity/SessionStatus.tsx  — Status indicator
  src/screens/KioskSimulator.tsx   — Dev kiosk simulator

MODIFIED:
  src/screens/Identity.tsx         — Add "Link at Kiosk" QR section
  src/lib/demoData.ts              — Country themes, sessions, kiosks
  src/App.tsx                      — Add /kiosk-sim route
  tailwind.config.ts               — Add welcome animation keyframes
```

## Technical Notes

- **No external QR library** — we'll use a compact alphanumeric QR encoder (~200 lines) that outputs SVG paths. Keeps bundle small.
- **State shared via event bus**, not React context — keeps kiosk simulator decoupled and simulates real WebSocket behavior.
- **All animations GPU-only**: transform + opacity, `cubic-bezier(0.22, 1, 0.36, 1)` easing, motion tokens from `useMotion`.
- **Backend-ready structure**: `tokenService` and `verificationSession` have async interfaces so swapping to real API calls later is a find-and-replace.

