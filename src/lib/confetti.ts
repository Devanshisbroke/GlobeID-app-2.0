/**
 * Lightweight confetti emitter (BACKLOG K 133).
 *
 * Spawns a fixed-position canvas, runs a particle simulation for a
 * bounded duration, then auto-removes itself. Pure DOM/canvas, no
 * runtime dependency, ~3KB minified. Respects prefers-reduced-motion
 * by simply no-oping.
 *
 * Used on doc-verified moments (passport scan complete, identity
 * verification success) and major positive transitions.
 */

interface ConfettiParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  rotation: number;
  rotationSpeed: number;
  color: string;
  size: number;
  shape: "rect" | "circle";
  life: number;
}

const COLORS = [
  "#22c55e", // green
  "#eab308", // amber
  "#ef4444", // red
  "#3b82f6", // blue
  "#a855f7", // violet
  "#ec4899", // pink
];

export interface ConfettiOptions {
  /** Number of particles. Default 80. */
  count?: number;
  /** Duration in ms. Default 1800. */
  duration?: number;
  /** Origin y as fraction of viewport. Default 0.4. */
  originY?: number;
}

export function fireConfetti(options: ConfettiOptions = {}): void {
  if (typeof document === "undefined" || typeof window === "undefined") return;
  if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return;

  const count = options.count ?? 80;
  const duration = options.duration ?? 1800;
  const originY = options.originY ?? 0.4;

  const canvas = document.createElement("canvas");
  canvas.style.position = "fixed";
  canvas.style.inset = "0";
  canvas.style.width = "100%";
  canvas.style.height = "100%";
  canvas.style.pointerEvents = "none";
  canvas.style.zIndex = "9999";
  canvas.width = window.innerWidth * window.devicePixelRatio;
  canvas.height = window.innerHeight * window.devicePixelRatio;
  document.body.appendChild(canvas);

  const ctx = canvas.getContext("2d");
  if (!ctx) {
    canvas.remove();
    return;
  }
  ctx.scale(window.devicePixelRatio, window.devicePixelRatio);

  const particles: ConfettiParticle[] = [];
  const cx = window.innerWidth / 2;
  const cy = window.innerHeight * originY;
  for (let i = 0; i < count; i++) {
    const angle = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 0.7;
    const speed = 6 + Math.random() * 6;
    particles.push({
      x: cx,
      y: cy,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      rotation: Math.random() * Math.PI,
      rotationSpeed: (Math.random() - 0.5) * 0.4,
      color: COLORS[Math.floor(Math.random() * COLORS.length)]!,
      size: 4 + Math.random() * 6,
      shape: Math.random() > 0.5 ? "rect" : "circle",
      life: 1,
    });
  }

  let rafId = 0;
  const start = performance.now();

  const step = (t: number) => {
    const elapsed = t - start;
    const progress = elapsed / duration;
    if (progress >= 1) {
      cancelAnimationFrame(rafId);
      canvas.remove();
      return;
    }
    ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
    for (const p of particles) {
      // gravity
      p.vy += 0.18;
      // air resistance
      p.vx *= 0.99;
      p.vy *= 0.99;
      p.x += p.vx;
      p.y += p.vy;
      p.rotation += p.rotationSpeed;
      p.life = 1 - progress;

      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rotation);
      ctx.globalAlpha = Math.max(0, p.life);
      ctx.fillStyle = p.color;
      if (p.shape === "rect") {
        ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 0.6);
      } else {
        ctx.beginPath();
        ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
    rafId = requestAnimationFrame(step);
  };
  rafId = requestAnimationFrame(step);
}
