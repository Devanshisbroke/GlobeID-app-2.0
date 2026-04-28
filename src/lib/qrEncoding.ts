/**
 * Phase 9-γ — QR boarding-pass encoding.
 *
 * The output is a structured JSON payload, NOT a real airline-issued
 * IATA BCBP (Bar Coded Boarding Pass). Real BCBP is signed and issued
 * by the operating carrier; we cannot synthesise that. The QR here is
 * scannable proof of travel-record membership in the user's wallet —
 * useful for in-app display, lounge attendants, or social check-in,
 * but never to clear a real boarding gate.
 *
 * Every payload carries `kind: "globeid.demo-pass.v1"` and `isDemoData: true`
 * so any downstream verifier can refuse it.
 */

export interface DemoBoardingPassPayload {
  kind: "globeid.demo-pass.v1";
  isDemoData: true;
  passenger: string;
  passportLast4: string | null;
  flightNumber: string;
  airline: string;
  fromIata: string;
  toIata: string;
  scheduledDate: string;
  legId: string;
  tripId: string | null;
  issuedAt: number;
  appOrigin: string;
}

export interface EncodeArgs {
  passenger: string;
  passportNo: string | null;
  flightNumber: string;
  airline: string;
  fromIata: string;
  toIata: string;
  scheduledDate: string;
  legId: string;
  tripId: string | null;
}

export function encodeBoardingPass(args: EncodeArgs): {
  payload: DemoBoardingPassPayload;
  qrText: string;
} {
  const passportLast4 =
    args.passportNo && args.passportNo.length >= 4
      ? args.passportNo.slice(-4)
      : null;

  const payload: DemoBoardingPassPayload = {
    kind: "globeid.demo-pass.v1",
    isDemoData: true,
    passenger: args.passenger,
    passportLast4,
    flightNumber: args.flightNumber,
    airline: args.airline,
    fromIata: args.fromIata,
    toIata: args.toIata,
    scheduledDate: args.scheduledDate,
    legId: args.legId,
    tripId: args.tripId,
    issuedAt: Date.now(),
    appOrigin: typeof window !== "undefined" ? window.location.origin : "globeid",
  };

  return {
    payload,
    qrText: JSON.stringify(payload),
  };
}
