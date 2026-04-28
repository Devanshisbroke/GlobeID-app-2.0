/**
 * paymentGateway — QR payload codec only.
 *
 * Slice-A note: actual payment processing now goes through the real wallet
 * ledger (`api.wallet.record` / `useWalletStore.recordTransaction`). The
 * "gateway" stub that simulated PSP latency was removed because it was
 * the kind of fake flow we explicitly forbid. Until a real PSP key is
 * wired (STRIPE_SECRET_KEY / RAZORPAY_KEY_ID), all "Pay" actions hit the
 * idempotent ledger and return `isDemoGateway: true` from the server.
 *
 * The encode/decode helpers below are still real and used to round-trip
 * payment intents through QR codes — that part is honest functionality,
 * not a simulation.
 */

export interface QRPayload {
  amount: number;
  currency: string;
  merchant: string;
  merchantId?: string;
  reference?: string;
  /** issued-at unix ms; lets the scanner reject stale payloads */
  ts?: number;
  /** payload format version */
  v?: string;
}

const QR_VERSION = "1";

export function encodeQRPayload(payload: Omit<QRPayload, "ts" | "v">): string {
  const enriched = { ...payload, ts: Date.now(), v: QR_VERSION };
  return btoa(JSON.stringify(enriched));
}

export function decodeQRPayload(encoded: string): QRPayload | null {
  try {
    const parsed = JSON.parse(atob(encoded));
    if (typeof parsed !== "object" || parsed === null) return null;
    const { amount, currency, merchant, merchantId, reference, ts, v } = parsed as QRPayload;
    if (typeof amount !== "number" || !isFinite(amount) || amount <= 0) return null;
    if (typeof currency !== "string" || !currency) return null;
    if (typeof merchant !== "string" || !merchant) return null;
    return { amount, currency, merchant, merchantId, reference, ts, v };
  } catch {
    return null;
  }
}
