/**
 * Slice-F — multi-currency conversion engine.
 *
 * Sits on top of the existing server `/api/v1/exchange/*` endpoints
 * (Slice-B, exchangerate.host, 15-min TTL cache).
 *
 * Provides:
 *  - `convertAmount(from, to, amount, rates)` — pure math.
 *  - `portfolioValue(balances, base, rates)` — total net worth across
 *    all wallet currencies expressed in `base`. Pure function so the UI
 *    just memoises it.
 *  - `bestConversionRoute(balances, targetCurrency, targetAmount, rates)`
 *    — picks the source balance with the lowest conversion cost given
 *    current rates + user's holdings. Deterministic; no randomness.
 */
import type { WalletBalance } from "@shared/types/wallet";

export interface Rates {
  base: string;
  rates: Record<string, number>;
}

/** Convert `amount` in `from` to `to` given a `base`-denominated rates table. */
export function convertAmount(
  from: string,
  to: string,
  amount: number,
  rates: Rates,
): number | null {
  if (from === to) return amount;
  const { base, rates: r } = rates;
  // If the table isn't based at `from` we need to triangulate.
  // amount_in_base = amount / rate(base→from)
  // amount_in_to   = amount_in_base * rate(base→to)
  const rFrom = base === from ? 1 : r[from];
  const rTo = base === to ? 1 : r[to];
  if (typeof rFrom !== "number" || typeof rTo !== "number") return null;
  const inBase = amount / rFrom;
  return inBase * rTo;
}

export interface PortfolioSnapshot {
  base: string;
  total: number;
  missing: string[];
  byCurrency: Array<{ currency: string; amount: number; inBase: number | null }>;
}

/** Sum all balances expressed in `base`. Returns which currencies had no rate. */
export function portfolioValue(
  balances: WalletBalance[],
  base: string,
  rates: Rates | null,
): PortfolioSnapshot {
  const byCurrency = balances.map((b) => {
    if (!rates) return { currency: b.currency, amount: b.amount, inBase: null };
    const converted = convertAmount(b.currency, base, b.amount, rates);
    return { currency: b.currency, amount: b.amount, inBase: converted };
  });
  const total = byCurrency.reduce((acc, r) => acc + (r.inBase ?? 0), 0);
  // Any currency whose base-denominated value is null is "missing" — either
  // the rates table isn't loaded at all, or it doesn't contain that pair.
  const missing = byCurrency.filter((r) => r.inBase === null).map((r) => r.currency);
  return { base, total, missing, byCurrency };
}

export interface ConversionRoute {
  from: string;
  sourceAmount: number;
  rate: number;
  outputAmount: number;
  /** Cost expressed as fractional difference vs. the ideal. */
  cost: number;
}

/**
 * Given a user's holdings and a target amount in `targetCurrency`, find
 * the cheapest source currency to convert from that still has enough
 * balance. Cost is zero for a like-for-like conversion, otherwise the
 * fractional deviation from the straight "amount × rate" path.
 */
export function bestConversionRoute(
  balances: WalletBalance[],
  targetCurrency: string,
  targetAmount: number,
  rates: Rates,
): ConversionRoute | null {
  const candidates: ConversionRoute[] = [];
  for (const b of balances) {
    if (b.amount <= 0) continue;
    if (b.currency === targetCurrency) {
      if (b.amount < targetAmount) continue;
      candidates.push({
        from: b.currency,
        sourceAmount: targetAmount,
        rate: 1,
        outputAmount: targetAmount,
        cost: 0,
      });
      continue;
    }
    const rateFromToTarget = convertAmount(b.currency, targetCurrency, 1, rates);
    if (rateFromToTarget === null || rateFromToTarget <= 0) continue;
    const sourceNeeded = targetAmount / rateFromToTarget;
    if (sourceNeeded > b.amount) continue;
    const ideal = sourceNeeded * rateFromToTarget;
    const cost = Math.abs(ideal - targetAmount) / targetAmount;
    candidates.push({
      from: b.currency,
      sourceAmount: sourceNeeded,
      rate: rateFromToTarget,
      outputAmount: targetAmount,
      cost,
    });
  }
  if (candidates.length === 0) return null;
  // Sort primarily by cost. Tie-break: direct same-currency routes win
  // over cross-rate routes so we never spend extra conversions when the
  // user already holds the target currency.
  candidates.sort((a, b) => {
    const delta = a.cost - b.cost;
    if (Math.abs(delta) > 1e-9) return delta;
    const aDirect = a.from === targetCurrency ? 0 : 1;
    const bDirect = b.from === targetCurrency ? 0 : 1;
    return aDirect - bDirect;
  });
  return candidates[0] ?? null;
}
