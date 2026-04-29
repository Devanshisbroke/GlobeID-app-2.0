import { describe, it, expect } from "vitest";
import { buildReceiptRows } from "@/lib/receiptRenderer";
import type { WalletTransaction } from "@shared/types/wallet";

const tx: WalletTransaction = {
  id: "tx-123",
  type: "payment",
  description: "Dinner at Maison Pic",
  amount: -140.5,
  currency: "EUR",
  date: "2025-05-12",
  category: "food",
  icon: "utensils",
  merchant: "Maison Pic",
  location: "Valence",
  country: "France",
  reference: "ref-789",
};

describe("buildReceiptRows", () => {
  it("emits canonical key/value rows and a Debit direction for negatives", () => {
    const rows = buildReceiptRows(tx, { holderName: "Ada Lovelace", holderEmail: "ada@example.com" });
    const kv = Object.fromEntries(rows.map((r) => [r.label, r.value]));
    expect(kv["Transaction ID"]).toBe("tx-123");
    expect(kv["Amount"]).toBe("EUR 140.50");
    expect(kv["Direction"]).toBe("Debit");
    expect(kv["Merchant"]).toBe("Maison Pic");
    expect(kv["Holder"]).toBe("Ada Lovelace");
    expect(kv["Email"]).toBe("ada@example.com");
    expect(kv["Issued by"]).toBe("GlobeID");
  });

  it("marks credits as Credit direction", () => {
    const creditTx = { ...tx, amount: 200, description: "Refund" };
    const rows = buildReceiptRows(creditTx, { holderName: "Ada" });
    const direction = rows.find((r) => r.label === "Direction")?.value;
    expect(direction).toBe("Credit");
  });
});
