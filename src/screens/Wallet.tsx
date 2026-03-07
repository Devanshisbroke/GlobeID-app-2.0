import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoBalances, demoTransactions } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
import { ArrowUpRight, ArrowDownLeft, RefreshCw, Wallet as WalletIcon } from "lucide-react";
import { cn } from "@/lib/utils";

const Wallet: React.FC = () => {
  const totalUSD = demoBalances.reduce((acc, b) => {
    if (b.currency === "USD") return acc + b.amount;
    if (b.currency === "EUR") return acc + b.amount * 1.08;
    if (b.currency === "INR") return acc + b.amount * 0.012;
    if (b.currency === "SGD") return acc + b.amount * 0.74;
    return acc;
  }, 0);

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
          <div className="flex gap-3 justify-center mt-4">
            <button className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-accent text-accent-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <ArrowUpRight className="w-4 h-4" />
              Send
            </button>
            <button className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl glass border border-border text-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <ArrowDownLeft className="w-4 h-4" />
              Receive
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
              className="animate-fade-in"
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

      {/* Transactions */}
      <AnimatedPage staggerIndex={2}>
        <h3 className="text-sm font-medium text-muted-foreground mb-3 px-1">Transactions</h3>
        <div className="space-y-2">
          {demoTransactions.map((tx, i) => (
            <GlassCard
              key={tx.id}
              className="flex items-center gap-3 py-3 px-4 animate-fade-in"
              style={{ animationDelay: staggerDelay(i, 40) }}
            >
              <span className="text-lg shrink-0">{tx.icon}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{tx.description}</p>
                <p className="text-xs text-muted-foreground">{tx.date}</p>
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
        </div>
      </AnimatedPage>
    </div>
  );
};

export default Wallet;
