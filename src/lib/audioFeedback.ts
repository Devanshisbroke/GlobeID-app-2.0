/**
 * Lightweight audio feedback layer — used for success / error / scan
 * cues across the app. WebAudio synthesis only (no audio files), so
 * the bundle stays small and there's nothing to license. Honours both
 * `prefers-reduced-motion` AND a per-user opt-in flag in localStorage.
 *
 * Each cue is a tiny envelope (≤200 ms) so it never feels intrusive.
 * On Capacitor / Android WebView the API is identical — Chrome's
 * AudioContext is available.
 */

const STORAGE_KEY = "globeid:audio-feedback";
let ctx: AudioContext | null = null;

function isEnabled(): boolean {
  if (typeof window === "undefined") return false;
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return false;
  try {
    // Default: enabled. Users opt out by writing "off".
    return localStorage.getItem(STORAGE_KEY) !== "off";
  } catch {
    return true;
  }
}

export function setAudioFeedbackEnabled(enabled: boolean): void {
  try {
    localStorage.setItem(STORAGE_KEY, enabled ? "on" : "off");
  } catch {
    /* private mode — fine, defaults to enabled */
  }
}

export function isAudioFeedbackEnabled(): boolean {
  return isEnabled();
}

function getCtx(): AudioContext | null {
  if (typeof window === "undefined") return null;
  if (ctx) return ctx;
  const Ctor =
    window.AudioContext ??
    (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!Ctor) return null;
  try {
    ctx = new Ctor();
    return ctx;
  } catch {
    return null;
  }
}

interface ToneSpec {
  freq: number;
  duration: number; // seconds
  type?: OscillatorType;
  /** Optional second tone played after `freq` for a small chord/up-glide. */
  followFreq?: number;
  followDelay?: number;
  gain?: number;
}

function playTone({
  freq,
  duration,
  type = "sine",
  followFreq,
  followDelay = 0.05,
  gain = 0.04,
}: ToneSpec): void {
  if (!isEnabled()) return;
  const audio = getCtx();
  if (!audio) return;
  // Resume on first interaction when AudioContext was created suspended.
  if (audio.state === "suspended") {
    void audio.resume();
  }
  const now = audio.currentTime;
  const osc = audio.createOscillator();
  const g = audio.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, now);
  if (followFreq) {
    osc.frequency.linearRampToValueAtTime(followFreq, now + followDelay);
  }
  g.gain.setValueAtTime(0, now);
  g.gain.linearRampToValueAtTime(gain, now + 0.012);
  g.gain.exponentialRampToValueAtTime(0.0001, now + duration);
  osc.connect(g).connect(audio.destination);
  osc.start(now);
  osc.stop(now + duration + 0.02);
}

export const audioCues = {
  success(): void {
    playTone({ freq: 660, followFreq: 880, duration: 0.18, type: "triangle" });
  },
  error(): void {
    playTone({ freq: 220, followFreq: 180, duration: 0.22, type: "square", gain: 0.03 });
  },
  scan(): void {
    playTone({ freq: 1320, duration: 0.08, type: "sine", gain: 0.025 });
  },
  tap(): void {
    playTone({ freq: 1080, duration: 0.04, type: "sine", gain: 0.02 });
  },
};
