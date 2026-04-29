/**
 * Slice-F — day-of-week × category heatmap powered by `@visx/heatmap`.
 *
 * Visx is used here rather than recharts because heatmaps are not one of
 * recharts' native chart types, and visx exposes the low-level primitives
 * we want (`HeatmapRect` + deterministic scaling).
 */
import React, { useMemo } from "react";
import { Group } from "@visx/group";
import { HeatmapRect } from "@visx/heatmap";
import { scaleLinear, scaleBand } from "@visx/scale";
import type { HeatmapCell } from "@/lib/analytics";

const CATEGORIES = [
  "transport",
  "food",
  "hotel",
  "shopping",
  "flight",
  "transfer",
  "entertainment",
] as const;

const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

interface Props {
  data: HeatmapCell[];
  width?: number;
  height?: number;
}

const CategoryHeatmap: React.FC<Props> = ({ data, height = 180 }) => {
  // visx wants nested bins[day][category].
  const matrix = useMemo(() => {
    const m: Array<{ bin: number; bins: Array<{ bin: number; count: number }> }> = [];
    for (let dayIdx = 0; dayIdx < 7; dayIdx++) {
      const bins = CATEGORIES.map((cat, catIdx) => {
        const cell = data.find((d) => d.day === dayIdx && d.category === cat);
        return { bin: catIdx, count: cell ? cell.spend : 0 };
      });
      m.push({ bin: dayIdx, bins });
    }
    return m;
  }, [data]);

  const maxSpend = useMemo(() => {
    let max = 0;
    for (const row of matrix) {
      for (const b of row.bins) if (b.count > max) max = b.count;
    }
    return Math.max(1, max);
  }, [matrix]);

  const labelWidth = 36;
  const topPad = 20;
  const bottomPad = 6;
  const innerWidth = 320 - labelWidth;
  const innerHeight = height - topPad - bottomPad;
  const binWidth = innerWidth / CATEGORIES.length;
  const binHeight = innerHeight / 7;

  const colorScale = scaleLinear<string>({
    domain: [0, maxSpend],
    range: ["rgba(96,165,250,0.05)", "rgba(96,165,250,0.95)"],
  });
  const opacityScale = scaleLinear<number>({
    domain: [0, maxSpend],
    range: [0.15, 1],
  });
  const yScale = scaleBand<number>({
    domain: Array.from({ length: 7 }, (_, i) => i),
    range: [0, innerHeight],
    padding: 0.05,
  });
  const xScale = scaleBand<number>({
    domain: CATEGORIES.map((_, i) => i),
    range: [0, innerWidth],
    padding: 0.05,
  });

  return (
    <div className="overflow-hidden text-[10px] text-muted-foreground">
      <svg width="100%" viewBox={`0 0 ${labelWidth + innerWidth + 8} ${height}`}>
        {/* Day labels */}
        <Group top={topPad}>
          {DAYS.map((d, i) => (
            <text
              key={d}
              x={4}
              y={yScale(i)! + binHeight / 2 + 3}
              fill="currentColor"
              fontSize="9"
            >
              {d}
            </text>
          ))}
        </Group>
        {/* Category labels */}
        <Group left={labelWidth} top={14}>
          {CATEGORIES.map((c, i) => (
            <text
              key={c}
              x={xScale(i)! + binWidth / 2}
              y={0}
              textAnchor="middle"
              fill="currentColor"
              fontSize="8"
            >
              {c.slice(0, 3)}
            </text>
          ))}
        </Group>
        {/* Heatmap */}
        <Group left={labelWidth} top={topPad}>
          <HeatmapRect
            data={matrix}
            xScale={(v) => xScale(v)! ?? 0}
            yScale={(v) => yScale(v)! ?? 0}
            colorScale={colorScale}
            opacityScale={opacityScale}
            binWidth={binWidth}
            binHeight={binHeight}
            gap={2}
          >
            {(cells) =>
              cells.map((c) => (
                <rect
                  key={`${c.row}-${c.column}`}
                  className="visx-heatmap-rect"
                  width={c.width}
                  height={c.height}
                  x={c.x}
                  y={c.y}
                  fill={c.color}
                  fillOpacity={c.opacity}
                  rx={3}
                />
              ))
            }
          </HeatmapRect>
        </Group>
      </svg>
      <div className="mt-1 flex items-center justify-between text-[9px]">
        <span>low</span>
        <span>high</span>
      </div>
    </div>
  );
};

export default CategoryHeatmap;
