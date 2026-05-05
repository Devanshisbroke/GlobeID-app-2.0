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
  // H 95 — numeric resolution: "trip 3", "pass 2"
  | { kind: "numeric"; target: "trip" | "pass" | "document"; index: number; label: string }
  // H 96 — translate intent: "translate this to french" → triggers overlay
  | { kind: "translate"; toLang: string; label: string }
  // H 97 — reminder: "remind me to pack at 7pm"
  | { kind: "remind"; text: string; whenLocal: string | null; label: string }
  // H 98 — multi-step: "book a hotel in tokyo for next friday"
  | { kind: "compose"; verb: "book" | "find" | "plan"; subject: string; meta: Record<string, string>; label: string }
  | { kind: "unknown"; transcript: string };

interface Rule {
  re: RegExp;
  build: (m: RegExpMatchArray) => VoiceIntent;
}

// Map of language words that we recognise for the translate intent.
const LANG_MAP: Record<string, string> = {
  english: "en",
  spanish: "es",
  french: "fr",
  german: "de",
  italian: "it",
  portuguese: "pt",
  japanese: "ja",
  chinese: "zh",
  korean: "ko",
  arabic: "ar",
  hindi: "hi",
  russian: "ru",
};

/** The order is meaningful — more specific patterns come first. */
const RULES: Rule[] = [
  // H 96 — translate (very specific, must come before navigation)
  {
    re: /\btranslate\b.*\b(to|into|in)\s+([a-z]+)\b/,
    build: (m) => {
      const word = (m[2] ?? "").toLowerCase();
      const code = LANG_MAP[word] ?? word;
      return {
        kind: "translate",
        toLang: code,
        label: `Translate to ${word}`,
      };
    },
  },
  // H 97 — remind ("remind me to X at HH(:MM)?(am|pm)?")
  {
    re: /\bremind\s+me\s+to\s+([a-z0-9\s]+?)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b/,
    build: (m) => {
      const text = (m[1] ?? "").trim();
      const hourRaw = parseInt(m[2] ?? "0", 10);
      const minute = m[3] ? parseInt(m[3], 10) : 0;
      const ampm = m[4];
      let hour = hourRaw;
      if (ampm === "pm" && hourRaw < 12) hour = hourRaw + 12;
      else if (ampm === "am" && hourRaw === 12) hour = 0;
      const hh = String(hour).padStart(2, "0");
      const mm = String(minute).padStart(2, "0");
      return {
        kind: "remind",
        text,
        whenLocal: `${hh}:${mm}`,
        label: `Remind me to ${text} at ${hh}:${mm}`,
      };
    },
  },
  // H 95 — numeric resolution: "trip 3", "pass 2", "document 5"
  {
    re: /\b(trip|pass|document)\s+(?:number\s+)?(\d{1,3})\b/,
    build: (m) => {
      const target = m[1] as "trip" | "pass" | "document";
      const index = parseInt(m[2] ?? "0", 10);
      return {
        kind: "numeric",
        target,
        index,
        label: `${target.charAt(0).toUpperCase() + target.slice(1)} ${index}`,
      };
    },
  },
  // H 98 — compose: "book a hotel in tokyo (for next friday)?"
  // Requires at least a place OR a date modifier so simpler "find a hotel"
  // still falls through to the plain `search` intent below.
  {
    re: /\b(book|find|plan)\s+(?:a\s+)?(hotel|flight|ride|trip)\b\s+(?:(?:in|to)\s+([a-z\s]+?))(?:\s+(?:on|for)\s+([a-z0-9\s]+?))?$/,
    build: (m) => {
      const verb = (m[1] ?? "find") as "book" | "find" | "plan";
      const subject = (m[2] ?? "").toLowerCase();
      const place = (m[3] ?? "").trim();
      const when = (m[4] ?? "").trim();
      const meta: Record<string, string> = {};
      if (place) meta.place = place;
      if (when) meta.when = when;
      const placeCopy = place ? ` in ${place}` : "";
      const whenCopy = when ? ` for ${when}` : "";
      return {
        kind: "compose",
        verb,
        subject,
        meta,
        label: `${verb.charAt(0).toUpperCase() + verb.slice(1)} a ${subject}${placeCopy}${whenCopy}`.trim(),
      };
    },
  },
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
    re: /\b(go to|open|show)\s+(identity|passport)\b/,
    build: () => ({ kind: "navigate", path: "/identity", label: "Identity" }),
  },
  {
    re: /\b(go to|open|show)\s+(document\s+vault|vault|documents)\b/,
    build: () => ({ kind: "navigate", path: "/vault", label: "Document vault" }),
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
    re: /\b(go to|open|show)\s+(map|globe)\b/,
    build: () => ({ kind: "navigate", path: "/map", label: "Map" }),
  },
  {
    re: /\b(go to|open|show)\s+planet\b/,
    build: () => ({ kind: "navigate", path: "/explorer", label: "Planet Explorer" }),
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

/**
 * H 100 — "did you mean" disambiguation.
 *
 * When parseIntent returns `unknown`, run a simple keyword-overlap pass
 * against a curated set of canonical phrasings. Returns up to N best
 * suggestions ordered by score. Empty array if nothing scored above
 * the threshold.
 *
 * Pure function — no IO, no fuzzy library; tokenisation is whitespace
 * + punctuation strip + lower-case.
 */
const DISAMBIG_PHRASES: Array<{ phrase: string; intent: string }> = [
  { phrase: "open wallet", intent: "go to wallet" },
  { phrase: "open identity", intent: "go to identity" },
  { phrase: "scan passport", intent: "scan a passport" },
  { phrase: "scan document", intent: "scan a document" },
  { phrase: "find hotel", intent: "find a hotel" },
  { phrase: "find ride", intent: "find a ride" },
  { phrase: "translate to french", intent: "translate this to French" },
  { phrase: "translate to spanish", intent: "translate this to Spanish" },
  { phrase: "remind pack", intent: "remind me to pack at 7pm" },
  { phrase: "next trip", intent: "show next trip" },
  { phrase: "wallet balance", intent: "what's my balance" },
  { phrase: "travel score", intent: "show my travel score" },
  { phrase: "weather", intent: "weather" },
  { phrase: "visa", intent: "visa requirements" },
  { phrase: "social feed", intent: "open feed" },
  { phrase: "passport book", intent: "open passport book" },
  { phrase: "globe", intent: "open map" },
  { phrase: "trip", intent: "open travel" },
];

function tokenise(s: string): Set<string> {
  return new Set(
    s
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .split(/\s+/)
      .filter(Boolean),
  );
}

export function suggestIntents(transcript: string, max = 3): string[] {
  const want = tokenise(transcript);
  if (want.size === 0) return [];
  const scored: Array<{ score: number; intent: string }> = [];
  for (const { phrase, intent } of DISAMBIG_PHRASES) {
    const have = tokenise(phrase);
    let overlap = 0;
    for (const t of have) if (want.has(t)) overlap += 1;
    // Score = overlap / max-of-sizes — favours short canonical phrasings
    // when they fully match.
    const score = overlap / Math.max(have.size, 1);
    if (score > 0) scored.push({ score, intent });
  }
  scored.sort((a, b) => b.score - a.score);
  return Array.from(new Set(scored.slice(0, max).map((s) => s.intent)));
}
