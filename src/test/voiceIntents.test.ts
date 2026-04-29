import { describe, it, expect } from "vitest";
import { parseIntent, stripWakeWord } from "@/lib/voiceIntents";

describe("parseIntent", () => {
  it("recognises navigation intents", () => {
    expect(parseIntent("go to wallet")).toMatchObject({ kind: "navigate", path: "/wallet" });
    expect(parseIntent("open home")).toMatchObject({ kind: "navigate", path: "/" });
    expect(parseIntent("show services")).toMatchObject({ kind: "navigate", path: "/services/super" });
    expect(parseIntent("open vault")).toMatchObject({ kind: "navigate", path: "/vault" });
    expect(parseIntent("show social")).toMatchObject({ kind: "navigate", path: "/feed" });
  });

  it("recognises action intents", () => {
    expect(parseIntent("refresh the page")).toMatchObject({ kind: "action", action: "refresh" });
    expect(parseIntent("scan my passport")).toMatchObject({ kind: "action", action: "start-scan" });
    expect(parseIntent("switch language")).toMatchObject({
      kind: "action",
      action: "toggle-language",
    });
  });

  it("recognises queries", () => {
    expect(parseIntent("what's my balance")).toMatchObject({ kind: "query", query: "wallet-balance" });
    expect(parseIntent("upcoming flight")).toMatchObject({ kind: "query", query: "next-trip" });
    expect(parseIntent("show my travel score")).toMatchObject({ kind: "query", query: "score" });
    expect(parseIntent("weather today")).toMatchObject({ kind: "query", query: "weather" });
  });

  it("recognises searches", () => {
    expect(parseIntent("find a hotel")).toMatchObject({ kind: "search", target: "hotels" });
    expect(parseIntent("book a ride")).toMatchObject({ kind: "search", target: "rides" });
    expect(parseIntent("order some food")).toMatchObject({ kind: "search", target: "food" });
    expect(parseIntent("visa check")).toMatchObject({ kind: "search", target: "visa" });
  });

  it("returns unknown for gibberish", () => {
    expect(parseIntent("asdf lmnop qwerty")).toMatchObject({ kind: "unknown" });
    expect(parseIntent("")).toMatchObject({ kind: "unknown" });
  });

  it("is case-insensitive and punctuation-tolerant", () => {
    expect(parseIntent("GO TO WALLET!!!")).toMatchObject({ kind: "navigate", path: "/wallet" });
    expect(parseIntent("  refresh,  please  ")).toMatchObject({ kind: "action", action: "refresh" });
  });

  it("is deterministic", () => {
    expect(parseIntent("go to home")).toEqual(parseIntent("go to home"));
  });
});

describe("stripWakeWord", () => {
  it("strips hey-globe prefix and returns the rest", () => {
    expect(stripWakeWord("hey globe go to wallet")).toBe("go to wallet");
    expect(stripWakeWord("ok globe refresh")).toBe("refresh");
    expect(stripWakeWord("okay globeid what's my balance")).toBe("what's my balance");
  });

  it("returns null when wake word is missing", () => {
    expect(stripWakeWord("go to wallet")).toBeNull();
    expect(stripWakeWord("")).toBeNull();
  });
});
