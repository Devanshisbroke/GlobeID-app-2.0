import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoBalances, demoTransactions } from "@/lib/demoData";
import { demoPaymentNetworks } from "@/lib/demoServices";
import { staggerDelay } from "@/hooks/useMotion";
import { ArrowUpRight, ArrowDownLeft, RefreshCw, Wallet as WalletIcon, Search, SlidersHorizontal, QrCode } from "lucide-react";
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
        <GlassCard className="text-center py-6" glow>
          <WalletIcon className="w-6 h-6 mx-auto text-accent mb-2" />
          <p className="text-xs text-muted-foreground mb-1">Total Balance</p>
          <p className="text-3xl font-bold text-foreground">
            ${totalUSD.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </p>
          <div className="flex gap-2 justify-center mt-4 flex-wrap">
            <button className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-accent text-accent-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <ArrowUpRight className="w-4 h-4" />
              Send
            </button>
            <button className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl glass border border-border text-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <ArrowDownLeft className="w-4 h-4" />
              Receive
            </button>
            <button className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl glass border border-border text-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <QrCode className="w-4 h-4" />
              Scan
            </button>
            <button className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl glass border border-border text-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <RefreshCw className="w-4 h-4" />
              Convert
            </button>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Currency Cards */}
      <AnimatedPage staggerIndex={1}>
        <h3 className="text-sm font-medium text-muted-foreground mb-3 px-1">Currencies</h3>
        <div className="grid grid-cols-2 gap-2">
          {demoBalances.map((b, i) => (
            <GlassCard
              key={b.currency}
              className="animate-fade-in cursor-pointer active:scale-[0.98] transition-transform"
              style={{ animationDelay: staggerDelay(i, 60) }}
            >
              <div className="flex items-center gap-2 mb-2">
                <span className="text-lg">{b.flag}</span>
                <span className="text-xs font-medium text-muted-foreground">{b.currency}</span>
              </div>
              <p className="text-base font-semibold text-foreground">
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
          <h3 className="text-sm font-medium text-muted-foreground">Payment Networks</h3>
          <span className="text-xs text-accent">{showNetworks ? "Hide" : "Show"}</span>
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
                  <span className="text-[10px] text-accent font-medium">✓</span>
                ) : (
                  <span className="text-[10px] text-muted-foreground">Add</span>
                )}
              </GlassCard>
            ))}
          </div>
        )}
      </AnimatedPage>

      {/* Transactions */}
      <AnimatedPage staggerIndex={3}>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-sm font-medium text-muted-foreground">Transactions</h3>
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
                "px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap transition-colors min-h-[32px]",
                filter === f.key
                  ? "bg-accent text-accent-foreground"
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
              <span className="text-lg shrink-0">{tx.icon}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{tx.description}</p>
                <p className="text-xs text-muted-foreground">{tx.date} · {tx.category}</p>
              </div>
              <p
                className={cn(
                  "text-sm font-semibold tabular-nums",
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
