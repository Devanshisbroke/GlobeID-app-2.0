/**
 * Carbon footprint chart (BACKLOG I 108).
 *
 * Renders a 6-month bar chart of estimated per-passenger CO₂e from
 * the user's travel history. Bucket = calendar month; each bar is the
 * sum of `estimateFlightCarbon(distanceKm, "economy").kgCo2e` over
 * flights whose `date` falls in that month.
 *
 * Why bar not line: bars at month resolution read more naturally as
 * "discrete flying events" than a smooth line, and recharts handles
 * keyboard / VoiceOver focus on bars.
 */
import React, { useMemo } from "react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";
import { useUserStore } from "@/store/userStore";
import { distanceBetween } from "@/lib/distanceEngine";
import { estimateFlightCarbon } from "@/lib/travelInsights";
import { Surface, Text } from "@/components/ui/v2";
import { Leaf } from "lucide-react";

interface MonthBucket {
  month: string;
  label: string;
  kg: number;
}

const MONTH_LABELS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

const CarbonFootprintChart: React.FC = () => {
  const travelHistory = useUserStore((s) => s.travelHistory);

  const data: MonthBucket[] = useMemo(() => {
    const now = new Date();
    const buckets: MonthBucket[] = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
      buckets.push({
        month: key,
        label: MONTH_LABELS[d.getMonth()] ?? "—",
        kg: 0,
      });
    }
    for (const t of travelHistory) {
      const dt = new Date(t.date);
      if (!Number.isFinite(dt.getTime())) continue;
      const key = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}`;
      const idx = buckets.findIndex((b) => b.month === key);
      if (idx === -1) continue;
      const km = distanceBetween(t.from, t.to);
      buckets[idx]!.kg += estimateFlightCarbon(km, "economy").kgCo2e;
    }
    return buckets;
  }, [travelHistory]);

  const total = data.reduce((a, b) => a + b.kg, 0);
  const peak = Math.max(...data.map((d) => d.kg));

  return (
    <Surface variant="elevated" radius="surface" className="p-4">
      <header className="mb-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-p7-input bg-emerald-500/15 text-emerald-300">
            <Leaf className="w-3.5 h-3.5" strokeWidth={2} />
          </span>
          <div>
            <Text variant="body-em" tone="primary">
              Carbon footprint
            </Text>
            <Text variant="caption-1" tone="tertiary">
              Last 6 months · economy class baseline
            </Text>
          </div>
        </div>
        <div className="text-right">
          <Text variant="body-em" tone="primary" className="tabular-nums">
            {Math.round(total).toLocaleString()} kg
          </Text>
          <Text variant="caption-1" tone="tertiary">
            CO₂e
          </Text>
        </div>
      </header>
      <div className="h-32">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 4, right: 0, bottom: 0, left: 0 }}>
            <CartesianGrid
              strokeDasharray="3 3"
              vertical={false}
              stroke="hsl(var(--p7-border))"
              opacity={0.3}
            />
            <XAxis
              dataKey="label"
              axisLine={false}
              tickLine={false}
              tick={{ fontSize: 10, fill: "hsl(var(--p7-ink-tertiary))" }}
            />
            <YAxis hide domain={[0, peak === 0 ? 1 : peak * 1.2]} />
            <Tooltip
              cursor={{ fill: "hsl(var(--p7-ink-primary) / 0.05)" }}
              content={({ active, payload }) => {
                if (!active || !payload?.length) return null;
                const v = payload[0]!.value;
                return (
                  <div className="rounded-xl border border-border bg-surface-elevated px-3 py-2 shadow-depth-sm">
                    <p className="text-[11px] text-muted-foreground">
                      {payload[0]!.payload.label}
                    </p>
                    <p className="text-[13px] font-semibold text-foreground tabular-nums">
                      {Number(v).toLocaleString()} kg CO₂e
                    </p>
                  </div>
                );
              }}
            />
            <Bar
              dataKey="kg"
              fill="hsl(150, 64%, 56%)"
              radius={[6, 6, 0, 0]}
              isAnimationActive
              animationDuration={650}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
      <p className="mt-2 text-[10px] italic text-muted-foreground">
        ICAO 2018 short/medium/long-haul factors. Estimate, not certified.
      </p>
    </Surface>
  );
};

export default CarbonFootprintChart;
