import { describe, it, expect } from "vitest";
import { filterByDateRange, spendHeatmap } from "@/lib/analytics";
import type { WalletTransaction } from "@shared/types/wallet";

const tx = (over: Partial<WalletTransaction>): WalletTransaction => ({
  id: "t1",
  type: "payment",
  description: "test",
  amount: -10,
  currency: "USD",
  date: "2025-01-15",
  category: "food",
  icon: "utensils",
  ...over,
});

describe("filterByDateRange", () => {
  const txs = [
    tx({ id: "a", date: "2025-01-01" }),
    tx({ id: "b", date: "2025-01-15" }),
    tx({ id: "c", date: "2025-02-01" }),
  ];

  it("includes the boundary dates", () => {
    const out = filterByDateRange(txs, "2025-01-01", "2025-02-01");
    expect(out.map((t) => t.id)).toEqual(["a", "b", "c"]);
  });

  it("excludes outside-range dates", () => {
    const out = filterByDateRange(txs, "2025-01-10", "2025-01-31");
    expect(out.map((t) => t.id)).toEqual(["b"]);
  });
});

describe("spendHeatmap", () => {
  it("buckets spend by weekday × category and ignores credits", () => {
    // 2025-01-13 is a Monday (UTC). Map: Mon=0.
    const txs = [
      tx({ id: "a", date: "2025-01-13", amount: -20, category: "food" }),
      tx({ id: "b", date: "2025-01-13", amount: -10, category: "food" }),
      tx({ id: "c", date: "2025-01-14", amount: -30, category: "transport" }),
      tx({ id: "d", date: "2025-01-13", amount: 100, category: "transfer" }), // credit, ignored
    ];
    const cells = spendHeatmap(txs);
    const mondayFood = cells.find(
      (c) => c.day === 0 && c.category === "food",
    );
    expect(mondayFood?.spend).toBe(30);
    const tuesdayTransport = cells.find(
      (c) => c.day === 1 && c.category === "transport",
    );
    expect(tuesdayTransport?.spend).toBe(30);
    // Credit-only categories don't appear.
    expect(
      cells.find((c) => c.category === "transfer"),
    ).toBeUndefined();
  });
});
