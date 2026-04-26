import React from "react";
import { Surface, Pill, Text } from "@/components/ui/v2";
import { cn } from "@/lib/utils";
import type { WalletBalance } from "@/store/walletStore";
import { useInsightsStore } from "@/store/insightsStore";

interface CurrencyCardProps {
  balance: WalletBalance;
  index: number;
  defaultCurrency: string;
  onClick?: () => void;
}

const CurrencyCard: React.FC<CurrencyCardProps> = ({
  balance,
  index: _index,
  defaultCurrency,
  onClick,
}) => {
  const usdValue = balance.amount * balance.rate;
  const isDefault = balance.currency === defaultCurrency;
  const walletInsight = useInsightsStore((s) => s.wallet);
  const insight = walletInsight?.byCurrency.find((c) => c.currency === balance.currency);
  const isActive = insight?.isActive === true;
  const isInactive = insight?.isInactive === true;

  return (
    <Surface
      variant="elevated"
      radius="surface"
      onClick={onClick}
      className={cn(
        "p-3.5 cursor-pointer relative overflow-hidden transition-transform active:scale-[0.99]",
        isDefault && "ring-1 ring-brand/30",
        isActive && !isDefault && "ring-1 ring-state-accent/40",
      )}
    >
      <div className="flex items-center gap-2 mb-2">
        <span className="text-base w-7 h-7 rounded-p7-input bg-surface-overlay flex items-center justify-center border border-surface-hairline">
          {balance.flag}
        </span>
        <Text variant="caption-1" tone="secondary" className="font-semibold tracking-wide">
          {balance.currency}
        </Text>
        <span className="ml-auto">
          {isDefault && (
            <Pill tone="brand" weight="tinted">
              Default
            </Pill>
          )}
          {!isDefault && isActive && (
            <Pill tone="accent" weight="tinted">
              Active trip
            </Pill>
          )}
          {!isDefault && !isActive && isInactive && (
            <Pill
              tone="neutral"
              weight="tinted"
              title={insight?.reason ?? "No upcoming trip uses this currency"}
            >
              Idle
            </Pill>
          )}
        </span>
      </div>
      <Text variant="title-3" tone="primary" className="tabular-nums tracking-tight">
        {balance.symbol}
        {balance.amount.toLocaleString(undefined, {
          minimumFractionDigits: balance.currency === "JPY" ? 0 : 2,
          maximumFractionDigits: balance.currency === "JPY" ? 0 : 2,
        })}
      </Text>
      {balance.currency !== "USD" && (
        <Text variant="caption-2" tone="tertiary" className="mt-0.5">
          ≈ $
          {usdValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}{" "}
          USD
        </Text>
      )}
    </Surface>
  );
};

export default CurrencyCard;
