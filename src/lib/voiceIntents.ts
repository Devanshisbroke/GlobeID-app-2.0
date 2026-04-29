/**
 * Slice-C — voice intent parser.
 *
 * Deterministic, side-effect-free mapping from a transcript string to a
 * navigation / action intent. Same input → same output. Grammar is a
 * small set of regex alternations; easy to unit-test and easy to extend.
 *
 * We intentionally *don't* use an LLM here. Voice commands should work
 * offline, on-device, in under 50 ms — deterministic rules do that.
 */

export type VoiceIntent =
  | { kind: "navigate"; path: string; label: string }
  | { kind: "action"; action: "refresh" | "start-scan" | "toggle-language"; label: string }
  | { kind: "query"; query: "wallet-balance" | "next-trip" | "score" | "weather"; label: string }
  | { kind: "search"; target: "hotels" | "rides" | "food" | "visa"; label: string }
  | { kind: "unknown"; transcript: string };

interface Rule {
  re: RegExp;
  build: (m: RegExpMatchArray) => VoiceIntent;
}

/** The order is meaningful — more specific patterns come first. */
const RULES: Rule[] = [
  // Navigation
  {
    re: /\b(go to|open|show)\s+(home|dashboard)\b/,
    build: () => ({ kind: "navigate", path: "/", label: "Home" }),
  },
  {
    re: /\b(go to|open|show)\s+(wallet|money)\b/,
    build: () => ({ kind: "navigate", path: "/wallet", label: "Wallet" }),
  },
  {
    re: /\b(go to|open|show)\s+(identity|passport|vault)\b/,
    build: () => ({ kind: "navigate", path: "/vault", label: "Identity vault" }),
  },
  {
    re: /\b(go to|open|show)\s+(services|super|hub)\b/,
    build: () => ({ kind: "navigate", path: "/services/super", label: "Super Services" }),
  },
  {
    re: /\b(go to|open|show)\s+(travel|trips|timeline)\b/,
    build: () => ({ kind: "navigate", path: "/timeline", label: "Timeline" }),
  },
  {
    re: /\b(go to|open|show)\s+(feed|social|posts)\b/,
    build: () => ({ kind: "navigate", path: "/feed", label: "Social feed" }),
  },
  {
    re: /\b(go to|open|show)\s+(profile|me|account)\b/,
    build: () => ({ kind: "navigate", path: "/profile", label: "Profile" }),
  },
  {
    re: /\b(go to|open|show)\s+(map|globe|planet)\b/,
    build: () => ({ kind: "navigate", path: "/planet", label: "Planet Explorer" }),
  },
  // Actions
  {
    re: /\b(refresh|reload|sync)\b/,
    build: () => ({ kind: "action", action: "refresh", label: "Refresh" }),
  },
  {
    re: /\b(scan|capture)\b.*\b(document|passport|id|visa)\b/,
    build: () => ({ kind: "action", action: "start-scan", label: "Scan document" }),
  },
  {
    re: /\b(change|switch|toggle)\s+language\b/,
    build: () => ({ kind: "action", action: "toggle-language", label: "Toggle language" }),
  },
  // Queries
  {
    re: /\b(what|show|check)\b.*\b(balance|wallet)\b/,
    build: () => ({ kind: "query", query: "wallet-balance", label: "Wallet balance" }),
  },
  {
    re: /\b(next|upcoming)\s+(trip|flight)\b/,
    build: () => ({ kind: "query", query: "next-trip", label: "Next trip" }),
  },
  {
    re: /\b(travel\s+)?score\b/,
    build: () => ({ kind: "query", query: "score", label: "Travel score" }),
  },
  {
    re: /\bweather\b/,
    build: () => ({ kind: "query", query: "weather", label: "Weather" }),
  },
  // Search
  {
    re: /\b(find|search|book)\s+(a\s+)?hotel/,
    build: () => ({ kind: "search", target: "hotels", label: "Search hotels" }),
  },
  {
    re: /\b(find|search|book)\s+(a\s+)?ride|\bcall\s+(a\s+)?(taxi|uber|cab)\b/,
    build: () => ({ kind: "search", target: "rides", label: "Search rides" }),
  },
  {
    re: /\b(find|order|get)\s+(some\s+)?food|\b(restaurant|lunch|dinner)\b/,
    build: () => ({ kind: "search", target: "food", label: "Search food" }),
  },
  {
    re: /\bvisa\b/,
    build: () => ({ kind: "search", target: "visa", label: "Visa lookup" }),
  },
];

/** Parse a raw transcript into a single best-match intent. */
export function parseIntent(raw: string): VoiceIntent {
  const t = raw.trim().toLowerCase().replace(/[^a-z0-9\s]/g, " ");
  if (!t) return { kind: "unknown", transcript: raw };
  for (const r of RULES) {
    const m = t.match(r.re);
    if (m) return r.build(m);
  }
  return { kind: "unknown", transcript: raw };
}

/**
 * Strip the "hey globe" wake word prefix if present. Returns the trimmed
 * rest; returns null if the wake word is missing (so callers can ignore
 * the transcript entirely when wake-word mode is on).
 */
export function stripWakeWord(raw: string): string | null {
  const t = raw.trim().toLowerCase();
  const m = t.match(/^(hey|ok|okay)\s+(globe|globeid|guide)\b[,\s]*/);
  if (!m) return null;
  return raw.slice(m[0].length).trim();
}
