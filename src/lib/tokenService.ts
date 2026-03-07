/**
 * Simulated JWS/JWT token service.
 * Produces realistic token structures; signing is simulated via HMAC-like hash.
 * Backend-ready: swap implementations to real jose/crypto when real backend exists.
 */

const usedNonces = new Set<string>();
const NONCE_TTL = 120_000; // 2 min

function generateNonce(): string {
  const nonce = crypto.randomUUID().replace(/-/g, "").slice(0, 16);
  usedNonces.add(nonce);
  setTimeout(() => usedNonces.delete(nonce), NONCE_TTL);
  return nonce;
}

export function isNonceUsed(nonce: string): boolean {
  return usedNonces.has(nonce);
}

export function consumeNonce(nonce: string): boolean {
  if (!usedNonces.has(nonce)) return false;
  usedNonces.delete(nonce);
  return true;
}

export interface TokenPayload {
  iss: string;
  kid: string;
  iat: number;
  exp: number;
  session_id?: string;
  user_id?: string;
  kiosk_id?: string;
  nonce: string;
  country_code?: string;
  [key: string]: unknown;
}

function base64url(str: string): string {
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function simSign(payload: string): string {
  // Simulated signature — deterministic hash-like string
  let h = 0;
  for (let i = 0; i < payload.length; i++) {
    h = ((h << 5) - h + payload.charCodeAt(i)) | 0;
  }
  return base64url(Math.abs(h).toString(36).padStart(12, "0"));
}

export function createToken(claims: Omit<TokenPayload, "iss" | "iat" | "nonce"> & { iss?: string; iat?: number; nonce?: string }): { token: string; payload: TokenPayload } {
  const now = Math.floor(Date.now() / 1000);
  const payload: TokenPayload = {
    iss: claims.iss ?? "terracore",
    kid: claims.kid,
    iat: claims.iat ?? now,
    exp: claims.exp,
    nonce: claims.nonce ?? generateNonce(),
    ...claims,
  };

  const header = base64url(JSON.stringify({ alg: "ES256", typ: "JWT", kid: payload.kid }));
  const body = base64url(JSON.stringify(payload));
  const sig = simSign(`${header}.${body}`);
  return { token: `${header}.${body}.${sig}`, payload };
}

export function decodeToken(token: string): TokenPayload | null {
  try {
    const [, body] = token.split(".");
    return JSON.parse(atob(body.replace(/-/g, "+").replace(/_/g, "/")));
  } catch {
    return null;
  }
}

export function verifyToken(token: string): { valid: boolean; payload: TokenPayload | null; error?: string } {
  const payload = decodeToken(token);
  if (!payload) return { valid: false, payload: null, error: "Invalid token format" };

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp < now) return { valid: false, payload, error: "Token expired" };

  return { valid: true, payload };
}

export function generateShortCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
