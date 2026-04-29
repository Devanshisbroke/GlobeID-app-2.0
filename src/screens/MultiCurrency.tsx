/**
 * Slice-F — multi-currency wallet view.
 *
 * Real portfolio aggregation:
 *  - Fetches the live rates from `/api/v1/exchange/rates` (server-cached
 *    15min, exchangerate.host — keyless).
 *  - Converts every balance into the user's `base` currency.
 *  - Shows the best conversion route to hit a target amount.
 *
 * Pure math lives in `lib/currencyEngine.ts` so this screen is just
 * presentation + side-effects.
 */
import React, { useEffect, useMemo, useState } from "react";
import { ArrowRight, RefreshCw, TrendingUp, Globe2, Loader2 } from "lucide-react";
import { Surface, Button, Pill, Text } from "@/components/ui/v2";
import { useWalletStore } from "@/store/walletStore";
import { api } from "@/lib/apiClient";
import {
  portfolioValue,
  bestConversionRoute,
  type Rates,
} from "@/lib/currencyEngine";

const POPULAR_BASES = ["USD", "EUR", "GBP", "INR", "SGD", "JPY"] as const;

export default function MultiCurrency(): React.ReactElement {
  const balances = useWalletStore((s) => s.balances);
  const [base, setBase] = useState<string>("USD");
  const [rates, setRates] = useState<Rates | null>(null);
  const [asOf, setAsOf] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [targetCurrency, setTargetCurrency] = useState<string>("EUR");
  const [targetAmount, setTargetAmount] = useState<string>("100");

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    api.exchange
      .rates(base)
      .then((res) => {
        if (cancelled) return;
        setRates({ base: res.base, rates: res.rates });
        setAsOf(res.asOf);
      })
      .catch((e) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "Failed to fetch rates");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [base]);

  const portfolio = useMemo(
    () => portfolioValue(balances, base, rates),
    [balances, base, rates],
  );

  const route = useMemo(() => {
    if (!rates) return null;
    const n = Number(targetAmount);
    if (!Number.isFinite(n) || n <= 0) return null;
    return bestConversionRoute(balances, targetCurrency, n, rates);
  }, [balances, rates, targetAmount, targetCurrency]);

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="px-4 pt-6 pb-4">
        <Text variant="title-2" tone="primary">
          Multi-currency
        </Text>
        <Text variant="caption-1" tone="secondary" className="mt-1">
          Portfolio value across {balances.length} wallets
        </Text>
      </div>

      <div className="px-4 space-y-4">
        {/* Base selector */}
        <Surface variant="plain" radius="surface" className="p-4">
          <div className="flex items-center justify-between mb-3">
            <Text variant="body-strong" tone="primary">
              Base currency
            </Text>
            {loading ? (
              <Loader2 className="w-4 h-4 animate-spin text-muted-foreground" />
            ) : (
              <Pill tone="neutral">{asOf ?? "no rates"}</Pill>
            )}
          </div>
          <div className="flex flex-wrap gap-2">
            {POPULAR_BASES.map((b) => (
              <Button
                key={b}
                size="sm"
                variant={base === b ? "default" : "ghost"}
                onClick={() => setBase(b)}
              >
                {b}
              </Button>
            ))}
          </div>
          {error && (
            <div className="mt-3 text-sm text-destructive">
              {error}
            </div>
          )}
        </Surface>

        {/* Portfolio total */}
        <Surface variant="elevated" radius="surface" className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <Globe2 className="w-4 h-4 text-brand" />
            <Text variant="caption-1" tone="secondary">
              Total value in {base}
            </Text>
          </div>
          <div className="flex items-baseline gap-2">
            <Text variant="title-1" tone="primary">
              {portfolio.total.toLocaleString(undefined, {
                maximumFractionDigits: 2,
              })}
            </Text>
            <Text variant="caption-1" tone="secondary">
              {base}
            </Text>
          </div>
          {portfolio.missing.length > 0 && (
            <div className="mt-2 text-xs text-amber-500">
              No rate for: {portfolio.missing.join(", ")}
            </div>
          )}
        </Surface>

        {/* Per-wallet breakdown */}
        <Surface variant="plain" radius="surface" className="p-4">
          <Text variant="body-strong" tone="primary" className="mb-3">
            Breakdown
          </Text>
          <div className="space-y-2">
            {portfolio.byCurrency.map((row) => (
              <div
                key={row.currency}
                className="flex items-center justify-between py-2 border-b border-border/50 last:border-0"
              >
                <div>
                  <Text variant="body-strong" tone="primary">
                    {row.currency}
                  </Text>
                  <Text variant="caption-1" tone="secondary">
                    {row.amount.toLocaleString(undefined, {
                      maximumFractionDigits: 2,
                    })}{" "}
                    {row.currency}
                  </Text>
                </div>
                <Text variant="body-strong" tone="primary">
                  {row.inBase !== null
                    ? `${row.inBase.toLocaleString(undefined, {
                        maximumFractionDigits: 2,
                      })} ${base}`
                    : "—"}
                </Text>
              </div>
            ))}
            {portfolio.byCurrency.length === 0 && (
              <Text variant="caption-1" tone="secondary">
                No balances loaded.
              </Text>
            )}
          </div>
        </Surface>

        {/* Best conversion route */}
        <Surface variant="plain" radius="surface" className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp className="w-4 h-4 text-brand" />
            <Text variant="body-strong" tone="primary">
              Best conversion route
            </Text>
          </div>
          <div className="flex items-center gap-2 mb-3">
            <input
              type="number"
              min={0}
              value={targetAmount}
              onChange={(e) => setTargetAmount(e.target.value)}
              className="w-24 rounded-md border border-border/50 bg-transparent px-2 py-1.5 text-sm"
            />
            <select
              value={targetCurrency}
              onChange={(e) => setTargetCurrency(e.target.value)}
              className="rounded-md border border-border/50 bg-transparent px-2 py-1.5 text-sm"
            >
              {balances
                .map((b) => b.currency)
                .concat(["USD", "EUR", "GBP"])
                .filter((v, i, a) => a.indexOf(v) === i)
                .map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
            </select>
          </div>
          {route ? (
            <div className="flex items-center gap-2">
              <Pill tone="neutral">
                {route.sourceAmount.toLocaleString(undefined, {
                  maximumFractionDigits: 2,
                })}{" "}
                {route.from}
              </Pill>
              <ArrowRight className="w-4 h-4 text-muted-foreground" />
              <Pill tone="neutral">
                {route.outputAmount.toLocaleString(undefined, {
                  maximumFractionDigits: 2,
                })}{" "}
                {targetCurrency}
              </Pill>
              <Text
                variant="caption-1"
                tone="secondary"
                className="ml-auto"
              >
                rate {route.rate.toFixed(4)}
              </Text>
            </div>
          ) : (
            <Text variant="caption-1" tone="secondary">
              {rates
                ? "No balance can cover that target amount."
                : "Waiting for rates…"}
            </Text>
          )}
        </Surface>

        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            setRates(null);
            setAsOf(null);
            // Trigger effect to re-fetch.
            setBase((b) => b);
          }}
        >
          <RefreshCw className="w-3 h-3 mr-1" />
          Refresh rates
        </Button>
      </div>
    </div>
  );
}
