/**
 * Slice-A — wallet ledger schema tests.
 *
 * The full ledger semantics (idempotency keys, atomic balance updates,
 * insufficient-funds rejection) live on the server. This file pins the
 * Zod schemas the client/server share so neither side can drift the
 * shape silently. If the contract changes, these tests will fail and
 * force a coordinated update.
 */
import { describe, it, expect } from "vitest";
import {
  recordTransactionRequestSchema,
  convertRequestSchema,
  walletTransactionSchema,
} from "@shared/types/wallet";

describe("wallet ledger schemas", () => {
  it("accepts a well-formed payment request", () => {
    const ok = recordTransactionRequestSchema.safeParse({
      idempotencyKey: "abc-123-456-789",
      type: "payment",
      amount: 1499,
      currency: "INR",
      description: "Coffee",
      merchant: "Blue Tokai",
      category: "food",
      icon: "Coffee",
    });
    expect(ok.success).toBe(true);
  });

  it("rejects a zero amount", () => {
    const bad = recordTransactionRequestSchema.safeParse({
      idempotencyKey: "abc-123-456-789",
      type: "payment",
      amount: 0,
      currency: "INR",
      description: "Bug",
      category: "food",
      icon: "Coffee",
    });
    expect(bad.success).toBe(false);
  });

  it("rejects too-short idempotency keys", () => {
    const bad = recordTransactionRequestSchema.safeParse({
      idempotencyKey: "x",
      type: "payment",
      amount: 100,
      currency: "INR",
      description: "Test",
      category: "food",
      icon: "Coffee",
    });
    expect(bad.success).toBe(false);
  });

  it("requires non-empty currencies on convert", () => {
    const bad = convertRequestSchema.safeParse({
      idempotencyKey: "abc-123-456-789",
      fromCurrency: "",
      toCurrency: "USD",
      amount: 100,
    });
    expect(bad.success).toBe(false);
  });

  it("requires positive amount on convert", () => {
    const bad = convertRequestSchema.safeParse({
      idempotencyKey: "abc-123-456-789",
      fromCurrency: "INR",
      toCurrency: "USD",
      amount: -50,
    });
    expect(bad.success).toBe(false);
  });

  it("accepts a stored ledger row with full optional metadata", () => {
    const row = walletTransactionSchema.safeParse({
      id: "tx_abc",
      type: "payment",
      amount: -1499,
      currency: "INR",
      description: "Coffee",
      merchant: "Blue Tokai",
      date: "2099-01-15",
      category: "food",
      icon: "Coffee",
      country: "India",
      countryFlag: "🇮🇳",
      reference: "qr-payment-001",
    });
    expect(row.success).toBe(true);
  });
});
