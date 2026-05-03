import React, { useEffect, useMemo, useRef, useState } from "react";

interface IdentityScoreProps {
  score: number; // 0-100
  size?: number;
  strokeWidth?: number;
  className?: string;
}

function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

const IdentityScore: React.FC<IdentityScoreProps> = ({
  score,
  size = 80,
  strokeWidth = 6,
  className,
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (score / 100) * circumference;
  const gradientId = useMemo(() => `score-grad-${Math.random().toString(36).slice(2, 8)}`, []);

  // Apple Wallet-style number ticker on the inner score (BACKLOG K 134).
  const [displayed, setDisplayed] = useState(score);
  const previousRef = useRef(score);
  useEffect(() => {
    if (prefersReducedMotion()) {
      setDisplayed(score);
      previousRef.current = score;
      return;
    }
    const start = previousRef.current;
    const end = score;
    if (start === end) return;
    const startedAt = performance.now();
    const dur = 700;
    let rafId = 0;
    const tick = (t: number) => {
      const p = Math.min(1, (t - startedAt) / dur);
      const eased = 1 - Math.pow(1 - p, 3); // easeOutCubic
      setDisplayed(Math.round(start + (end - start) * eased));
      if (p < 1) {
        rafId = requestAnimationFrame(tick);
      } else {
        previousRef.current = end;
      }
    };
    rafId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafId);
  }, [score]);

  return (
    <div
      className={className}
      style={{ width: size, height: size, position: "relative" }}
      role="meter"
      aria-valuenow={score}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={`Identity score: ${score} out of 100`}
    >
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <defs>
          <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="hsl(225, 73%, 57%)" />
            <stop offset="50%" stopColor="hsl(185, 72%, 48%)" />
            <stop offset="100%" stopColor="hsl(168, 70%, 45%)" />
          </linearGradient>
        </defs>
        {/* Background track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="hsl(240, 6%, 15%)"
          strokeWidth={strokeWidth}
        />
        {/* Score arc */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={`url(#${gradientId})`}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={
            {
              "--score-offset": String(offset),
              transform: "rotate(-90deg)",
              transformOrigin: "50% 50%",
            } as React.CSSProperties
          }
          className="animate-score-fill"
        />
      </svg>
      {/* HTML overlay so we can use tabular-nums and ease the number. */}
      <span
        aria-hidden
        className="absolute inset-0 grid place-items-center font-bold text-foreground tabular-nums"
        style={{ fontSize: size * 0.28 }}
      >
        {displayed}
      </span>
    </div>
  );
};

export { IdentityScore };
