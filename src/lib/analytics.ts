/**
 * Slice-C — pure analytics helpers.
 *
 * Everything is a pure function of the caller-supplied transaction
 * array + a `now` timestamp. No IO, no hidden clock — trivially testable.
 */
import type { WalletTransaction, TxCategory } from "@shared/types/wallet";

/** Sum debits per category (absolute values). */
export function spendByCategory(
  txs: WalletTransaction[],
): Array<{ category: TxCategory; spend: number }> {
  const buckets = new Map<TxCategory, number>();
  for (const tx of txs) {
    if (tx.amount >= 0) continue; // skip credits
    const amt = Math.abs(tx.amount);
    buckets.set(tx.category, (buckets.get(tx.category) ?? 0) + amt);
  }
  return [...buckets.entries()]
    .map(([category, spend]) => ({ category, spend }))
    .sort((a, b) => b.spend - a.spend);
}

/**
 * Daily debit total for the last `days` days, anchored at `now`.
 * Returns one entry per day, oldest first.
 */
export function dailyBurn(
  txs: WalletTransaction[],
  opts: { now: Date; days: number },
): Array<{ date: string; total: number }> {
  const days = opts.days;
  const end = new Date(opts.now);
  end.setUTCHours(0, 0, 0, 0);

  const result: Array<{ date: string; total: number }> = [];
  const dayIndex = new Map<string, number>();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(end);
    d.setUTCDate(d.getUTCDate() - i);
    const key = d.toISOString().slice(0, 10);
    dayIndex.set(key, result.length);
    result.push({ date: key, total: 0 });
  }
  for (const tx of txs) {
    if (tx.amount >= 0) continue;
    const idx = dayIndex.get(tx.date);
    if (idx === undefined) continue;
    result[idx]!.total += Math.abs(tx.amount);
  }
  return result;
}

/**
 * Split transactions into travel-related vs. non-travel spend.
 * Travel = flight | hotel | transport.
 */
export function travelSplit(txs: WalletTransaction[]): {
  travel: number;
  nonTravel: number;
  total: number;
} {
  const TRAVEL: TxCategory[] = ["flight", "hotel", "transport"];
  let travel = 0;
  let nonTravel = 0;
  for (const tx of txs) {
    if (tx.amount >= 0) continue;
    const amt = Math.abs(tx.amount);
    if (TRAVEL.includes(tx.category)) travel += amt;
    else nonTravel += amt;
  }
  return { travel, nonTravel, total: travel + nonTravel };
}

/**
 * Slice-F — filter a transaction list to a date window (inclusive).
 * `from`/`to` are `YYYY-MM-DD` strings (same shape as `tx.date`).
 */
export function filterByDateRange(
  txs: WalletTransaction[],
  from: string,
  to: string,
): WalletTransaction[] {
  return txs.filter((tx) => tx.date >= from && tx.date <= to);
}

/**
 * Slice-F — week-of-day × category heatmap data.
 *
 * Rows = 7 days of week (Mon..Sun), columns = one entry per category.
 * Used to drive the visx heatmap in Analytics 2.0.
 */
export interface HeatmapCell {
  day: number; // 0..6 (Mon..Sun)
  category: TxCategory;
  spend: number;
}

export function spendHeatmap(
  txs: WalletTransaction[],
): HeatmapCell[] {
  const cells = new Map<string, HeatmapCell>();
  for (const tx of txs) {
    if (tx.amount >= 0) continue;
    // Parse YYYY-MM-DD → day of week (Mon=0..Sun=6).
    const [y, m, d] = tx.date.split("-").map(Number);
    if (!y || !m || !d) continue;
    const dayJs = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
    // JS: Sun=0..Sat=6 → map to Mon=0..Sun=6.
    const day = (dayJs + 6) % 7;
    const key = `${day}_${tx.category}`;
    const prev = cells.get(key);
    if (prev) {
      prev.spend += Math.abs(tx.amount);
    } else {
      cells.set(key, { day, category: tx.category, spend: Math.abs(tx.amount) });
    }
  }
  return [...cells.values()];
}

/** Count of transactions per merchant, top-N. */
export function topMerchants(
  txs: WalletTransaction[],
  n: number,
): Array<{ merchant: string; count: number; spend: number }> {
  const m = new Map<string, { count: number; spend: number }>();
  for (const tx of txs) {
    if (tx.amount >= 0) continue;
    const key = tx.merchant ?? tx.description;
    const prev = m.get(key) ?? { count: 0, spend: 0 };
    prev.count += 1;
    prev.spend += Math.abs(tx.amount);
    m.set(key, prev);
  }
  return [...m.entries()]
    .map(([merchant, v]) => ({ merchant, ...v }))
    .sort((a, b) => b.spend - a.spend)
    .slice(0, n);
}
