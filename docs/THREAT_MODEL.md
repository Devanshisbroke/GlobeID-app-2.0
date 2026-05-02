# GlobeID Threat Model

This document is a living STRIDE-based threat model for the GlobeID mobile
client (the Capacitor + React WebView app shipped in this repo). It exists so
that future feature design changes can be evaluated against a shared baseline,
and so security-relevant changes are not retrofitted.

## Scope

- **In scope.** The mobile client (TS/React + Capacitor Android shell), local
  state stores (Zustand persisted to `localStorage`), the document scanner +
  OCR pipeline, the wallet pass surface, and any data the client puts into the
  OS clipboard / OS notification center / OS keychain.
- **Out of scope (called out, not modelled).** The `globeid-server` HTTP
  surface (covered in its own threat model), payment-rail integrations
  (Stripe, FX provider), and OS-level threats (rooted device, hostile
  keyboard, malicious accessibility service).

## Assets

| Asset | Sensitivity | Storage |
|---|---|---|
| Passport / national-ID number | High (PII + entitled-credential) | `userStore.documents` (localStorage) |
| MRZ scan output | High (PII) | In-memory only; not persisted |
| Boarding-pass QR payload | Medium (entitled-access) | `userStore.documents` |
| Visa / residency document | High (PII + entitled-credential) | `userStore.documents` |
| Identity score factors | Low (derived) | `userStore.profile` |
| Wallet balances + transactions | Medium (financial) | `walletStore` |
| Clipboard | High (transient) | OS clipboard |
| Brightness / haptic settings | Low | Not persisted |
| Theme + quiet-hours prefs | Low | `localStorage:globeid:themePrefs`, `localStorage:globeid:scheduledJobs:prefs` |

## Trust boundaries

```
┌──────────────┐  HTTPS  ┌────────────┐  ─────  ┌─────────────────┐
│  Native shell│◀───────▶│ React UI   │◀──────▶│ globeid-server  │
│  (Capacitor) │         │ (WebView)  │         │ (out of scope)  │
└──────┬───────┘         └─────┬──────┘         └─────────────────┘
       │ JS bridge             │
       │                       │ localStorage
       ▼                       ▼
   Camera, NFC,           Persisted
   Brightness,           userStore /
   Clipboard,           walletStore /
   Keychain             alertsStore
```

## STRIDE

### Spoofing
| ID | Threat | Mitigation | Status |
|---|---|---|---|
| S-1 | Attacker resumes a backgrounded app and views passport details | App-lock biometric after 30 s background (P 171, **planned**); LockScreen present today | Partial |
| S-2 | Hostile site embeds the WebView and impersonates a verified pass | Capacitor scheme `globeid://` + `androidScheme: https` lock the WebView origin | Done |

### Tampering
| ID | Threat | Mitigation | Status |
|---|---|---|---|
| T-1 | User edits localStorage to forge an identity score | Identity score is derived, not authoritative; server-side validation required for any privileged action | Done (architectural) |
| T-2 | Hostile JS modifies a boarding-pass document in flight | All mutating store methods go through Zustand setters; no global mutation API exposed | Done |

### Repudiation
| ID | Threat | Mitigation | Status |
|---|---|---|---|
| R-1 | User claims they did not view a vault entry | Audit log for vault access (P 175, **planned**) | Open |

### Information disclosure
| ID | Threat | Mitigation | Status |
|---|---|---|---|
| I-1 | Passport number persists in OS clipboard after copy | `secureCopy()` auto-clears after 30 s if untouched (P 176) | **Done in this PR** |
| I-2 | PassDetail visible in screen recording / app switcher | Screenshot blocking on PassDetail (P 172, needs custom Android plugin) | Open |
| I-3 | localStorage readable by any cohabiting WebView | Capacitor isolates WebView per app on Android 5+ | Done (platform) |
| I-4 | Vault data on disk readable from a rooted device | At-rest encryption (libsodium / WebCrypto) (P 173, **planned**) | Open |

### Denial of service
| ID | Threat | Mitigation | Status |
|---|---|---|---|
| D-1 | Quiet hours bypassed → notification storm wakes user | `isQuietHour()` gates `scheduledJobs.tick()` (O 163) | **Done in this PR** |
| D-2 | OCR worker hangs the UI | Tesseract runs in a Web Worker; UI yields via `useDeferredValue` candidate | Partial |

### Elevation of privilege
| ID | Threat | Mitigation | Status |
|---|---|---|---|
| E-1 | Capacitor JS bridge invoked from a hostile origin | Allowlist of native plugins; `cleartext: false`, `androidScheme: https` | Done |

## Tracking

- Items marked **planned** are in `BACKLOG.md` under section P.
- New threats should be added with a STRIDE letter prefix and a status of
  `Open` / `Partial` / `Done`. Status transitions happen in the same PR that
  ships the mitigation.
