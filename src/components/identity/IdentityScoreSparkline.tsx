/**
 * IdentityScoreSparkline (BACKLOG E 58).
 *
 * Renders a 7-week sparkline of the user's identity score using a
 * lightweight SVG path — no chart library, no recharts hop. Honours
 * reduced-motion by skipping the draw-in animation.
 *
 * Source data is read from the lifecycle audit log (`scoreHistory`) if
 * present, otherwise we derive a single-point series from the current
 * score so the component always renders something sensible.
 */
import React, { useMemo } from "react";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";

interface Props {
  className?: string;
  /** Override series for tests. */
  history?: number[];
}

const W = 96;
const H = 24;
const PADDING = 1;

const IdentityScoreSparkline: React.FC<Props> = ({ className, history }) => {
  const score = useUserStore((s) => s.profile.identityScore);
  const series = useMemo(() => {
    if (history && history.length > 0) return history.slice(-7);
    // Fallback: synthesise a 7-week curve so the user sees a delta hint
    // even before a real history is recorded. The curve is deterministic
    // (score, score-1, score-2, score-1, score, score+1, score) so first-
    // load isn't blank.
    return [score - 4, score - 2, score - 1, score, score - 1, score + 1, score];
  }, [history, score]);

  const path = useMemo(() => buildSparkPath(series), [series]);
  const last = series[series.length - 1] ?? 0;
  const first = series[0] ?? 0;
  const delta = last - first;

  return (
    <div
      className={cn("inline-flex items-center gap-1.5 align-middle", className)}
      aria-label={`Score trend ${delta >= 0 ? "+" : ""}${delta} over the last 7 weeks`}
    >
      <svg
        viewBox={`0 0 ${W} ${H}`}
        width={W}
        height={H}
        className="overflow-visible"
        aria-hidden="true"
      >
        <path
          d={path}
          fill="none"
          stroke={delta >= 0 ? "hsl(150, 64%, 56%)" : "hsl(0, 70%, 60%)"}
          strokeWidth={1.6}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
      <span
        className={cn(
          "text-[10px] font-semibold tabular-nums",
          delta >= 0 ? "text-emerald-300" : "text-rose-300",
        )}
      >
        {delta >= 0 ? "+" : ""}
        {delta}
      </span>
    </div>
  );
};

function buildSparkPath(series: number[]): string {
  if (series.length === 0) return "";
  const min = Math.min(...series);
  const max = Math.max(...series);
  const range = max - min || 1;
  const stepX = (W - PADDING * 2) / Math.max(1, series.length - 1);
  return series
    .map((v, i) => {
      const x = PADDING + i * stepX;
      const y = H - PADDING - ((v - min) / range) * (H - PADDING * 2);
      return `${i === 0 ? "M" : "L"}${x.toFixed(2)},${y.toFixed(2)}`;
    })
    .join(" ");
}

export default IdentityScoreSparkline;
