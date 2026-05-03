/**
 * Theme preferences — accent colour, reduce-transparency, density,
 * high-contrast, and auto-by-time-of-day mode.
 *
 * Stored in `localStorage` under `globeid:themePrefs` so the choice
 * persists across launches. Applied at boot by `applyThemePrefs()`
 * (called from `main.tsx`) and re-applied by individual setters.
 *
 * Implementation:
 *  - accent → overrides `--p7-brand` HSL token on documentElement.
 *  - reduceTransparency → `data-reduce-transparency` on <html>.
 *  - density → `data-density` on <html>; CSS reads `[data-density='compact']`.
 *  - highContrast → `data-high-contrast` on <html>; lifts border tier and
 *    forces solid-on-solid text.
 *  - autoTimeOfDay → enables a hourly tick that switches `theme` between
 *    light/dark based on the device's local clock (sunrise/sunset
 *    approximated as 06:00/19:00 — close enough for a UX hint).
 */
import { ACCENTS, DEFAULT_ACCENT_ID } from "./themeAccents";
export {
  ACCENTS,
  DEFAULT_ACCENT_ID,
  type AccentOption,
} from "./themeAccents";

export type Density = "compact" | "comfortable" | "spacious";

export interface ThemePrefs {
  accentId: string;
  reduceTransparency: boolean;
  density: Density;
  highContrast: boolean;
  /** When true, light/dark switches automatically by local time. */
  autoTimeOfDay: boolean;
}

const STORAGE_KEY = "globeid:themePrefs";
const DEFAULT_PREFS: ThemePrefs = {
  accentId: DEFAULT_ACCENT_ID,
  reduceTransparency: false,
  density: "comfortable",
  highContrast: false,
  autoTimeOfDay: false,
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
      density: ["compact", "comfortable", "spacious"].includes(
        parsed.density as string,
      )
        ? (parsed.density as Density)
        : "comfortable",
      highContrast: parsed.highContrast === true,
      autoTimeOfDay: parsed.autoTimeOfDay === true,
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

function applyAccent(id: string): void {
  if (typeof document === "undefined") return;
  const accent = ACCENTS.find((a) => a.id === id) ?? ACCENTS[0]!;
  const root = document.documentElement;
  root.style.setProperty("--p7-brand", accent.hsl);
  root.style.setProperty("--p7-brand-strong", accent.hslStrong);
  root.style.setProperty("--p7-brand-soft", `${accent.hsl} / 0.10`);
}

function applyReduceTransparency(on: boolean): void {
  if (typeof document === "undefined") return;
  document.documentElement.dataset.reduceTransparency = on ? "true" : "false";
}

function applyDensity(d: Density): void {
  if (typeof document === "undefined") return;
  document.documentElement.dataset.density = d;
}

function applyHighContrast(on: boolean): void {
  if (typeof document === "undefined") return;
  document.documentElement.dataset.highContrast = on ? "true" : "false";
}

/** Apple-style: dark after sunset (~19:00), light after sunrise (~06:00).
 *  Returns the theme that *should* be active right now. */
export function themeForTimeOfDay(now: Date = new Date()): "light" | "dark" {
  const h = now.getHours();
  return h >= 6 && h < 19 ? "light" : "dark";
}

let autoTimer: ReturnType<typeof setInterval> | null = null;

function applyAutoTimeOfDay(on: boolean): void {
  if (typeof window === "undefined") return;
  if (autoTimer !== null) {
    clearInterval(autoTimer);
    autoTimer = null;
  }
  if (!on) return;
  // Capture next-themes' setter via DOM class, avoiding a hard dep here.
  const tick = () => {
    const root = document.documentElement;
    const want = themeForTimeOfDay();
    const isDark = root.classList.contains("dark");
    if (want === "dark" && !isDark) {
      root.classList.add("dark");
      root.style.colorScheme = "dark";
    } else if (want === "light" && isDark) {
      root.classList.remove("dark");
      root.style.colorScheme = "light";
    }
  };
  tick();
  // Recheck every 5 min — cheap and timezone-shifts (DST, traveling)
  // get picked up without a new app launch.
  autoTimer = setInterval(tick, 5 * 60_000);
}

/** Boot-time call from main.tsx — applies persisted prefs. */
export function applyThemePrefs(): void {
  const prefs = readPrefs();
  applyAccent(prefs.accentId);
  applyReduceTransparency(prefs.reduceTransparency);
  applyDensity(prefs.density);
  applyHighContrast(prefs.highContrast);
  applyAutoTimeOfDay(prefs.autoTimeOfDay);
}

export function setAccent(id: string): void {
  const accent = ACCENTS.find((a) => a.id === id) ?? ACCENTS[0]!;
  const prefs = readPrefs();
  prefs.accentId = accent.id;
  writePrefs(prefs);
  applyAccent(prefs.accentId);
}

export function setReduceTransparency(on: boolean): void {
  const prefs = readPrefs();
  prefs.reduceTransparency = on;
  writePrefs(prefs);
  applyReduceTransparency(on);
}

export function setDensity(d: Density): void {
  const prefs = readPrefs();
  prefs.density = d;
  writePrefs(prefs);
  applyDensity(d);
}

export function setHighContrast(on: boolean): void {
  const prefs = readPrefs();
  prefs.highContrast = on;
  writePrefs(prefs);
  applyHighContrast(on);
}

export function setAutoTimeOfDay(on: boolean): void {
  const prefs = readPrefs();
  prefs.autoTimeOfDay = on;
  writePrefs(prefs);
  applyAutoTimeOfDay(on);
}
