/**
 * Slice-C — full analytics dashboard.
 *
 * Real data source: the wallet ledger (already real + server-backed).
 * Visualisations:
 *  - Donut: spend-by-category (pie with hole).
 *  - Line: 30-day burn rate.
 *  - Stacked bar: travel vs non-travel split.
 *  - Top-5 merchants list.
 *
 * Uses `recharts` — already in the bundle for the legacy SpendingAnalytics
 * component, so no net size increase.
 */
import React, { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { ArrowLeft } from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { GlassCard } from "@/components/ui/GlassCard";
import { useWalletStore } from "@/store/walletStore";
import {
  dailyBurn,
  spendByCategory,
  topMerchants,
  travelSplit,
  filterByDateRange,
  spendHeatmap,
} from "@/lib/analytics";
import CategoryHeatmap from "@/components/analytics/CategoryHeatmap";

const CATEGORY_COLORS: Record<string, string> = {
  transport: "#22d3ee",
  food: "#fb923c",
  hotel: "#a78bfa",
  shopping: "#34d399",
  flight: "#60a5fa",
  transfer: "#94a3b8",
  entertainment: "#f87171",
};

type RangeKey = "7d" | "30d" | "90d" | "all";

function rangeToBounds(range: RangeKey, now: Date): { from: string; to: string } {
  const to = now.toISOString().slice(0, 10);
  if (range === "all") return { from: "1970-01-01", to };
  const days = range === "7d" ? 7 : range === "30d" ? 30 : 90;
  const d = new Date(now);
  d.setUTCDate(d.getUTCDate() - days);
  return { from: d.toISOString().slice(0, 10), to };
}

const AnalyticsDashboard: React.FC = () => {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const transactions = useWalletStore((s) => s.transactions);
  const defaultCurrency = useWalletStore((s) => s.defaultCurrency);
  const [range, setRange] = useState<RangeKey>("30d");

  const filteredTx = useMemo(() => {
    const { from, to } = rangeToBounds(range, new Date());
    return filterByDateRange(transactions, from, to);
  }, [transactions, range]);

  const categoryData = useMemo(
    () =>
      spendByCategory(filteredTx).map((d) => ({
        name: d.category,
        value: Math.round(d.spend * 100) / 100,
      })),
    [filteredTx],
  );

  const burnData = useMemo(
    () =>
      dailyBurn(filteredTx, {
        now: new Date(),
        days: range === "7d" ? 7 : range === "30d" ? 30 : 90,
      }).map((d) => ({
        date: d.date.slice(5),
        total: Math.round(d.total * 100) / 100,
      })),
    [filteredTx, range],
  );

  const split = useMemo(() => travelSplit(filteredTx), [filteredTx]);
  const merchants = useMemo(() => topMerchants(filteredTx, 5), [filteredTx]);
  const heatmapData = useMemo(() => spendHeatmap(filteredTx), [filteredTx]);

  const totalSpend = split.total;

  return (
    <div className="px-4 py-6 pb-28 space-y-4">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button
            onClick={() => navigate(-1)}
            className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center"
          >
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Analytics</h1>
            <p className="text-xs text-muted-foreground">
              {t("common.loading")} · {filteredTx.length} of {transactions.length} transactions · {defaultCurrency}
            </p>
          </div>
        </div>
      </AnimatedPage>

      <div className="flex gap-2">
        {(["7d", "30d", "90d", "all"] as const).map((r) => (
          <button
            key={r}
            type="button"
            onClick={() => setRange(r)}
            className={`flex-1 rounded-full border px-3 py-1.5 text-xs transition ${
              range === r
                ? "border-primary bg-primary/15 text-foreground"
                : "border-border/40 bg-transparent text-muted-foreground hover:bg-secondary/30"
            }`}
          >
            {r === "all" ? "All time" : `Last ${r}`}
          </button>
        ))}
      </div>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">
          Spend by category
        </p>
        {categoryData.length === 0 ? (
          <p className="text-xs text-muted-foreground py-6 text-center">No spend yet.</p>
        ) : (
          <div className="h-56">
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={categoryData}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={48}
                  outerRadius={80}
                  paddingAngle={2}
                >
                  {categoryData.map((entry, i) => (
                    <Cell key={i} fill={CATEGORY_COLORS[entry.name] ?? "#94a3b8"} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: "rgba(12,12,16,0.9)",
                    border: "1px solid rgba(255,255,255,0.08)",
                    borderRadius: 8,
                    color: "#fff",
                    fontSize: 11,
                  }}
                />
                <Legend
                  iconSize={8}
                  wrapperStyle={{ fontSize: 11, color: "rgba(255,255,255,0.7)" }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        )}
      </GlassCard>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">
          30-day burn
        </p>
        <div className="h-52">
          <ResponsiveContainer>
            <LineChart data={burnData} margin={{ top: 10, right: 10, left: -18, bottom: 0 }}>
              <CartesianGrid stroke="rgba(255,255,255,0.06)" vertical={false} />
              <XAxis dataKey="date" tick={{ fill: "rgba(255,255,255,0.5)", fontSize: 10 }} />
              <YAxis tick={{ fill: "rgba(255,255,255,0.5)", fontSize: 10 }} />
              <Tooltip
                contentStyle={{
                  background: "rgba(12,12,16,0.9)",
                  border: "1px solid rgba(255,255,255,0.08)",
                  borderRadius: 8,
                  color: "#fff",
                  fontSize: 11,
                }}
              />
              <Line
                type="monotone"
                dataKey="total"
                stroke="#60a5fa"
                strokeWidth={2}
                dot={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </GlassCard>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">
          Travel vs non-travel
        </p>
        <div className="flex gap-4">
          <div className="flex-1">
            <p className="text-[11px] text-muted-foreground">Travel</p>
            <p className="text-xl font-bold text-primary">
              {split.travel.toFixed(2)} {defaultCurrency}
            </p>
          </div>
          <div className="flex-1">
            <p className="text-[11px] text-muted-foreground">Other</p>
            <p className="text-xl font-bold text-foreground">
              {split.nonTravel.toFixed(2)} {defaultCurrency}
            </p>
          </div>
        </div>
        {totalSpend > 0 && (
          <div className="mt-3 h-2 rounded-full bg-secondary/40 overflow-hidden flex">
            <div
              className="bg-primary"
              style={{ width: `${(split.travel / totalSpend) * 100}%` }}
            />
            <div
              className="bg-muted-foreground/60"
              style={{ width: `${(split.nonTravel / totalSpend) * 100}%` }}
            />
          </div>
        )}
      </GlassCard>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">
          Day × category heatmap
        </p>
        <CategoryHeatmap data={heatmapData} />
      </GlassCard>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">
          Top merchants
        </p>
        {merchants.length === 0 ? (
          <p className="text-xs text-muted-foreground py-2">No merchants yet.</p>
        ) : (
          <div className="space-y-2">
            {merchants.map((m) => (
              <div key={m.merchant} className="flex items-center justify-between text-xs">
                <div className="min-w-0 flex-1 truncate">
                  <p className="text-foreground truncate">{m.merchant}</p>
                  <p className="text-[10px] text-muted-foreground">{m.count} transactions</p>
                </div>
                <p className="font-bold text-foreground shrink-0">
                  {m.spend.toFixed(2)} {defaultCurrency}
                </p>
              </div>
            ))}
          </div>
        )}
      </GlassCard>
    </div>
  );
};

export default AnalyticsDashboard;
