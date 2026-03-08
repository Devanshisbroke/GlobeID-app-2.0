/**
 * GlobeID UI Sound System (placeholder)
 * Minimal sound hooks for tactile UI feedback
 * Actual audio files can be added later
 */

const SOUND_ENABLED = false; // Toggle when audio assets are ready

const noop = () => {};

class UISoundEngine {
  private ctx: AudioContext | null = null;

  private getCtx() {
    if (!this.ctx && typeof AudioContext !== "undefined") {
      this.ctx = new AudioContext();
    }
    return this.ctx;
  }

  private playTone(freq: number, duration: number, vol: number = 0.05) {
    if (!SOUND_ENABLED) return;
    const ctx = this.getCtx();
    if (!ctx) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.frequency.value = freq;
    osc.type = "sine";
    gain.gain.value = vol;
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + duration);
  }

  click = () => this.playTone(800, 0.06, 0.03);
  swipe = () => this.playTone(600, 0.1, 0.02);
  confirm = () => {
    this.playTone(523, 0.08, 0.04);
    setTimeout(() => this.playTone(659, 0.08, 0.04), 80);
  };
  notification = () => this.playTone(880, 0.15, 0.04);
  error = () => this.playTone(220, 0.2, 0.03);
}

export const uiSound = new UISoundEngine();
