import { describe, it, expect } from "vitest";
import { parseIntent, suggestIntents } from "@/lib/voiceIntents";

describe("voiceIntents extended (H 95-100)", () => {
  it("parses numeric trip selection", () => {
    expect(parseIntent("trip 3")).toMatchObject({
      kind: "numeric",
      target: "trip",
      index: 3,
    });
    expect(parseIntent("pass number 12")).toMatchObject({
      kind: "numeric",
      target: "pass",
      index: 12,
    });
  });

  it("parses translate intent with language code mapping", () => {
    expect(parseIntent("translate this to french")).toMatchObject({
      kind: "translate",
      toLang: "fr",
    });
    expect(parseIntent("translate to japanese")).toMatchObject({
      kind: "translate",
      toLang: "ja",
    });
  });

  it("parses remind intent with time", () => {
    const r = parseIntent("remind me to pack at 7pm");
    expect(r.kind).toBe("remind");
    if (r.kind === "remind") {
      expect(r.text).toBe("pack");
      expect(r.whenLocal).toBe("19:00");
    }
  });

  it("parses 12am edge case", () => {
    const r = parseIntent("remind me to call mom at 12am");
    if (r.kind === "remind") {
      expect(r.whenLocal).toBe("00:00");
    } else {
      throw new Error("expected remind");
    }
  });

  it("parses compose multi-step with place", () => {
    const r = parseIntent("book a hotel in tokyo");
    expect(r.kind).toBe("compose");
    if (r.kind === "compose") {
      expect(r.subject).toBe("hotel");
      expect(r.meta.place).toBe("tokyo");
    }
  });

  it("parses compose with place + when", () => {
    const r = parseIntent("book a hotel in tokyo for next friday");
    expect(r.kind).toBe("compose");
    if (r.kind === "compose") {
      expect(r.meta.place).toBe("tokyo");
      expect(r.meta.when).toBe("next friday");
    }
  });

  it("does NOT shadow simple search ('find a hotel')", () => {
    expect(parseIntent("find a hotel")).toMatchObject({
      kind: "search",
      target: "hotels",
    });
  });

  it("suggests intents for unrecognised phrases", () => {
    const s = suggestIntents("show wallet");
    expect(s.length).toBeGreaterThan(0);
    expect(s.some((s) => s.toLowerCase().includes("wallet"))).toBe(true);
  });

  it("returns empty array for empty transcript", () => {
    expect(suggestIntents("")).toEqual([]);
  });
});
