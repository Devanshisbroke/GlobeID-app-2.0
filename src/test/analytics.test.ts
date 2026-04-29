import { describe, it, expect } from "vitest";
import { dailyBurn, spendByCategory, topMerchants, travelSplit } from "@/lib/analytics";
import type { WalletTransaction } from "@shared/types/wallet";

const tx = (over: Partial<WalletTransaction>): WalletTransaction => ({
  id: "t1",
  type: "payment",
  description: "test",
  amount: -10,
  currency: "USD",
  date: "2025-01-15",
  category: "food",
  icon: "🍜",
  ...over,
});

describe("spendByCategory", () => {
  it("sums debits per category and sorts descending", () => {
    const txs = [
      tx({ id: "a", amount: -20, category: "food" }),
      tx({ id: "b", amount: -50, category: "hotel" }),
      tx({ id: "c", amount: -5, category: "food" }),
      tx({ id: "d", amount: 100, category: "food" }), // credit ignored
    ];
    expect(spendByCategory(txs)).toEqual([
      { category: "hotel", spend: 50 },
      { category: "food", spend: 25 },
    ]);
  });

  it("returns empty for no spend", () => {
    expect(spendByCategory([])).toEqual([]);
  });
});

describe("dailyBurn", () => {
  it("buckets debits into the requested window", () => {
    const now = new Date("2025-01-31T12:00:00Z");
    const txs = [
      tx({ id: "a", amount: -10, date: "2025-01-30" }),
      tx({ id: "b", amount: -5, date: "2025-01-30" }),
      tx({ id: "c", amount: -20, date: "2025-01-15" }),
      tx({ id: "d", amount: -99, date: "2024-12-31" }), // out of window
    ];
    const r = dailyBurn(txs, { now, days: 30 });
    expect(r).toHaveLength(30);
    expect(r[r.length - 1]).toEqual({ date: "2025-01-31", total: 0 });
    expect(r[r.length - 2]).toEqual({ date: "2025-01-30", total: 15 });
    const fifteen = r.find((d) => d.date === "2025-01-15");
    expect(fifteen).toEqual({ date: "2025-01-15", total: 20 });
  });
});

describe("travelSplit", () => {
  it("splits into travel vs non-travel", () => {
    const txs = [
      tx({ amount: -100, category: "flight" }),
      tx({ amount: -50, category: "hotel" }),
      tx({ amount: -20, category: "transport" }),
      tx({ amount: -30, category: "food" }),
      tx({ amount: -10, category: "shopping" }),
    ];
    expect(travelSplit(txs)).toEqual({ travel: 170, nonTravel: 40, total: 210 });
  });

  it("is zero for empty input", () => {
    expect(travelSplit([])).toEqual({ travel: 0, nonTravel: 0, total: 0 });
  });
});

describe("topMerchants", () => {
  it("aggregates by merchant and returns top N", () => {
    const txs = [
      tx({ id: "a", amount: -10, merchant: "Starbucks" }),
      tx({ id: "b", amount: -15, merchant: "Starbucks" }),
      tx({ id: "c", amount: -50, merchant: "Hilton" }),
      tx({ id: "d", amount: -5, merchant: "7-11" }),
    ];
    const r = topMerchants(txs, 2);
    expect(r).toEqual([
      { merchant: "Hilton", count: 1, spend: 50 },
      { merchant: "Starbucks", count: 2, spend: 25 },
    ]);
  });
});
