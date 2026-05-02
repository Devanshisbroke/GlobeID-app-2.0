/**
 * Animated number ticker — eases the displayed value from its
 * previous render to the new prop value over `duration` ms.
 *
 * Apple Wallet and the Stripe dashboard both use this on balance
 * surfaces — when the underlying number changes (rate refresh,
 * transaction lands), the digit roll feels alive instead of an
 * abrupt jump.
 *
 * Implementation:
 *  - Pure rAF loop (no external animation lib) → no extra bytes.
 *  - Honours `prefers-reduced-motion`: when reduced, we set the
 *    final value immediately with no animation.
 *  - tabular-nums on the wrapper so digits don't reflow as they
 *    change width.
 *  - A11y: announces the *final* value via aria-live, not every
 *    intermediate frame, so screen-readers don't spam.
 */

import React, { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";

export interface AnimatedNumberProps {
  /** Target value to ease toward. */
  value: number;
  /** Number of decimal places to render. Defaults to 0. */
  decimals?: number;
  /** Animation duration in ms. Defaults to 600. */
  duration?: number;
  /** Optional prefix (e.g. "$"). */
  prefix?: string;
  /** Optional suffix (e.g. " USD"). */
  suffix?: string;
  /** className applied to the outer span. */
  className?: string;
  /** aria-label override (otherwise screen-readers read prefix+value+suffix). */
  ariaLabel?: string;
}

function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

const AnimatedNumber: React.FC<AnimatedNumberProps> = ({
  value,
  decimals = 0,
  duration = 600,
  prefix = "",
  suffix = "",
  className,
  ariaLabel,
}) => {
  const [display, setDisplay] = useState(value);
  const fromRef = useRef(value);
  const startRef = useRef<number | null>(null);
  const rafRef = useRef<number | null>(null);

  useEffect(() => {
    // First render or reduced motion → snap.
    if (prefersReducedMotion() || display === value) {
      setDisplay(value);
      fromRef.current = value;
      return;
    }
    fromRef.current = display;
    startRef.current = null;

    const tick = (t: number) => {
      if (startRef.current === null) startRef.current = t;
      const elapsed = t - startRef.current;
      const progress = Math.min(1, elapsed / duration);
      // ease-out-cubic — matches Apple Wallet's number roll.
      const eased = 1 - Math.pow(1 - progress, 3);
      const next = fromRef.current + (value - fromRef.current) * eased;
      setDisplay(next);
      if (progress < 1) {
        rafRef.current = requestAnimationFrame(tick);
      } else {
        setDisplay(value);
      }
    };

    rafRef.current = requestAnimationFrame(tick);
    return () => {
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value, duration]);

  const formatted = display.toLocaleString("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });

  return (
    <span
      className={cn("tabular-nums", className)}
      aria-label={ariaLabel ?? `${prefix}${value.toLocaleString("en-US", { minimumFractionDigits: decimals, maximumFractionDigits: decimals })}${suffix}`}
      aria-live="polite"
      aria-atomic="true"
    >
      <span aria-hidden>{prefix}{formatted}{suffix}</span>
    </span>
  );
};

export default AnimatedNumber;
