import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { getIcon } from "@/lib/iconMap";
import { cn } from "@/lib/utils";
import { Search, SlidersHorizontal } from "lucide-react";
import { staggerDelay } from "@/hooks/useMotion";
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
    if (search && !tx.description.toLowerCase().includes(search.toLowerCase()) && !tx.merchant?.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between px-1">
        <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Transactions</h3>
        <SlidersHorizontal className="w-4 h-4 text-muted-foreground" />
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          type="text"
          placeholder="Search transactions..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border/40 text-xs text-foreground bg-transparent focus:border-primary/50 focus:shadow-glow-sm outline-none min-h-[44px] transition-all"
        />
      </div>

      <div className="flex gap-1.5 overflow-x-auto hide-scrollbar">
        {filters.map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            className={cn(
              "px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all min-h-[32px]",
              filter === f.key ? "bg-primary text-primary-foreground shadow-glow-sm" : "glass text-muted-foreground hover:text-foreground"
            )}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="space-y-2">
        {filtered.map((tx, i) => {
          const TxIcon = getIcon(tx.icon);
          return (
            <GlassCard key={tx.id} className="flex items-center gap-3 py-3 px-4 animate-fade-in cursor-pointer" style={{ animationDelay: staggerDelay(i, 40) }}>
              <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                <TxIcon className="w-4 h-4 text-muted-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{tx.description}</p>
                <p className="text-xs text-muted-foreground">
                  {tx.date} {tx.location && `· ${tx.location}`} {tx.countryFlag && tx.countryFlag}
                </p>
              </div>
              <p className={cn("text-sm font-bold tabular-nums tracking-tight", tx.amount > 0 ? "text-accent" : "text-foreground")}>
                {tx.amount > 0 ? "+" : ""}{tx.amount.toLocaleString()} {tx.currency}
              </p>
            </GlassCard>
          );
        })}
        {filtered.length === 0 && <p className="text-xs text-muted-foreground text-center py-8">No transactions found</p>}
      </div>
    </div>
  );
};

export default TransactionList;
