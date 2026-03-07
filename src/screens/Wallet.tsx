import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoBalances, demoTransactions } from "@/lib/demoData";
import { demoPaymentNetworks } from "@/lib/demoServices";
import { staggerDelay } from "@/hooks/useMotion";
import { ArrowUpRight, ArrowDownLeft, RefreshCw, Search, SlidersHorizontal, QrCode, TrendingUp, Zap } from "lucide-react";
import { cn } from "@/lib/utils";

type TxFilter = "all" | "send" | "receive" | "payment" | "convert";

const Wallet: React.FC = () => {
  const [filter, setFilter] = useState<TxFilter>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [showNetworks, setShowNetworks] = useState(false);

  const totalUSD = demoBalances.reduce((acc, b) => {
    if (b.currency === "USD") return acc + b.amount;
    if (b.currency === "EUR") return acc + b.amount * 1.08;
    if (b.currency === "INR") return acc + b.amount * 0.012;
    if (b.currency === "SGD") return acc + b.amount * 0.74;
    if (b.currency === "CNY") return acc + b.amount * 0.14;
    if (b.currency === "AED") return acc + b.amount * 0.27;
    return acc;
  }, 0);

  const filteredTx = demoTransactions.filter((tx) => {
    if (filter !== "all" && tx.type !== filter) return false;
    if (searchQuery && !tx.description.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });

  const filters: { key: TxFilter; label: string }[] = [
    { key: "all", label: "All" },
    { key: "payment", label: "Payments" },
    { key: "send", label: "Sent" },
    { key: "receive", label: "Received" },
    { key: "convert", label: "Converted" },
  ];

  return (
    <div className="px-4 py-6 space-y-6">
      {/* Total Balance */}
      <AnimatedPage>
        <GlassCard className="text-center py-6 relative overflow-hidden" glow>
          <div className="absolute inset-0 bg-gradient-to-br from-neon-indigo/5 via-transparent to-neon-cyan/5 pointer-events-none" />
          <div className="relative">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-neon-indigo to-neon-cyan flex items-center justify-center mx-auto mb-3">
              <TrendingUp className="w-6 h-6 text-primary-foreground" />
            </div>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider mb-1">Total Balance</p>
            <p className="text-3xl font-bold text-foreground tabular-nums">
              ${totalUSD.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </p>
            <div className="flex gap-2 justify-center mt-5 flex-wrap">
              {[
                { icon: ArrowUpRight, label: "Send", accent: true },
                { icon: ArrowDownLeft, label: "Receive" },
                { icon: QrCode, label: "Scan" },
                { icon: RefreshCw, label: "Convert" },
              ].map((btn) => {
                const Icon = btn.icon;
                return (
                  <button
                    key={btn.label}
                    className={cn(
                      "flex items-center gap-1.5 px-4 py-2.5 rounded-xl text-xs font-medium active:scale-95 transition-all min-h-[44px]",
                      btn.accent
                        ? "bg-gradient-to-r from-neon-indigo to-neon-cyan text-primary-foreground shadow-[0_0_16px_hsl(var(--neon-cyan)/0.3)]"
                        : "glass border border-border text-foreground hover:border-accent/30"
                    )}
                  >
                    <Icon className="w-4 h-4" />
                    {btn.label}
                  </button>
                );
              })}
            </div>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Currency Cards */}
      <AnimatedPage staggerIndex={1}>
        <h3 className="text-sm font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-wider">Currencies</h3>
        <div className="grid grid-cols-2 gap-2">
          {demoBalances.map((b, i) => (
            <GlassCard
              key={b.currency}
              className="animate-fade-in cursor-pointer active:scale-[0.98] transition-all hover:border-accent/20"
              style={{ animationDelay: staggerDelay(i, 60) }}
            >
              <div className="flex items-center gap-2 mb-2">
                <span className="text-lg">{b.flag}</span>
                <span className="text-xs font-semibold text-muted-foreground">{b.currency}</span>
              </div>
              <p className="text-base font-bold text-foreground tabular-nums">
                {b.symbol}{b.amount.toLocaleString()}
              </p>
            </GlassCard>
          ))}
        </div>
      </AnimatedPage>

      {/* Payment Networks */}
      <AnimatedPage staggerIndex={2}>
        <button
          onClick={() => setShowNetworks(!showNetworks)}
          className="flex items-center justify-between w-full mb-3 px-1"
        >
          <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider flex items-center gap-1.5">
            <Zap className="w-3.5 h-3.5" />
            Payment Networks
          </h3>
          <span className="text-xs text-accent font-medium">{showNetworks ? "Hide" : "Show"}</span>
        </button>
        {showNetworks && (
          <div className="grid grid-cols-2 gap-2 animate-fade-in">
            {demoPaymentNetworks.map((n, i) => (
              <GlassCard
                key={n.id}
                className="flex items-center gap-2.5 py-3 animate-fade-in"
                style={{ animationDelay: staggerDelay(i, 40) }}
              >
                <span className="text-lg">{n.icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-medium text-foreground truncate">{n.name}</p>
                  <p className="text-[10px] text-muted-foreground">{n.region}</p>
                </div>
                {n.connected ? (
                  <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-accent/20 text-accent font-medium">✓</span>
                ) : (
                  <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-secondary text-muted-foreground">Add</span>
                )}
              </GlassCard>
            ))}
          </div>
        )}
      </AnimatedPage>

      {/* Transactions */}
      <AnimatedPage staggerIndex={3}>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Transactions</h3>
          <SlidersHorizontal className="w-4 h-4 text-muted-foreground" />
        </div>

        {/* Search */}
        <div className="relative mb-3">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search transactions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border text-xs text-foreground bg-transparent focus:border-accent outline-none min-h-[44px]"
          />
        </div>

        {/* Filters */}
        <div className="flex gap-1.5 mb-3 overflow-x-auto hide-scrollbar">
          {filters.map((f) => (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={cn(
                "px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap transition-all min-h-[32px]",
                filter === f.key
                  ? "bg-accent text-accent-foreground shadow-[0_0_10px_hsl(var(--neon-cyan)/0.3)]"
                  : "glass text-muted-foreground"
              )}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Transaction List */}
        <div className="space-y-2">
          {filteredTx.map((tx, i) => (
            <GlassCard
              key={tx.id}
              className="flex items-center gap-3 py-3 px-4 animate-fade-in cursor-pointer active:scale-[0.98] transition-transform"
              style={{ animationDelay: staggerDelay(i, 40) }}
            >
              <div className="w-9 h-9 rounded-xl bg-secondary/80 flex items-center justify-center shrink-0">
                <span className="text-base">{tx.icon}</span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{tx.description}</p>
                <p className="text-xs text-muted-foreground">{tx.date} · {tx.category}</p>
              </div>
              <p
                className={cn(
                  "text-sm font-bold tabular-nums",
                  tx.amount > 0 ? "text-accent" : "text-foreground"
                )}
              >
                {tx.amount > 0 ? "+" : ""}
                {tx.amount.toLocaleString()} {tx.currency}
              </p>
            </GlassCard>
          ))}
          {filteredTx.length === 0 && (
            <p className="text-xs text-muted-foreground text-center py-8">No transactions found</p>
          )}
        </div>
      </AnimatedPage>
    </div>
  );
};

export default Wallet;
