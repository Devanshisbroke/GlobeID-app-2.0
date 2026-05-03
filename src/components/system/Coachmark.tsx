/**
 * First-launch coachmark system (BACKLOG I).
 *
 * Renders a sequence of light overlay tooltips the first time the
 * user lands on a screen. Each step targets a DOM element via
 * `data-coachmark="<key>"` and surfaces a labelled tooltip pinned
 * to the element's bounding rect.
 *
 * Persistence: each step is keyed and remembered in localStorage
 * under `globeid:coachmarks:<key>`. Once dismissed it never returns.
 *
 * Implementation notes:
 *  - We listen for `resize` + `scroll` so the tooltip stays aligned
 *    when the layout reflows. The position is recomputed via rAF so
 *    it remains 120Hz-smooth.
 *  - Click anywhere outside the tooltip → advance/dismiss.
 *  - Respects prefers-reduced-motion (no entrance spring).
 */
import React, { useCallback, useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { spring } from "@/lib/motion-tokens";

const STORAGE_PREFIX = "globeid:coachmark:";

export interface CoachmarkStep {
  key: string;
  /** `data-coachmark` attribute value of the target element. */
  target: string;
  title: string;
  body: string;
  /** Where the tooltip arrow points relative to the target. */
  placement?: "top" | "bottom";
}

function isDismissed(key: string): boolean {
  try {
    return localStorage.getItem(STORAGE_PREFIX + key) === "1";
  } catch {
    return true;
  }
}

function dismiss(key: string): void {
  try {
    localStorage.setItem(STORAGE_PREFIX + key, "1");
  } catch {
    /* ignore */
  }
}

interface Position {
  top: number;
  left: number;
  width: number;
  height: number;
}

const Coachmark: React.FC<{ steps: CoachmarkStep[] }> = ({ steps }) => {
  const visibleSteps = steps.filter((s) => !isDismissed(s.key));
  const [active, setActive] = useState<number>(visibleSteps.length > 0 ? 0 : -1);
  const [pos, setPos] = useState<Position | null>(null);

  const measure = useCallback(() => {
    if (active < 0 || active >= visibleSteps.length) {
      setPos(null);
      return;
    }
    const step = visibleSteps[active]!;
    const el = document.querySelector<HTMLElement>(
      `[data-coachmark="${step.target}"]`,
    );
    if (!el) {
      setPos(null);
      return;
    }
    const r = el.getBoundingClientRect();
    setPos({
      top: r.top + window.scrollY,
      left: r.left + window.scrollX,
      width: r.width,
      height: r.height,
    });
  }, [active, visibleSteps]);

  useEffect(() => {
    if (active < 0) return;
    let rafId = 0;
    const tick = () => {
      measure();
      rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);
    const onResize = () => measure();
    window.addEventListener("resize", onResize);
    window.addEventListener("scroll", onResize, true);
    return () => {
      cancelAnimationFrame(rafId);
      window.removeEventListener("resize", onResize);
      window.removeEventListener("scroll", onResize, true);
    };
  }, [active, measure]);

  const advance = useCallback(() => {
    if (active < 0) return;
    const step = visibleSteps[active];
    if (step) dismiss(step.key);
    setActive((i) => (i + 1 < visibleSteps.length ? i + 1 : -1));
  }, [active, visibleSteps]);

  if (active < 0 || !pos) return null;
  const step = visibleSteps[active]!;
  const placement: "top" | "bottom" = step.placement ?? "bottom";
  const tooltipTop =
    placement === "bottom" ? pos.top + pos.height + 12 : pos.top - 100;

  return (
    <AnimatePresence>
      <motion.div
        key="overlay"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.16 }}
        className="fixed inset-0 z-[100] pointer-events-auto"
        onClick={advance}
        style={{
          background:
            "radial-gradient(circle at center, transparent 0, rgba(0,0,0,0.55) 60%)",
        }}
      />
      <motion.div
        key={step.key}
        initial={{ opacity: 0, y: placement === "bottom" ? -8 : 8 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0 }}
        transition={spring.snap}
        className="fixed z-[101] pointer-events-auto"
        style={{
          top: tooltipTop,
          left: Math.max(12, Math.min(window.innerWidth - 280 - 12, pos.left)),
          width: 280,
        }}
      >
        <div className="rounded-2xl bg-[hsl(var(--p7-brand-strong))] text-white shadow-2xl px-4 py-3">
          <div className="flex items-start justify-between gap-3">
            <div className="flex-1 min-w-0">
              <div className="text-[14px] font-semibold leading-snug">
                {step.title}
              </div>
              <div className="text-[12px] text-white/85 mt-1 leading-relaxed">
                {step.body}
              </div>
            </div>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                advance();
              }}
              className="text-[11px] uppercase tracking-wider opacity-90 hover:opacity-100 px-2 py-1 rounded-md bg-white/10"
            >
              Got it
            </button>
          </div>
          <div className="mt-2 flex gap-1">
            {visibleSteps.map((_, i) => (
              <span
                key={i}
                className={`h-0.5 flex-1 rounded-full ${
                  i === active ? "bg-white" : "bg-white/30"
                }`}
              />
            ))}
          </div>
        </div>
      </motion.div>
    </AnimatePresence>
  );
};

export default Coachmark;
