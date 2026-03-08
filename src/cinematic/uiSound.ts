/**
 * GlobeID UI Sound System
 * Real Web Audio tones for premium tactile UI feedback
 */

const SOUND_ENABLED_KEY = "globe-sound-enabled";

class UISoundEngine {
  private ctx: AudioContext | null = null;
  private _enabled: boolean = true;

  constructor() {
    if (typeof localStorage !== "undefined") {
      const saved = localStorage.getItem(SOUND_ENABLED_KEY);
      this._enabled = saved !== "false";
    }
  }

  get enabled() { return this._enabled; }
  set enabled(val: boolean) {
    this._enabled = val;
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(SOUND_ENABLED_KEY, String(val));
    }
  }

  private getCtx() {
    if (!this.ctx && typeof AudioContext !== "undefined") {
      this.ctx = new AudioContext();
    }
    // Resume if suspended (browser policy)
    if (this.ctx?.state === "suspended") {
      this.ctx.resume();
    }
    return this.ctx;
  }

  private playTone(freq: number, dur: number, vol: number = 0.04, type: OscillatorType = "sine") {
    if (!this._enabled) return;
    try {
      const ctx = this.getCtx();
      if (!ctx) return;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.frequency.value = freq;
      osc.type = type;
      gain.gain.setValueAtTime(vol, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + dur);
    } catch {
      // Silently fail if audio not available
    }
  }

  private playChord(freqs: number[], dur: number, vol: number = 0.025) {
    freqs.forEach((f, i) => {
      setTimeout(() => this.playTone(f, dur, vol), i * 30);
    });
  }

  /** Soft click — for buttons, selections */
  click = () => this.playTone(1200, 0.04, 0.025);

  /** Tab/nav click — slightly deeper */
  navigate = () => this.playTone(880, 0.06, 0.03);

  /** Swipe gesture */
  swipe = () => this.playTone(600, 0.08, 0.02, "triangle");

  /** Success confirmation — ascending two-note */
  confirm = () => {
    this.playTone(523, 0.1, 0.03); // C5
    setTimeout(() => this.playTone(659, 0.12, 0.035), 70); // E5
  };

  /** Notification ping */
  notification = () => {
    this.playTone(988, 0.08, 0.03); // B5
    setTimeout(() => this.playTone(1319, 0.12, 0.025), 60); // E6
  };

  /** Error / warning — low tone */
  error = () => this.playTone(220, 0.18, 0.03, "triangle");

  /** Like / favorite — warm pop */
  like = () => {
    this.playTone(698, 0.06, 0.03); // F5
    setTimeout(() => this.playTone(880, 0.08, 0.025), 50); // A5
  };

  /** Toggle on/off */
  toggle = () => this.playTone(1047, 0.04, 0.02);

  /** Card open / expand */
  open = () => this.playTone(440, 0.1, 0.02, "triangle");

  /** Subtle hover feedback */
  hover = () => this.playTone(1600, 0.025, 0.01);
}

export const uiSound = new UISoundEngine();
