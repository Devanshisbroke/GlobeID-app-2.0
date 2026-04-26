import React, { useState } from "react";
import { Search, SlidersHorizontal } from "lucide-react";
import { Surface, Text, Tabs, Input } from "@/components/ui/v2";
import { getIcon } from "@/lib/iconMap";
import { cn } from "@/lib/utils";
import type { WalletTransaction } from "@/store/walletStore";

type TxFilter = "all" | "payment" | "send" | "receive" | "convert";

const filters: { key: TxFilter; label: string }[] = [
  { key: "all", label: "All" },
  { key: "payment", label: "Payments" },
  { key: "send", label: "Sent" },
  { key: "receive", label: "Received" },
  { key: "convert", label: "Converted" },
];

interface TransactionListProps {
  transactions: WalletTransaction[];
}

const TransactionList: React.FC<TransactionListProps> = ({ transactions }) => {
  const [filter, setFilter] = useState<TxFilter>("all");
  const [search, setSearch] = useState("");

  const filtered = transactions.filter((tx) => {
    if (filter !== "all" && tx.type !== filter) return false;
    if (
      search &&
      !tx.description.toLowerCase().includes(search.toLowerCase()) &&
      !tx.merchant?.toLowerCase().includes(search.toLowerCase())
    )
      return false;
    return true;
  });

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between px-1">
        <Text variant="caption-1" tone="tertiary" className="uppercase tracking-widest">
          Transactions
        </Text>
        <SlidersHorizontal className="w-4 h-4 text-ink-tertiary" />
      </div>

      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-ink-tertiary z-10" />
        <Input
          type="text"
          placeholder="Search transactions..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-9"
        />
      </div>

      <Tabs
        value={filter}
        onValueChange={(next) => setFilter(next as TxFilter)}
      >
        <Tabs.List variant="segmented" className="overflow-x-auto hide-scrollbar">
          {filters.map((f) => (
            <Tabs.Trigger key={f.key} value={f.key} className="whitespace-nowrap">
              {f.label}
            </Tabs.Trigger>
          ))}
        </Tabs.List>
      </Tabs>

      <div className="space-y-2">
        {filtered.map((tx) => {
          const TxIcon = getIcon(tx.icon);
          const positive = tx.amount > 0;
          return (
            <Surface
              key={tx.id}
              variant="plain"
              radius="surface"
              className="flex items-center gap-3 py-3 px-3.5 cursor-pointer transition-transform active:scale-[0.99]"
            >
              <div className="w-9 h-9 rounded-p7-input bg-surface-overlay flex items-center justify-center shrink-0">
                <TxIcon className="w-4 h-4 text-ink-secondary" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <Text variant="callout" tone="primary" truncate>
                  {tx.description}
                </Text>
                <Text variant="caption-2" tone="tertiary">
                  {tx.date} {tx.location && `· ${tx.location}`} {tx.countryFlag && tx.countryFlag}
                </Text>
              </div>
              <Text
                variant="callout"
                tone={positive ? "accent" : "primary"}
                className={cn("tabular-nums tracking-tight font-semibold")}
              >
                {positive ? "+" : ""}
                {tx.amount.toLocaleString()} {tx.currency}
              </Text>
            </Surface>
          );
        })}
        {filtered.length === 0 && (
          <Text variant="caption-1" tone="tertiary" align="center" className="py-8">
            No transactions found
          </Text>
        )}
      </div>
    </div>
  );
};

export default TransactionList;
