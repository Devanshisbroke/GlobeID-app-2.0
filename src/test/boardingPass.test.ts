/**
 * Slice-A — boarding-pass HMAC tests.
 *
 * These tests exercise *real* HMAC-SHA256 via Web Crypto subtle (Node 22
 * exposes it as `globalThis.crypto.subtle`). They cover the verification
 * contract that the `KioskSimulator` boarding-pass tab depends on.
 */
import { describe, it, expect } from "vitest";
import { issueBoardingPass, verifyBoardingPass } from "@/lib/boardingPass";

const baseArgs = {
  passenger: "Devansh Barai",
  passportNo: "M1234567",
  flightNumber: "AI307",
  airline: "Air India",
  fromIata: "BOM",
  toIata: "DEL",
  scheduledDate: "2099-01-15",
  legId: "leg-test-001",
  tripId: "trip-test-001",
};

describe("boardingPass", () => {
  it("issues and verifies a fresh pass", async () => {
    const SECRET = "test-secret-1";
    const { qrText, payload } = await issueBoardingPass(baseArgs, SECRET);
    expect(payload.flightNumber).toBe("AI307");
    expect(payload.passportLast4).toBe("4567");
    expect(payload.kind).toBe("globeid.bp.v1");

    const result = await verifyBoardingPass(qrText, SECRET);
    expect(result.valid).toBe(true);
    if (result.valid) {
      expect(result.payload.legId).toBe("leg-test-001");
    }
  });

  it("rejects a payload signed with a different secret", async () => {
    const { qrText } = await issueBoardingPass(baseArgs, "secret-a");
    const result = await verifyBoardingPass(qrText, "secret-b");
    expect(result.valid).toBe(false);
    if (!result.valid) {
      expect(result.error).toBe("Signature mismatch");
    }
  });

  it("rejects a tampered payload", async () => {
    const SECRET = "test-secret-2";
    const { qrText } = await issueBoardingPass(baseArgs, SECRET);
    const envelope = JSON.parse(qrText) as { p: Record<string, unknown>; s: string };
    envelope.p.passenger = "Eve The Attacker";
    const tamperedQr = JSON.stringify(envelope);

    const result = await verifyBoardingPass(tamperedQr, SECRET);
    expect(result.valid).toBe(false);
    if (!result.valid) {
      expect(result.error).toBe("Signature mismatch");
    }
  });

  it("rejects an expired pass", async () => {
    const SECRET = "test-secret-3";
    const longAgo = Date.now() - 30 * 24 * 3_600_000;
    const { qrText } = await issueBoardingPass(
      { ...baseArgs, exp: longAgo, iat: longAgo - 60_000 },
      SECRET,
    );
    const result = await verifyBoardingPass(qrText, SECRET);
    expect(result.valid).toBe(false);
    if (!result.valid) {
      expect(result.error).toBe("Pass expired");
    }
  });

  it("rejects malformed input", async () => {
    const result = await verifyBoardingPass("not-json", "any-secret");
    expect(result.valid).toBe(false);
    if (!result.valid) {
      expect(result.error).toBe("Malformed QR payload");
    }
  });

  it("rejects payload with the wrong kind marker", async () => {
    const fake = JSON.stringify({
      p: { ...baseArgs, kind: "evil.fake.v1", isDemoData: true, iat: 1, exp: Date.now() + 60_000, appOrigin: "evil" },
      s: "AAAA",
    });
    const result = await verifyBoardingPass(fake, "any-secret");
    expect(result.valid).toBe(false);
    if (!result.valid) {
      expect(result.error).toBe("Not a GlobeID boarding pass");
    }
  });

  it("masks passport numbers shorter than 4 chars", async () => {
    const { payload } = await issueBoardingPass(
      { ...baseArgs, passportNo: "A1" },
      "test",
    );
    expect(payload.passportLast4).toBeNull();
  });
});
