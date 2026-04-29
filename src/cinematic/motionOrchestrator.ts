/**
 * Slice-F GSAP timeline orchestration.
 *
 * Two real public entry points:
 *
 *   - `playHeroReveal(root)` – on first paint, staggers in all elements
 *     tagged `data-reveal` under `root`. Returns the timeline so callers
 *     can seek / reverse / kill.
 *   - `playScreenTransition(next)` – slides a screen container in from the
 *     right while fading. Designed to be called from route-level wrappers.
 *
 * These functions are intentionally thin wrappers over GSAP – the real
 * motion design lives in the timeline definitions below so it's trivial
 * to re-tune from a single place. They are no-ops in SSR / jsdom
 * (typeof window === "undefined").
 */
import { gsap } from "gsap";

export interface RevealOptions {
  stagger?: number;
  duration?: number;
  y?: number;
  ease?: string;
}

const DEFAULTS = {
  stagger: 0.05,
  duration: 0.55,
  y: 16,
  ease: "expo.out",
} satisfies Required<RevealOptions>;

/**
 * Fades + lifts every descendant that carries a `data-reveal` attribute,
 * in DOM order. Idempotent – if called twice on the same root it will
 * just re-play the timeline.
 */
export function playHeroReveal(
  root: HTMLElement | Document = typeof document !== "undefined" ? document : ({} as Document),
  opts: RevealOptions = {},
): gsap.core.Timeline | null {
  if (typeof window === "undefined") return null;
  const cfg = { ...DEFAULTS, ...opts };
  const targets = (root as ParentNode | null)?.querySelectorAll?.(
    "[data-reveal]",
  );
  if (!targets || targets.length === 0) return null;
  const tl = gsap.timeline();
  tl.from(targets, {
    y: cfg.y,
    opacity: 0,
    duration: cfg.duration,
    ease: cfg.ease,
    stagger: cfg.stagger,
  });
  return tl;
}

/**
 * Plays a directional slide-in on an element. Used for screen entrances
 * where we want a cinematic "card slides into place" feel rather than a
 * cross-fade.
 */
export function playScreenTransition(
  next: HTMLElement,
  direction: "forward" | "back" = "forward",
): gsap.core.Timeline | null {
  if (typeof window === "undefined") return null;
  const tl = gsap.timeline();
  tl.from(next, {
    x: direction === "forward" ? 24 : -24,
    opacity: 0,
    duration: 0.42,
    ease: "expo.out",
  });
  return tl;
}

/** Utility: kills any timeline still running on the given element. */
export function stopMotion(target: HTMLElement | null): void {
  if (!target) return;
  gsap.killTweensOf(target);
}
