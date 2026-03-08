import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useUserStore } from "@/store/userStore";
import { useWalletStore } from "@/store/walletStore";
import { staggerDelay } from "@/hooks/useMotion";
import { ArrowUpRight, ArrowDownLeft, RefreshCw, QrCode, TrendingUp, FileText, ScanLine, BarChart3, ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import DocumentCard from "@/components/wallet/DocumentCard";
import CurrencyCard from "@/components/wallet/CurrencyCard";
import CurrencyConverter from "@/components/wallet/CurrencyConverter";
import TransactionList from "@/components/wallet/TransactionList";
import SpendingAnalytics from "@/components/wallet/SpendingAnalytics";
import QRPayment from "@/components/payments/QRPayment";
import QRScanner from "@/components/payments/QRScanner";

type WalletTab = "balance" | "documents" | "analytics";
type ActivePanel = null | "converter" | "qr-pay" | "qr-scan";

const Wallet: React.FC = () => {
  const { documents } = useUserStore();
  const { balances, transactions, defaultCurrency } = useWalletStore();
  const [walletTab, setWalletTab] = useState<WalletTab>("balance");
  const [activePanel, setActivePanel] = useState<ActivePanel>(null);

  const totalUSD = balances.reduce((acc, b) => acc + b.amount * b.rate, 0);

  const tabs: { key: WalletTab; label: string; icon: React.ElementType }[] = [
    { key: "balance", label: "Balance", icon: TrendingUp },
    { key: "documents", label: "Documents", icon: FileText },
    { key: "analytics", label: "Analytics", icon: BarChart3 },
  ];

  return (
    <div className="px-4 py-6 space-y-5">
      {/* Tab toggle */}
      <AnimatedPage>
        <div className="flex gap-1 p-1 rounded-2xl glass border border-border/40">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button key={tab.key} onClick={() => { setWalletTab(tab.key); setActivePanel(null); }} className={cn(
                "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-semibold transition-all min-h-[44px]",
                walletTab === tab.key ? "bg-gradient-ocean text-primary-foreground shadow-depth-sm" : "text-muted-foreground"
              )}>
                <Icon className="w-3.5 h-3.5" strokeWidth={1.8} />{tab.label}
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {/* Panels overlay */}
      {activePanel && (
        <AnimatedPage>
          {activePanel === "converter" && <CurrencyConverter onClose={() => setActivePanel(null)} />}
          {activePanel === "qr-pay" && <QRPayment onClose={() => setActivePanel(null)} />}
          {activePanel === "qr-scan" && <QRScanner onClose={() => setActivePanel(null)} />}
        </AnimatedPage>
      )}

      {walletTab === "documents" ? (
        <div className="space-y-3">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Travel Documents</h3>
          {documents.map((doc, i) => (
            <AnimatedPage key={doc.id} staggerIndex={i}>
              <DocumentCard doc={doc} />
            </AnimatedPage>
          ))}
        </div>
      ) : walletTab === "analytics" ? (
        <AnimatedPage>
          <SpendingAnalytics transactions={transactions} />
        </AnimatedPage>
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
                    { icon: QrCode, label: "Pay QR", panel: "qr-pay" as ActivePanel },
                    { icon: ScanLine, label: "Scan", panel: "qr-scan" as ActivePanel },
                    { icon: RefreshCw, label: "Convert", panel: "converter" as ActivePanel },
                  ].map((btn) => {
                    const Icon = btn.icon;
                    return (
                      <button
                        key={btn.label}
                        onClick={() => btn.panel && setActivePanel(activePanel === btn.panel ? null : btn.panel)}
                        className={cn(
                          "flex items-center gap-1.5 px-4 py-2.5 rounded-xl text-xs font-semibold active:scale-95 transition-all min-h-[44px] btn-ripple touch-bounce",
                          btn.accent
                            ? "bg-gradient-ocean text-primary-foreground shadow-glow-md"
                            : activePanel === btn.panel
                              ? "bg-primary/15 text-primary border border-primary/30"
                              : "glass border border-border/40 text-foreground hover:border-primary/30 hover:shadow-glow-sm"
                        )}
                      >
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
              {balances.map((b, i) => (
                <CurrencyCard key={b.currency} balance={b} index={i} defaultCurrency={defaultCurrency} />
              ))}
            </div>
          </AnimatedPage>

          {/* Transactions */}
          <AnimatedPage staggerIndex={2}>
            <TransactionList transactions={transactions} />
          </AnimatedPage>
        </>
      )}
    </div>
  );
};

export default Wallet;
