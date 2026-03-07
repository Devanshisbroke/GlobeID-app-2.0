/**
 * Unit tests for tokenService — verifies token generation, verification, nonce replay protection.
 * Backend replacement: swap to real JOSE/JWT library tests.
 */
import { describe, it, expect, vi } from "vitest";
import { createToken, verifyToken, decodeToken, consumeNonce, isNonceUsed } from "@/lib/tokenService";

describe("tokenService", () => {
  it("generates a valid JWT-like token with 3 parts", () => {
    const { token, payload } = createToken({
      kid: "test-key-1",
      exp: Math.floor(Date.now() / 1000) + 60,
      user_id: "user-123",
    });
    expect(token.split(".")).toHaveLength(3);
    expect(payload.kid).toBe("test-key-1");
    expect(payload.user_id).toBe("user-123");
    expect(payload.iss).toBe("terracore");
    expect(payload.nonce).toBeTruthy();
  });

  it("verifies a non-expired token", () => {
    const { token } = createToken({
      kid: "k1",
      exp: Math.floor(Date.now() / 1000) + 60,
    });
    const result = verifyToken(token);
    expect(result.valid).toBe(true);
    expect(result.payload?.kid).toBe("k1");
  });

  it("rejects an expired token", () => {
    const { token } = createToken({
      kid: "k2",
      exp: Math.floor(Date.now() / 1000) - 10,
    });
    const result = verifyToken(token);
    expect(result.valid).toBe(false);
    expect(result.error).toBe("Token expired");
  });

  it("decodes token payload correctly", () => {
    const { token } = createToken({
      kid: "k3",
      exp: Math.floor(Date.now() / 1000) + 60,
      session_id: "sess-abc",
      country_code: "IN",
    });
    const payload = decodeToken(token);
    expect(payload?.session_id).toBe("sess-abc");
    expect(payload?.country_code).toBe("IN");
  });

  it("tracks nonces for replay protection", () => {
    const { payload } = createToken({
      kid: "k4",
      exp: Math.floor(Date.now() / 1000) + 60,
    });
    expect(isNonceUsed(payload.nonce)).toBe(true);
    // First consume succeeds
    expect(consumeNonce(payload.nonce)).toBe(true);
    // Second consume fails (replay rejected)
    expect(consumeNonce(payload.nonce)).toBe(false);
  });

  it("rejects decode of garbage input", () => {
    expect(decodeToken("not-a-token")).toBeNull();
    expect(verifyToken("garbage").valid).toBe(false);
  });
});
