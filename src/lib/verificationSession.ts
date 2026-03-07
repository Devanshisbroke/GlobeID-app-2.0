import { createToken, verifyToken, decodeToken, consumeNonce, generateShortCode, type TokenPayload } from "./tokenService";
import { audit } from "./auditLog";
import { eventBus } from "./eventBus";

export type SessionStatus = "idle" | "pending" | "app_scanned" | "verified" | "expired" | "failed";

export interface VerificationSession {
  id: string;
  kioskId: string;
  kioskToken: string;
  passportHash: string;
  countryCode: string;
  status: SessionStatus;
  createdAt: number;
  expiresAt: number;
  appTokenId?: string;
  receiptId?: string;
  receiptJws?: string;
  shortCode: string;
}

export interface EntryReceipt {
  id: string;
  sessionId: string;
  userId: string;
  did: string;
  countryCode: string;
  kioskId: string;
  receiptJws: string;
  createdAt: number;
}

const sessions = new Map<string, VerificationSession>();
const receipts = new Map<string, EntryReceipt>();
const SESSION_TTL = 120_000; // 2 minutes

// ── Kiosk: verify passport ──
export function kioskVerifyPassport(params: {
  kioskId: string;
  passportHash: string;
  countryCode: string;
  biometricHash?: string;
}): { session: VerificationSession; sessionToken: string } {
  const sessionId = crypto.randomUUID();
  const now = Date.now();

  const { token } = createToken({
    kid: "kiosk-key-1",
    exp: Math.floor((now + SESSION_TTL) / 1000),
    session_id: sessionId,
    kiosk_id: params.kioskId,
    country_code: params.countryCode,
  });

  const session: VerificationSession = {
    id: sessionId,
    kioskId: params.kioskId,
    kioskToken: token,
    passportHash: params.passportHash,
    countryCode: params.countryCode,
    status: "pending",
    createdAt: now,
    expiresAt: now + SESSION_TTL,
    shortCode: generateShortCode(),
  };

  sessions.set(sessionId, session);

  audit("kiosk_scan_received", { sessionId, kioskId: params.kioskId, countryCode: params.countryCode }, "kiosk");
  eventBus.emit("session:created", session);

  // Auto-expire
  setTimeout(() => {
    const s = sessions.get(sessionId);
    if (s && (s.status === "pending" || s.status === "app_scanned")) {
      s.status = "expired";
      audit("session_expired", { sessionId }, "backend");
      eventBus.emit("session:expired", s);
    }
  }, SESSION_TTL);

  return { session, sessionToken: token };
}

// ── App: generate QR token ──
export function appGenerateQR(params: {
  userId: string;
  sessionId?: string;
}): { appToken: string; payload: TokenPayload; shortCode: string; expiresAt: number } {
  const now = Date.now();
  const ttl = 30_000; // 30s
  const { token, payload } = createToken({
    kid: "app-key-1",
    exp: Math.floor((now + ttl) / 1000),
    session_id: params.sessionId,
    user_id: params.userId,
  });

  const shortCode = generateShortCode();

  audit("app_qr_generated", { userId: params.userId, sessionId: params.sessionId }, "app");

  return { appToken: token, payload, shortCode, expiresAt: now + ttl };
}

// ── Kiosk: scan app QR ──
export function kioskScanApp(params: {
  sessionId: string;
  appToken: string;
}): { success: boolean; error?: string; receipt?: EntryReceipt } {
  const session = sessions.get(params.sessionId);
  if (!session) return { success: false, error: "Session not found" };
  if (session.status === "expired") return { success: false, error: "Session expired" };
  if (session.status === "verified") return { success: false, error: "Session already verified" };
  if (Date.now() > session.expiresAt) {
    session.status = "expired";
    return { success: false, error: "Session expired" };
  }

  const { valid, payload, error } = verifyToken(params.appToken);
  if (!valid || !payload) {
    session.status = "failed";
    audit("session_failed", { sessionId: params.sessionId, error: error ?? "Invalid token" }, "backend");
    eventBus.emit("session:failed", session, error);
    return { success: false, error: error ?? "Invalid app token" };
  }

  // Nonce check (replay protection)
  if (payload.nonce && !consumeNonce(payload.nonce)) {
    audit("replay_rejected", { sessionId: params.sessionId, nonce: payload.nonce }, "backend");
    return { success: false, error: "Replay detected — token already consumed" };
  }

  audit("app_qr_scanned", { sessionId: params.sessionId, userId: payload.user_id }, "kiosk");

  // Create receipt
  const receiptId = crypto.randomUUID();
  const userId = payload.user_id ?? "unknown";
  const { token: receiptJws } = createToken({
    kid: "backend-receipt-key",
    exp: Math.floor(Date.now() / 1000) + 86400 * 365, // 1 year
    session_id: params.sessionId,
    user_id: userId,
    country_code: session.countryCode,
    kiosk_id: session.kioskId,
  });

  const receipt: EntryReceipt = {
    id: receiptId,
    sessionId: params.sessionId,
    userId,
    did: `did:terracore:${userId}`,
    countryCode: session.countryCode,
    kioskId: session.kioskId,
    receiptJws,
    createdAt: Date.now(),
  };

  receipts.set(receiptId, receipt);
  session.status = "verified";
  session.appTokenId = payload.nonce;
  session.receiptId = receiptId;
  session.receiptJws = receiptJws;

  audit("session_verified", { sessionId: params.sessionId, userId, countryCode: session.countryCode }, "backend");
  audit("receipt_created", { receiptId, sessionId: params.sessionId }, "backend");

  eventBus.emit("session:verified", session, receipt);

  return { success: true, receipt };
}

// ── Queries ──
export function getSession(id: string): VerificationSession | undefined {
  return sessions.get(id);
}

export function getReceipt(id: string): EntryReceipt | undefined {
  return receipts.get(id);
}

export function getAllSessions(): VerificationSession[] {
  return Array.from(sessions.values()).sort((a, b) => b.createdAt - a.createdAt);
}
