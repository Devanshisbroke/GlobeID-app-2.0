/**
 * Slice-A — signed boarding-pass QR.
 *
 * The QR encodes a JSON payload describing one trip leg, plus an HMAC-SHA256
 * signature over a stable canonical form of that payload. A verifier (e.g.
 * `KioskSimulator`) recomputes the HMAC with the same shared secret and
 * compares constant-time. Tampered or replayed payloads (after expiry)
 * fail verification.
 *
 * This is real cryptography (Web Crypto subtle.HMAC, SHA-256) — distinct
 * from the toy `simSign` in `tokenService.ts` which is left unchanged for
 * the existing identity-verification flow's contract.
 *
 * Caveat: this is NOT a real airline-issued IATA BCBP. Real boarding
 * passes are signed by the operating carrier's keypair. The payload still
 * carries `kind: "globeid.bp.v1"` + `isDemoData: true` so any genuine
 * gate verifier will reject it. Within the GlobeID app and the bundled
 * `KioskSimulator` mock, signature verification is real and meaningful.
 */
const SECRET: string =
  (typeof process !== "undefined" && process.env?.GLOBE_BP_SECRET) ||
  (typeof import.meta !== "undefined" && (import.meta as { env?: { VITE_BOARDING_PASS_SECRET?: string } }).env?.VITE_BOARDING_PASS_SECRET) ||
  "globe-dev-bp-secret-change-me";

const KIND = "globeid.bp.v1";

export interface BoardingPassPayload {
  kind: typeof KIND;
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
  iat: number; // issued-at unix ms
  exp: number; // expiry unix ms (departure +24h)
  appOrigin: string;
}

export interface SignedBoardingPass {
  payload: BoardingPassPayload;
  qrText: string;
}

export interface VerificationOk {
  valid: true;
  payload: BoardingPassPayload;
}

export interface VerificationFailed {
  valid: false;
  payload: BoardingPassPayload | null;
  error: string;
}

export type VerificationResult = VerificationOk | VerificationFailed;

export interface IssueArgs {
  passenger: string;
  passportNo: string | null;
  flightNumber: string;
  airline: string;
  fromIata: string;
  toIata: string;
  scheduledDate: string;
  legId: string;
  tripId: string | null;
  /** Override expiry (unix ms). Defaults to scheduledDate + 24h. */
  exp?: number;
  /** Override iat (unix ms). Defaults to Date.now(). */
  iat?: number;
}

function getCrypto(): Crypto {
  if (typeof globalThis !== "undefined" && globalThis.crypto?.subtle) {
    return globalThis.crypto;
  }
  throw new Error("Web Crypto subtle is unavailable in this environment");
}

function utf8Encode(s: string): Uint8Array {
  return new TextEncoder().encode(s);
}

function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlToBytes(b64: string): Uint8Array {
  const padded = b64.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (b64.length % 4)) % 4);
  const binary = atob(padded);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}

/** Stable JSON form: keys sorted, no whitespace. */
function canonicalize(payload: BoardingPassPayload): string {
  const ordered: Record<string, unknown> = {};
  for (const k of (Object.keys(payload) as Array<keyof BoardingPassPayload>).sort()) {
    ordered[k as string] = payload[k];
  }
  return JSON.stringify(ordered);
}

async function importHmacKey(secret: string): Promise<CryptoKey> {
  return getCrypto().subtle.importKey(
    "raw",
    utf8Encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

async function hmacSign(secret: string, data: string): Promise<string> {
  const key = await importHmacKey(secret);
  const sigBuf = await getCrypto().subtle.sign("HMAC", key, utf8Encode(data));
  return bytesToBase64Url(new Uint8Array(sigBuf));
}

async function hmacVerify(secret: string, data: string, sigB64: string): Promise<boolean> {
  const key = await importHmacKey(secret);
  let sig: Uint8Array;
  try {
    sig = base64UrlToBytes(sigB64);
  } catch {
    return false;
  }
  return getCrypto().subtle.verify("HMAC", key, sig, utf8Encode(data));
}

function deriveExp(scheduledDate: string): number {
  // Departure date at UTC noon + 24h. Wide enough for layover lounges
  // and red-eye departures that span midnight UTC.
  const t = Date.parse(`${scheduledDate}T12:00:00Z`);
  if (Number.isNaN(t)) return Date.now() + 7 * 24 * 3_600_000;
  return t + 24 * 3_600_000;
}

export async function issueBoardingPass(
  args: IssueArgs,
  secretOverride?: string,
): Promise<SignedBoardingPass> {
  const passportLast4 =
    args.passportNo && args.passportNo.length >= 4 ? args.passportNo.slice(-4) : null;
  const now = args.iat ?? Date.now();
  const payload: BoardingPassPayload = {
    kind: KIND,
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
    iat: now,
    exp: args.exp ?? deriveExp(args.scheduledDate),
    appOrigin: typeof window !== "undefined" ? window.location.origin : "globeid",
  };
  const canonical = canonicalize(payload);
  const sig = await hmacSign(secretOverride ?? SECRET, canonical);
  const envelope = { p: payload, s: sig };
  return { payload, qrText: JSON.stringify(envelope) };
}

export async function verifyBoardingPass(
  qrText: string,
  secretOverride?: string,
): Promise<VerificationResult> {
  let envelope: { p?: unknown; s?: unknown };
  try {
    envelope = JSON.parse(qrText);
  } catch {
    return { valid: false, payload: null, error: "Malformed QR payload" };
  }
  if (!envelope || typeof envelope !== "object" || typeof envelope.s !== "string") {
    return { valid: false, payload: null, error: "Missing signature" };
  }
  const candidate = envelope.p as Partial<BoardingPassPayload>;
  if (!candidate || candidate.kind !== KIND) {
    return { valid: false, payload: null, error: "Not a GlobeID boarding pass" };
  }
  const required: Array<keyof BoardingPassPayload> = [
    "kind",
    "isDemoData",
    "passenger",
    "flightNumber",
    "airline",
    "fromIata",
    "toIata",
    "scheduledDate",
    "legId",
    "iat",
    "exp",
    "appOrigin",
  ];
  for (const k of required) {
    if (candidate[k] === undefined) {
      return { valid: false, payload: null, error: `Missing field: ${k}` };
    }
  }
  const payload = candidate as BoardingPassPayload;
  const canonical = canonicalize(payload);
  const ok = await hmacVerify(secretOverride ?? SECRET, canonical, envelope.s);
  if (!ok) return { valid: false, payload, error: "Signature mismatch" };
  if (Date.now() > payload.exp) return { valid: false, payload, error: "Pass expired" };
  return { valid: true, payload };
}
