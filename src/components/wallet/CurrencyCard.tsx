import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { cn } from "@/lib/utils";
import type { WalletBalance } from "@/store/walletStore";
import { useInsightsStore } from "@/store/insightsStore";

const gradients = [
  "bg-gradient-ocean",
  "bg-gradient-sunset",
  "bg-gradient-aurora",
  "bg-gradient-forest",
  "bg-gradient-cosmic",
  "bg-gradient-blue",
];

interface CurrencyCardProps {
  balance: WalletBalance;
  index: number;
  defaultCurrency: string;
  onClick?: () => void;
}

const CurrencyCard: React.FC<CurrencyCardProps> = ({ balance, index, defaultCurrency, onClick }) => {
  const usdValue = balance.amount * balance.rate;
  const isDefault = balance.currency === defaultCurrency;
  const walletInsight = useInsightsStore((s) => s.wallet);
  const insight = walletInsight?.byCurrency.find((c) => c.currency === balance.currency);
  const isActive = insight?.isActive === true;
  const isInactive = insight?.isInactive === true;

  return (
    <GlassCard
      className={cn(
        "cursor-pointer touch-bounce relative overflow-hidden",
        isDefault && "ring-1 ring-primary/30",
        isActive && !isDefault && "ring-1 ring-accent/40"
      )}
      depth="md"
      onClick={onClick}
    >
      <div className={cn("absolute top-0 right-0 w-20 h-20 rounded-full blur-3xl opacity-15", gradients[index % gradients.length])} />
      <div className="relative">
        <div className="flex items-center gap-2 mb-2">
          <span className="text-base w-7 h-7 rounded-lg bg-secondary/40 flex items-center justify-center border border-border/20">
            {balance.flag}
          </span>
          <span className="text-xs font-semibold text-muted-foreground tracking-wide">{balance.currency}</span>
          {isDefault && (
            <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-primary/15 text-primary font-semibold ml-auto">
              Default
            </span>
          )}
          {!isDefault && isActive && (
            <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-accent/15 text-accent font-semibold ml-auto">
              Active trip
            </span>
          )}
          {!isDefault && !isActive && isInactive && (
            <span
              className="text-[9px] px-1.5 py-0.5 rounded-full bg-muted/40 text-muted-foreground font-semibold ml-auto"
              title={insight?.reason ?? "No upcoming trip uses this currency"}
            >
              Idle
            </span>
          )}
        </div>
        <p className="text-lg font-bold text-foreground tabular-nums tracking-tight">
          {balance.symbol}{balance.amount.toLocaleString(undefined, { minimumFractionDigits: balance.currency === "JPY" ? 0 : 2, maximumFractionDigits: balance.currency === "JPY" ? 0 : 2 })}
        </p>
        {balance.currency !== "USD" && (
          <p className="text-[10px] text-muted-foreground mt-0.5">
            ≈ ${usdValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} USD
          </p>
        )}
      </div>
    </GlassCard>
  );
};

export default CurrencyCard;
