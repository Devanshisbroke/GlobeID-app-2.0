/**
 * Integration tests for verificationSession — full kiosk→app flow.
 */
import { describe, it, expect } from "vitest";
import { kioskVerifyPassport, kioskScanApp, appGenerateQR, getSession } from "@/lib/verificationSession";

describe("verificationSession", () => {
  it("creates a session via kiosk passport scan", () => {
    const { session } = kioskVerifyPassport({
      kioskId: "kiosk-test-1",
      passportHash: "sha256:test",
      countryCode: "US",
    });
    expect(session.status).toBe("pending");
    expect(session.countryCode).toBe("US");
    expect(getSession(session.id)).toBeDefined();
  });

  it("completes full kiosk → app → verify flow", () => {
    const { session } = kioskVerifyPassport({
      kioskId: "kiosk-test-2",
      passportHash: "sha256:test2",
      countryCode: "IN",
    });

    const { appToken } = appGenerateQR({ userId: "user-456", sessionId: session.id });

    const result = kioskScanApp({ sessionId: session.id, appToken });
    expect(result.success).toBe(true);
    expect(result.receipt).toBeDefined();
    expect(result.receipt?.countryCode).toBe("IN");
    expect(result.receipt?.did).toContain("did:terracore:");
  });

  it("rejects replay of consumed app token", () => {
    const { session } = kioskVerifyPassport({
      kioskId: "kiosk-test-3",
      passportHash: "sha256:test3",
      countryCode: "SG",
    });

    const { appToken } = appGenerateQR({ userId: "user-789", sessionId: session.id });
    
    // First scan succeeds
    const r1 = kioskScanApp({ sessionId: session.id, appToken });
    expect(r1.success).toBe(true);

    // Create new session for replay attempt
    const { session: s2 } = kioskVerifyPassport({
      kioskId: "kiosk-test-3",
      passportHash: "sha256:test3b",
      countryCode: "SG",
    });

    // Replay with same token fails
    const r2 = kioskScanApp({ sessionId: s2.id, appToken });
    expect(r2.success).toBe(false);
    expect(r2.error).toContain("Replay");
  });

  it("rejects scan on non-existent session", () => {
    const result = kioskScanApp({ sessionId: "nonexistent", appToken: "fake" });
    expect(result.success).toBe(false);
  });
});
