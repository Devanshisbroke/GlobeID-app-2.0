import { describe, it, expect } from "vitest";
import {
  convertAmount,
  portfolioValue,
  bestConversionRoute,
  type Rates,
} from "@/lib/currencyEngine";
import type { WalletBalance } from "@shared/types/wallet";

const rates: Rates = {
  base: "USD",
  rates: { USD: 1, EUR: 0.9, GBP: 0.8, INR: 83 },
};

describe("convertAmount", () => {
  it("returns identity when from === to", () => {
    expect(convertAmount("USD", "USD", 100, rates)).toBe(100);
    expect(convertAmount("EUR", "EUR", 50, rates)).toBe(50);
  });

  it("converts against a matching base", () => {
    expect(convertAmount("USD", "EUR", 100, rates)).toBeCloseTo(90, 6);
    expect(convertAmount("USD", "INR", 1, rates)).toBeCloseTo(83, 6);
  });

  it("triangulates through the base for non-base pairs", () => {
    // 100 EUR → USD → INR: 100/0.9 * 83 ≈ 9222.22
    expect(convertAmount("EUR", "INR", 100, rates)).toBeCloseTo(
      (100 / 0.9) * 83,
      2,
    );
  });

  it("returns null for unknown currencies", () => {
    expect(convertAmount("JPY", "USD", 100, rates)).toBeNull();
  });
});

describe("portfolioValue", () => {
  const balances: WalletBalance[] = [
    { currency: "USD", amount: 100, symbol: "$", flag: "🇺🇸", rate: 1 },
    { currency: "EUR", amount: 50, symbol: "€", flag: "🇪🇺", rate: 0.9 },
    { currency: "JPY", amount: 1000, symbol: "¥", flag: "🇯🇵", rate: 150 },
  ];

  it("sums convertible balances in the requested base", () => {
    const snap = portfolioValue(balances, "USD", rates);
    // USD 100 + EUR 50 (≈55.555 USD)
    expect(snap.total).toBeCloseTo(100 + 50 / 0.9, 2);
    expect(snap.missing).toEqual(["JPY"]);
    expect(snap.byCurrency).toHaveLength(3);
  });

  it("returns zero total when rates are unavailable", () => {
    const snap = portfolioValue(balances, "USD", null);
    expect(snap.total).toBe(0);
    // Without a rates table we cannot convert anything — mark them all
    // missing so the UI can show a placeholder.
    expect(new Set(snap.missing)).toEqual(new Set(["USD", "EUR", "JPY"]));
  });
});

describe("bestConversionRoute", () => {
  const balances: WalletBalance[] = [
    { currency: "USD", amount: 200, symbol: "$", flag: "🇺🇸", rate: 1 },
    { currency: "EUR", amount: 90, symbol: "€", flag: "🇪🇺", rate: 0.9 },
    { currency: "GBP", amount: 10, symbol: "£", flag: "🇬🇧", rate: 0.8 },
  ];

  it("picks a like-for-like route (zero cost) when available", () => {
    const route = bestConversionRoute(balances, "USD", 50, rates);
    expect(route).not.toBeNull();
    expect(route!.from).toBe("USD");
    expect(route!.cost).toBe(0);
  });

  it("prefers a direct same-currency source over conversions", () => {
    // 80 EUR can be covered by either EUR balance (direct, cost 0) or USD
    // (cross-rate, non-zero). Zero-cost path must win.
    const needEur = bestConversionRoute(balances, "EUR", 80, rates);
    expect(needEur).not.toBeNull();
    expect(needEur!.from).toBe("EUR");
    expect(needEur!.cost).toBe(0);
  });

  it("falls back to the only affordable source when the direct wallet is short", () => {
    // 50 GBP: GBP has 10 (short), EUR has 90 → 50/0.8 from USD = 62.5 USD,
    // or via EUR: 50/(0.8/0.9) = 56.25 EUR. EUR has 90, USD has 200.
    // Both cross paths are available, costs should be ≈ 0 due to our ideal
    // math so lexical order breaks the tie — the point of the test is that
    // GBP is *not* picked.
    const needGbp = bestConversionRoute(balances, "GBP", 50, rates);
    expect(needGbp).not.toBeNull();
    expect(needGbp!.from).not.toBe("GBP");
  });

  it("returns null if no balance can cover the target", () => {
    const tooMuch = bestConversionRoute(balances, "GBP", 10_000, rates);
    expect(tooMuch).toBeNull();
  });
});
