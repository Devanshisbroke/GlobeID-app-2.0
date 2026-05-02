/**
 * Theme preferences — accent colour + reduce-transparency.
 *
 * Stored in `localStorage` under `globeid:themePrefs` so the choice
 * persists across launches. Applied at boot by `applyThemePrefs()`
 * (called from `main.tsx`) and re-applied by `setAccent` / `setReduceTransparency`.
 *
 * Implementation: we override the `--p7-brand` HSL token (defined in
 * `index.css`) on `document.documentElement.style` so every Tailwind
 * `brand` utility immediately rerenders with the new accent. Same
 * pattern Apple uses for Stage Manager / Mac OS accent picker.
 *
 * Reduce-transparency replaces glass surfaces with solid ones via a
 * single `data-reduce-transparency` attribute on `<html>`; CSS
 * already has the `[data-reduce-transparency='true'] .glass-*`
 * fallback rules.
 */

export interface AccentOption {
  /** Stable id stored in prefs. */
  id: string;
  /** Display name. */
  name: string;
  /** HSL triple in token form: "H S% L%". */
  hsl: string;
  /** A hover/pressed strong variant. */
  hslStrong: string;
}

export const ACCENTS: readonly AccentOption[] = [
  // Apple-style picker: 8 well-distributed hues that all read in dark + light
  { id: "azure",  name: "Azure",  hsl: "219 67% 54%", hslStrong: "219 72% 46%" }, // default
  { id: "ocean",  name: "Ocean",  hsl: "200 80% 48%", hslStrong: "200 85% 40%" },
  { id: "mint",   name: "Mint",   hsl: "168 65% 42%", hslStrong: "168 70% 36%" },
  { id: "lime",   name: "Lime",   hsl: "100 60% 44%", hslStrong: "100 65% 38%" },
  { id: "amber",  name: "Amber",  hsl: "38 92% 50%",  hslStrong: "38 95% 44%"  },
  { id: "coral",  name: "Coral",  hsl: "12 86% 60%",  hslStrong: "12 90% 52%"  },
  { id: "rose",   name: "Rose",   hsl: "340 78% 56%", hslStrong: "340 82% 48%" },
  { id: "violet", name: "Violet", hsl: "266 78% 62%", hslStrong: "266 82% 54%" },
] as const;

export const DEFAULT_ACCENT_ID = "azure";

export interface ThemePrefs {
  accentId: string;
  reduceTransparency: boolean;
}

const STORAGE_KEY = "globeid:themePrefs";
const DEFAULT_PREFS: ThemePrefs = {
  accentId: DEFAULT_ACCENT_ID,
  reduceTransparency: false,
};

function readPrefs(): ThemePrefs {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PREFS };
    const parsed = JSON.parse(raw) as Partial<ThemePrefs>;
    return {
      accentId:
        typeof parsed.accentId === "string" &&
        ACCENTS.some((a) => a.id === parsed.accentId)
          ? parsed.accentId
          : DEFAULT_ACCENT_ID,
      reduceTransparency: parsed.reduceTransparency === true,
    };
  } catch {
    return { ...DEFAULT_PREFS };
  }
}

function writePrefs(p: ThemePrefs): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(p));
  } catch {
    /* ignore */
  }
}

export function getThemePrefs(): ThemePrefs {
  return readPrefs();
}

function applyAccent(accent: AccentOption): void {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  root.style.setProperty("--p7-brand", accent.hsl);
  root.style.setProperty("--p7-brand-strong", accent.hslStrong);
  // Also feed the soft tint (used by halos / radial gradients).
  root.style.setProperty("--p7-brand-soft", `${accent.hsl} / 0.10`);
}

function applyReduceTransparency(on: boolean): void {
  if (typeof document === "undefined") return;
  document.documentElement.dataset.reduceTransparency = on ? "true" : "false";
}

/** Boot-time call from main.tsx — applies persisted prefs. */
export function applyThemePrefs(): void {
  const prefs = readPrefs();
  const accent = ACCENTS.find((a) => a.id === prefs.accentId) ?? ACCENTS[0]!;
  applyAccent(accent);
  applyReduceTransparency(prefs.reduceTransparency);
}

export function setAccent(id: string): void {
  const accent = ACCENTS.find((a) => a.id === id) ?? ACCENTS[0]!;
  const prefs = readPrefs();
  prefs.accentId = accent.id;
  writePrefs(prefs);
  applyAccent(accent);
}

export function setReduceTransparency(on: boolean): void {
  const prefs = readPrefs();
  prefs.reduceTransparency = on;
  writePrefs(prefs);
  applyReduceTransparency(on);
}
