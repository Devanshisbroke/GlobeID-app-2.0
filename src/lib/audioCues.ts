/**
 * audioCues — Tone.js-backed feedback layer (BACKLOG K).
 *
 * Tone.js itself is **dynamically imported** so the synth engine
 * (~95 KB gzipped) only ships when the user actually triggers a
 * cue, not on first paint. The first cue takes the cost of the
 * import + AudioContext warmup; subsequent cues reuse the same
 * synth.
 *
 * Cues:
 *   success  — short major triad chime (C5 → E5 → G5)
 *   error    — descending tritone for "something's wrong"
 *   scan     — single high-frequency click (camera shutter feel)
 *   tap      — micro click for navigation
 *
 * Honours `prefers-reduced-motion` AND a persisted user opt-out
 * (`globeid:audioCues:enabled`). Fails silently if the user's
 * browser blocks AudioContext outside a gesture — we just don't
 * play the cue.
 */

const STORAGE_KEY = "globeid:audioCues:enabled";

// Type alias matching the subset of Tone.PolySynth we touch.
interface SynthLike {
  triggerAttackRelease: (
    notes: string | string[],
    duration: string | number,
    time?: number,
    velocity?: number,
  ) => unknown;
  toDestination: () => SynthLike;
  dispose?: () => void;
}

interface ToneModule {
  start: () => Promise<void>;
  PolySynth: new (...args: unknown[]) => SynthLike;
  Synth: unknown;
  now: () => number;
  context: { state: string };
}

let synthPromise: Promise<{ tone: ToneModule; synth: SynthLike } | null> | null = null;

function isAudioEnabled(): boolean {
  if (typeof localStorage === "undefined") return true;
  try {
    const v = localStorage.getItem(STORAGE_KEY);
    if (v === null) return true;
    return v === "true";
  } catch {
    return true;
  }
}

function prefersReducedMotion(): boolean {
  if (typeof matchMedia !== "function") return false;
  try {
    return matchMedia("(prefers-reduced-motion: reduce)").matches;
  } catch {
    return false;
  }
}

async function getSynth(): Promise<{ tone: ToneModule; synth: SynthLike } | null> {
  if (synthPromise) return synthPromise;
  synthPromise = (async () => {
    try {
      const tone = (await import("tone")) as unknown as ToneModule;
      const synth = new tone.PolySynth(tone.Synth, {
        oscillator: { type: "triangle" },
        envelope: { attack: 0.005, decay: 0.1, sustain: 0.15, release: 0.4 },
        volume: -10,
      }).toDestination();
      return { tone, synth };
    } catch {
      return null;
    }
  })();
  return synthPromise;
}

async function play(notes: string[], spacing = 0.06, duration = "16n"): Promise<void> {
  if (!isAudioEnabled()) return;
  if (prefersReducedMotion()) return;
  const ctx = await getSynth();
  if (!ctx) return;
  try {
    if (ctx.tone.context.state !== "running") {
      await ctx.tone.start();
    }
    const t0 = ctx.tone.now();
    notes.forEach((n, i) => {
      ctx.synth.triggerAttackRelease(n, duration, t0 + i * spacing, 0.6);
    });
  } catch {
    /* user gesture missing or context blocked — silent */
  }
}

export const audioCues = {
  success: (): Promise<void> => play(["C5", "E5", "G5"], 0.06, "16n"),
  error: (): Promise<void> => play(["G4", "D#4"], 0.08, "8n"),
  scan: (): Promise<void> => play(["A6"], 0, "32n"),
  tap: (): Promise<void> => play(["E6"], 0, "64n"),
  unlock: (): Promise<void> => play(["G4", "B4", "D5", "G5"], 0.05, "32n"),
  setEnabled(enabled: boolean): void {
    try {
      localStorage.setItem(STORAGE_KEY, String(enabled));
    } catch {
      /* ignore */
    }
  },
  isEnabled: isAudioEnabled,
};
