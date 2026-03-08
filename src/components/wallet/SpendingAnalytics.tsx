import React, { useMemo } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { BarChart, Bar, PieChart, Pie, Cell, ResponsiveContainer, XAxis, YAxis, Tooltip } from "recharts";
import type { WalletTransaction } from "@/store/walletStore";
import { useWalletStore } from "@/store/walletStore";
import { cn } from "@/lib/utils";

const CATEGORY_COLORS: Record<string, string> = {
  transport: "hsl(var(--ocean-aqua))",
  food: "hsl(var(--sunset-orange))",
  hotel: "hsl(var(--aurora-purple))",
  shopping: "hsl(var(--forest-emerald))",
  flight: "hsl(var(--cosmic-electric))",
  transfer: "hsl(var(--muted-foreground))",
  entertainment: "hsl(var(--sunset-coral))",
};

const CATEGORY_LABELS: Record<string, string> = {
  transport: "Transport",
  food: "Food & Drink",
  hotel: "Hotels",
  shopping: "Shopping",
  flight: "Flights",
  transfer: "Transfers",
  entertainment: "Entertainment",
};

interface SpendingAnalyticsProps {
  transactions: WalletTransaction[];
}

const SpendingAnalytics: React.FC<SpendingAnalyticsProps> = ({ transactions }) => {
  const { balances } = useWalletStore();

  const { byCategory, byCountry } = useMemo(() => {
    const catMap: Record<string, number> = {};
    const countryMap: Record<string, number> = {};

    transactions
      .filter((tx) => tx.amount < 0)
      .forEach((tx) => {
        const bal = balances.find((b) => b.currency === tx.currency);
        const usd = Math.abs(tx.amount) * (bal?.rate ?? 1);
        catMap[tx.category] = (catMap[tx.category] ?? 0) + usd;
        if (tx.country) {
          countryMap[tx.country] = (countryMap[tx.country] ?? 0) + usd;
        }
      });

    return {
      byCategory: Object.entries(catMap)
        .map(([name, value]) => ({ name: CATEGORY_LABELS[name] ?? name, value: Math.round(value * 100) / 100, fill: CATEGORY_COLORS[name] ?? "hsl(var(--muted-foreground))" }))
        .sort((a, b) => b.value - a.value),
      byCountry: Object.entries(countryMap)
        .map(([name, value]) => ({ name, value: Math.round(value * 100) / 100 }))
        .sort((a, b) => b.value - a.value),
    };
  }, [transactions, balances]);

  const totalSpent = byCategory.reduce((s, c) => s + c.value, 0);

  return (
    <div className="space-y-4">
      <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1">Spending Analytics</h3>

      {/* Total spent */}
      <GlassCard depth="md">
        <p className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1">Total Spent (USD)</p>
        <p className="text-2xl font-bold text-foreground tabular-nums">${totalSpent.toLocaleString(undefined, { maximumFractionDigits: 2 })}</p>
      </GlassCard>

      {/* By category - pie */}
      <GlassCard depth="md" className="space-y-3">
        <p className="text-xs font-semibold text-foreground">By Category</p>
        <div className="flex items-center gap-4">
          <div className="w-28 h-28 shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={byCategory} dataKey="value" cx="50%" cy="50%" innerRadius={28} outerRadius={50} paddingAngle={2} strokeWidth={0}>
                  {byCategory.map((entry, i) => (
                    <Cell key={i} fill={entry.fill} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex-1 space-y-1.5">
            {byCategory.map((cat) => (
              <div key={cat.name} className="flex items-center gap-2 text-xs">
                <span className="w-2 h-2 rounded-full shrink-0" style={{ background: cat.fill }} />
                <span className="text-foreground flex-1 truncate">{cat.name}</span>
                <span className="text-muted-foreground tabular-nums">${cat.value.toFixed(0)}</span>
              </div>
            ))}
          </div>
        </div>
      </GlassCard>

      {/* By country - bar */}
      {byCountry.length > 0 && (
        <GlassCard depth="md" className="space-y-3">
          <p className="text-xs font-semibold text-foreground">By Country</p>
          <div className="h-32">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={byCountry} layout="vertical" margin={{ left: 0, right: 8 }}>
                <XAxis type="number" hide />
                <YAxis type="category" dataKey="name" width={70} tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} axisLine={false} tickLine={false} />
                <Tooltip
                  formatter={(v: number) => [`$${v.toFixed(2)}`, "Spent"]}
                  contentStyle={{ background: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: 12, fontSize: 11 }}
                />
                <Bar dataKey="value" fill="hsl(var(--primary))" radius={[0, 6, 6, 0]} barSize={14} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </GlassCard>
      )}
    </div>
  );
};

export default SpendingAnalytics;
