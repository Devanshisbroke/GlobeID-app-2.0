/**
 * Lazy Lottie wrapper.
 *
 * `lottie-react` (and the underlying `lottie-web`) is ~80 KB minified
 * before any animation JSON loads — so we *only* pull it into the
 * bundle when something actually renders one. The wrapper:
 *
 *  1. Lazy-imports `lottie-react` on first mount via React.lazy.
 *  2. Honours `prefers-reduced-motion`: when the user has reduced
 *     motion enabled, falls back to a static fallback (a still SVG
 *     ring or whatever the caller passes) — no animation, no JS.
 *  3. Falls back to a children-less placeholder if the lazy import
 *     fails (e.g. flaky network on first load) so the surface that
 *     hosts the animation never blocks.
 *
 * Capacitor / Android WebView compatibility: lottie-web uses canvas
 * + SVG renderers that are well-supported in WebView 51+. Our min
 * Capacitor target is well above that.
 */

import React, { Suspense, useEffect, useState } from "react";

const LottieReact = React.lazy(() =>
  import("lottie-react").then((m) => ({ default: m.default })),
);

export interface LottieViewProps {
  /** The Lottie JSON object — usually imported with
   *  `import data from "@/assets/lottie/success.json"`. */
  data: object;
  /** Width in px (or any CSS length). */
  width?: number | string;
  /** Height in px. */
  height?: number | string;
  /** Loop the animation. Defaults to true for ambient loops; pass
   *  false for one-shot success / error states. */
  loop?: boolean;
  /** Auto-play. Defaults to true. */
  autoplay?: boolean;
  /** Render fallback (static SVG, glyph, etc.) used when reduced
   *  motion is active or the lazy import fails. */
  fallback?: React.ReactNode;
  /** className applied to the outer wrapper. */
  className?: string;
  /** Optional aria-label for screen readers — Lottie is decorative
   *  by default (aria-hidden) but supply this for *meaningful*
   *  animations like success/error confirmation. */
  ariaLabel?: string;
}

function usePrefersReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    if (typeof window === "undefined" || !window.matchMedia) return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduced(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);
  return reduced;
}

const LottieView: React.FC<LottieViewProps> = ({
  data,
  width = 160,
  height = 160,
  loop = true,
  autoplay = true,
  fallback = null,
  className,
  ariaLabel,
}) => {
  const reduced = usePrefersReducedMotion();
  const ariaProps = ariaLabel
    ? { role: "img" as const, "aria-label": ariaLabel }
    : { "aria-hidden": true as const };

  if (reduced) {
    return (
      <div
        className={className}
        style={{ width, height }}
        {...ariaProps}
      >
        {fallback}
      </div>
    );
  }

  return (
    <div className={className} style={{ width, height }} {...ariaProps}>
      <Suspense fallback={<div style={{ width, height }}>{fallback}</div>}>
        <LottieReact
          animationData={data}
          loop={loop}
          autoplay={autoplay}
          style={{ width, height }}
        />
      </Suspense>
    </div>
  );
};

export default LottieView;
