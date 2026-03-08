export interface PaymentRequest {
  amount: number;
  currency: string;
  merchant: string;
  description?: string;
}

export interface PaymentResponse {
  success: boolean;
  transactionId: string;
  timestamp: string;
  message: string;
}

export async function processPayment(req: PaymentRequest): Promise<PaymentResponse> {
  // Simulate network delay
  await new Promise((r) => setTimeout(r, 800 + Math.random() * 600));
  return {
    success: true,
    transactionId: `GID-${Date.now().toString(36).toUpperCase()}`,
    timestamp: new Date().toISOString(),
    message: `Payment of ${req.currency} ${Math.abs(req.amount).toFixed(2)} to ${req.merchant} processed.`,
  };
}

export interface QRPayload {
  amount: number;
  currency: string;
  merchant: string;
  merchantId?: string;
  reference?: string;
}

export function encodeQRPayload(payload: QRPayload): string {
  return btoa(JSON.stringify({ ...payload, ts: Date.now(), v: "1" }));
}

export function decodeQRPayload(encoded: string): QRPayload | null {
  try {
    const parsed = JSON.parse(atob(encoded));
    return { amount: parsed.amount, currency: parsed.currency, merchant: parsed.merchant, merchantId: parsed.merchantId, reference: parsed.reference };
  } catch {
    return null;
  }
}
