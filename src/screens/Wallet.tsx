import React, { lazy, Suspense, useMemo, useState } from "react";
import { orderPasses } from "@/lib/passOrdering";
import { useVisibleClock } from "@/hooks/useVisibleClock";
import { motion } from "motion/react";
import {
  ArrowUpRight,
  ArrowDownLeft,
  RefreshCw,
  QrCode,
  TrendingUp,
  FileText,
  ScanLine,
  BarChart3,
} from "lucide-react";
import { Surface, Button, Pill, Tabs, Text, spring } from "@/components/ui/v2";
import { useUserStore } from "@/store/userStore";
import { useWalletStore } from "@/store/walletStore";
import PassStack from "@/components/wallet/PassStack";
import CurrencyCard from "@/components/wallet/CurrencyCard";
import CurrencyConverter from "@/components/wallet/CurrencyConverter";
import TransactionList from "@/components/wallet/TransactionList";
import QRPayment from "@/components/payments/QRPayment";
import QRScanner from "@/components/payments/QRScanner";

/* Phase 6 PR-α — lazy-load SpendingAnalytics so the recharts vendor chunk
   (~524 KB / 152 KB gzipped) only fetches when the user actually opens
   the Analytics tab, not on cold launch. Phase 7 PR-δ preserves this
   boundary verbatim. */
const SpendingAnalytics = lazy(
  () => import("@/components/wallet/SpendingAnalytics"),
);

const AnalyticsFallback: React.FC = () => (
  <div className="flex items-center justify-center min-h-[20dvh]">
    <span
      aria-hidden
      className="w-2 h-2 rounded-full bg-brand/40 animate-pulse"
    />
  </div>
);

type WalletTab = "balance" | "documents" | "analytics";
type ActivePanel = null | "converter" | "qr-pay" | "qr-scan";

/* Country → currency mapping so the active travel destination's
   wallet card sorts to the top. Mirrors locationProfiles in
   locationEngine.ts but kept local to avoid a circular import. */
const countryCurrency: Record<string, string> = {
  Singapore: "SGD",
  Japan: "JPY",
  India: "INR",
  "United States": "USD",
  "United Kingdom": "GBP",
  France: "EUR",
  Germany: "EUR",
  Spain: "EUR",
  Italy: "EUR",
  Netherlands: "EUR",
  UAE: "AED",
  "United Arab Emirates": "AED",
};

/**
 * Wallet — Phase 7 PR-δ.
 *
 * Visual reset against the v2 design system. Functional surface
 * preserved verbatim:
 *  - 3 tabs (Balance / Documents / Analytics) — same state machine,
 *    same lazy-load boundary on Analytics.
 *  - Inline action panels (converter / QR pay / QR scan) — same toggle.
 *  - Same store reads (`useUserStore`, `useWalletStore`).
 *  - Same sub-components for the data-dense surfaces (`DocumentCard`,
 *    `CurrencyCard`, `TransactionList`) — those migrate in their own
 *    follow-up; PR-δ scopes the screen-level chrome only.
 *
 * Visual changes:
 *  - Tab toggle → `Tabs.Root` segmented (shared-layout sliding indicator).
 *  - Total balance card → `Surface variant="elevated"` (replaces
 *    GlassCard `light-sweep` premium glow).
 *  - Action row → `Button variant="primary|secondary"` (replaces 5
 *    different ad-hoc class strings).
 *  - Section headings → `Text variant="caption-1" tone="tertiary"`
 *    (replaces `text-xs uppercase tracking-widest`).
 */
const Wallet: React.FC = () => {
  const { documents } = useUserStore();
  // Re-evaluate auto-pin every minute so a pass that crosses the
  // 24h-to-departure threshold bubbles to the top without a refresh.
  const now = useVisibleClock(60_000);
  const orderedDocuments = useMemo(
    () => orderPasses(documents, now),
    [documents, now],
  );
  const { balances, transactions, defaultCurrency, activeCountry } =
    useWalletStore();
  const [walletTab, setWalletTab] = useState<WalletTab>("balance");
  const [activePanel, setActivePanel] = useState<ActivePanel>(null);

  const totalUSD = balances.reduce((acc, b) => acc + b.amount * b.rate, 0);
  const sortedBalances = React.useMemo(() => {
    const targetCurrency = activeCountry ? countryCurrency[activeCountry] : null;
    if (!targetCurrency) return balances;
    return balances.slice().sort((a, b) => {
      if (a.currency === targetCurrency) return -1;
      if (b.currency === targetCurrency) return 1;
      return 0;
    });
  }, [balances, activeCountry]);

  const handleTabChange = (next: string) => {
    setWalletTab(next as WalletTab);
    setActivePanel(null);
  };

  const togglePanel = (panel: NonNullable<ActivePanel>) => {
    setActivePanel((current) => (current === panel ? null : panel));
  };

  return (
    <div className="px-4 py-6 space-y-5">
      <Tabs value={walletTab} onValueChange={handleTabChange}>
        <Tabs.List variant="segmented" className="w-full">
          <Tabs.Trigger value="balance" className="flex-1">
            <TrendingUp className="w-4 h-4" strokeWidth={1.8} />
            Balance
          </Tabs.Trigger>
          <Tabs.Trigger value="documents" className="flex-1">
            <FileText className="w-4 h-4" strokeWidth={1.8} />
            Documents
          </Tabs.Trigger>
          <Tabs.Trigger value="analytics" className="flex-1">
            <BarChart3 className="w-4 h-4" strokeWidth={1.8} />
            Analytics
          </Tabs.Trigger>
        </Tabs.List>

        {/* Active panel overlay — shared across tabs but mostly used on Balance. */}
        {activePanel ? (
          <motion.div
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring.default}
            className="mt-5"
          >
            {activePanel === "converter" ? (
              <CurrencyConverter onClose={() => setActivePanel(null)} />
            ) : null}
            {activePanel === "qr-pay" ? (
              <QRPayment onClose={() => setActivePanel(null)} />
            ) : null}
            {activePanel === "qr-scan" ? (
              <QRScanner onClose={() => setActivePanel(null)} />
            ) : null}
          </motion.div>
        ) : null}

        <Tabs.Content value="balance" className="mt-5 space-y-5">
          {/* Total balance — elevated hero. */}
          <Surface
            variant="elevated"
            radius="sheet"
            className="px-6 py-7 text-center"
          >
            <span
              aria-hidden
              className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-p7-input bg-brand-soft"
            >
              <TrendingUp className="w-5 h-5 text-brand" strokeWidth={2} />
            </span>
            <Text
              variant="caption-1"
              tone="tertiary"
              className="uppercase tracking-[0.18em]"
            >
              Total Balance
            </Text>
            <Text
              variant="display"
              tone="primary"
              className="mt-1 tabular-nums"
            >
              ${totalUSD.toLocaleString("en-US", {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })}
            </Text>
            <div className="mt-6 flex flex-wrap justify-center gap-2">
              <Button
                variant="primary"
                size="md"
                leading={<ArrowUpRight />}
              >
                Send
              </Button>
              <Button
                variant="secondary"
                size="md"
                leading={<ArrowDownLeft />}
              >
                Receive
              </Button>
              <Button
                variant={activePanel === "qr-pay" ? "subtle" : "secondary"}
                size="md"
                leading={<QrCode />}
                onClick={() => togglePanel("qr-pay")}
              >
                Pay QR
              </Button>
              <Button
                variant={activePanel === "qr-scan" ? "subtle" : "secondary"}
                size="md"
                leading={<ScanLine />}
                onClick={() => togglePanel("qr-scan")}
              >
                Scan
              </Button>
              <Button
                variant={activePanel === "converter" ? "subtle" : "secondary"}
                size="md"
                leading={<RefreshCw />}
                onClick={() => togglePanel("converter")}
              >
                Convert
              </Button>
            </div>
          </Surface>

          {/* Currencies grid. */}
          <section className="space-y-3">
            <div className="flex items-center justify-between px-1">
              <Text
                variant="caption-1"
                tone="tertiary"
                className="uppercase tracking-[0.18em]"
              >
                Currencies
              </Text>
              {activeCountry ? (
                <Pill tone="accent" weight="tinted" dot pulse>
                  Active in {activeCountry}
                </Pill>
              ) : null}
            </div>
            <div className="grid grid-cols-2 gap-2.5">
              {sortedBalances.map((b, i) => (
                <CurrencyCard
                  key={b.currency}
                  balance={b}
                  index={i}
                  defaultCurrency={defaultCurrency}
                />
              ))}
            </div>
          </section>

          {/* Transactions. */}
          <section>
            <TransactionList transactions={transactions} />
          </section>
        </Tabs.Content>

        <Tabs.Content value="documents" className="mt-5 space-y-4">
          <Text
            as="h3"
            variant="caption-1"
            tone="tertiary"
            className="px-1 uppercase tracking-[0.18em]"
          >
            Travel Passes
          </Text>
          <PassStack documents={orderedDocuments} />
          <Text
            variant="caption-2"
            tone="tertiary"
            className="px-1 text-center"
          >
            Tap to expand. Swipe down to flip through passes.
          </Text>
        </Tabs.Content>

        <Tabs.Content value="analytics" className="mt-5">
          <Suspense fallback={<AnalyticsFallback />}>
            <SpendingAnalytics transactions={transactions} />
          </Suspense>
        </Tabs.Content>
      </Tabs>
    </div>
  );
};

export default Wallet;
