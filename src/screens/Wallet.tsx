import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useUserStore } from "@/store/userStore";
import { demoBalances, demoTransactions } from "@/lib/demoData";
import { demoPaymentNetworks } from "@/lib/demoServices";
import { getIcon } from "@/lib/iconMap";
import { staggerDelay } from "@/hooks/useMotion";
import { ArrowUpRight, ArrowDownLeft, RefreshCw, Search, SlidersHorizontal, QrCode, TrendingUp, Zap, ChevronDown, Check, FileText } from "lucide-react";
import { cn } from "@/lib/utils";
import DocumentCard from "@/components/wallet/DocumentCard";

type TxFilter = "all" | "send" | "receive" | "payment" | "convert";
type WalletTab = "balance" | "documents";

const currencyGradients = ["bg-gradient-sunset", "bg-gradient-ocean", "bg-gradient-aurora", "bg-gradient-forest", "bg-gradient-cosmic", "bg-gradient-blue"];

const Wallet: React.FC = () => {
  const { documents } = useUserStore();
  const [filter, setFilter] = useState<TxFilter>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [showNetworks, setShowNetworks] = useState(false);
  const [walletTab, setWalletTab] = useState<WalletTab>("balance");

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
    <div className="px-4 py-6 space-y-5">
      {/* Tab toggle */}
      <AnimatedPage>
        <div className="flex gap-1.5 p-1 rounded-2xl glass border border-border/40">
          <button onClick={() => setWalletTab("balance")} className={cn(
            "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-semibold transition-all min-h-[44px]",
            walletTab === "balance" ? "bg-gradient-ocean text-primary-foreground shadow-depth-sm" : "text-muted-foreground"
          )}>
            <TrendingUp className="w-3.5 h-3.5" strokeWidth={1.8} />Balance
          </button>
          <button onClick={() => setWalletTab("documents")} className={cn(
            "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-semibold transition-all min-h-[44px]",
            walletTab === "documents" ? "bg-gradient-cosmic text-primary-foreground shadow-depth-sm" : "text-muted-foreground"
          )}>
            <FileText className="w-3.5 h-3.5" strokeWidth={1.8} />Documents
          </button>
        </div>
      </AnimatedPage>

      {walletTab === "documents" ? (
        <div className="space-y-3">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Travel Documents</h3>
          {documents.map((doc, i) => (
            <AnimatedPage key={doc.id} staggerIndex={i}>
              <DocumentCard doc={doc} />
            </AnimatedPage>
          ))}
        </div>
      ) : (
        <>
          {/* Total Balance */}
          <AnimatedPage>
            <GlassCard className="text-center py-8 relative overflow-hidden light-sweep" variant="premium" glow depth="lg">
              <div className="absolute inset-0 bg-gradient-to-br from-primary/6 via-transparent to-accent/4 pointer-events-none" />
              <div className="relative">
                <div className="w-14 h-14 rounded-2xl bg-gradient-cosmic flex items-center justify-center mx-auto mb-4 shadow-glow-md">
                  <TrendingUp className="w-7 h-7 text-primary-foreground" />
                </div>
                <p className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 font-medium">Total Balance</p>
                <p className="text-4xl font-bold text-foreground tabular-nums tracking-tight">
                  ${totalUSD.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </p>
                <div className="flex gap-2 justify-center mt-6 flex-wrap">
                  {[
                    { icon: ArrowUpRight, label: "Send", accent: true },
                    { icon: ArrowDownLeft, label: "Receive" },
                    { icon: QrCode, label: "Scan" },
                    { icon: RefreshCw, label: "Convert" },
                  ].map((btn) => {
                    const Icon = btn.icon;
                    return (
                      <button key={btn.label} className={cn(
                        "flex items-center gap-1.5 px-5 py-2.5 rounded-xl text-xs font-semibold active:scale-95 transition-all min-h-[44px] btn-ripple touch-bounce",
                        btn.accent ? "bg-gradient-ocean text-primary-foreground shadow-glow-md" : "glass border border-border/40 text-foreground hover:border-primary/30 hover:shadow-glow-sm"
                      )}>
                        <Icon className="w-4 h-4" strokeWidth={1.8} />{btn.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            </GlassCard>
          </AnimatedPage>

          {/* Currency Cards */}
          <AnimatedPage staggerIndex={1}>
            <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Currencies</h3>
            <div className="grid grid-cols-2 gap-2.5">
              {demoBalances.map((b, i) => (
                <GlassCard key={b.currency} className="animate-fade-in cursor-pointer relative overflow-hidden touch-bounce" style={{ animationDelay: staggerDelay(i, 60) }}>
                  <div className={cn("absolute top-0 right-0 w-20 h-20 rounded-full blur-3xl opacity-15", currencyGradients[i % currencyGradients.length])} />
                  <div className="relative">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-base w-7 h-7 rounded-lg bg-secondary/40 flex items-center justify-center border border-border/20">{b.flag}</span>
                      <span className="text-xs font-semibold text-muted-foreground tracking-wide">{b.currency}</span>
                    </div>
                    <p className="text-lg font-bold text-foreground tabular-nums tracking-tight">{b.symbol}{b.amount.toLocaleString()}</p>
                  </div>
                </GlassCard>
              ))}
            </div>
          </AnimatedPage>

          {/* Payment Networks */}
          <AnimatedPage staggerIndex={2}>
            <button onClick={() => setShowNetworks(!showNetworks)} className="flex items-center justify-between w-full mb-3 px-1">
              <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest flex items-center gap-1.5">
                <Zap className="w-3.5 h-3.5 text-neon-amber" /> Payment Networks
              </h3>
              <ChevronDown className={cn("w-4 h-4 text-muted-foreground transition-transform duration-[var(--motion-small)]", showNetworks && "rotate-180")} />
            </button>
            {showNetworks && (
              <div className="grid grid-cols-2 gap-2 animate-fade-in">
                {demoPaymentNetworks.map((n, i) => {
                  const NIcon = getIcon(n.icon);
                  return (
                    <GlassCard key={n.id} className="flex items-center gap-2.5 py-3 animate-fade-in" style={{ animationDelay: staggerDelay(i, 40) }}>
                      <div className="w-8 h-8 rounded-lg bg-secondary/60 flex items-center justify-center border border-border/20">
                        <NIcon className="w-4 h-4 text-muted-foreground" strokeWidth={1.8} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium text-foreground truncate">{n.name}</p>
                        <p className="text-[10px] text-muted-foreground">{n.region}</p>
                      </div>
                      {n.connected ? (
                        <span className="text-[10px] w-6 h-6 rounded-full bg-accent/15 flex items-center justify-center">
                          <Check className="w-3 h-3 text-accent" />
                        </span>
                      ) : (
                        <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-secondary text-muted-foreground">Add</span>
                      )}
                    </GlassCard>
                  );
                })}
              </div>
            )}
          </AnimatedPage>

          {/* Transactions */}
          <AnimatedPage staggerIndex={3}>
            <div className="flex items-center justify-between mb-3 px-1">
              <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Transactions</h3>
              <SlidersHorizontal className="w-4 h-4 text-muted-foreground" />
            </div>
            <div className="relative mb-3">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <input type="text" placeholder="Search transactions..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border/40 text-xs text-foreground bg-transparent focus:border-primary/50 focus:shadow-glow-sm outline-none min-h-[44px] transition-all" />
            </div>
            <div className="flex gap-1.5 mb-3 overflow-x-auto hide-scrollbar">
              {filters.map((f) => (
                <button key={f.key} onClick={() => setFilter(f.key)} className={cn(
                  "px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all min-h-[32px]",
                  filter === f.key ? "bg-primary text-primary-foreground shadow-glow-sm" : "glass text-muted-foreground hover:text-foreground"
                )}>{f.label}</button>
              ))}
            </div>
            <div className="space-y-2">
              {filteredTx.map((tx, i) => {
                const TxIcon = getIcon(tx.icon);
                return (
                  <GlassCard key={tx.id} className="flex items-center gap-3 py-3 px-4 animate-fade-in cursor-pointer" style={{ animationDelay: staggerDelay(i, 40) }}>
                    <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                      <TxIcon className="w-4 h-4 text-muted-foreground" strokeWidth={1.8} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-foreground truncate">{tx.description}</p>
                      <p className="text-xs text-muted-foreground">{tx.date} · {tx.category}</p>
                    </div>
                    <p className={cn("text-sm font-bold tabular-nums tracking-tight", tx.amount > 0 ? "text-accent" : "text-foreground")}>
                      {tx.amount > 0 ? "+" : ""}{tx.amount.toLocaleString()} {tx.currency}
                    </p>
                  </GlassCard>
                );
              })}
              {filteredTx.length === 0 && <p className="text-xs text-muted-foreground text-center py-8">No transactions found</p>}
            </div>
          </AnimatedPage>
        </>
      )}
    </div>
  );
};

export default Wallet;
