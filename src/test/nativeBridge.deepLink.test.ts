import { describe, it, expect } from "vitest";
import { deepLinkToPath } from "@/lib/nativeBridge";

describe("deepLinkToPath", () => {
  it("maps globeid://trip/<id> to /trip/<id>", () => {
    expect(deepLinkToPath("globeid://trip/abc-123")).toBe("/trip/abc-123");
  });

  it("maps globeid://pass/<code> to /wallet?pass=<code>", () => {
    expect(deepLinkToPath("globeid://pass/BP-AC-001")).toBe(
      "/wallet?pass=BP-AC-001",
    );
  });

  it("maps globeid://wallet to /wallet", () => {
    expect(deepLinkToPath("globeid://wallet")).toBe("/wallet");
  });

  it("maps globeid://verify to /kiosk", () => {
    expect(deepLinkToPath("globeid://verify")).toBe("/kiosk");
  });

  it("returns null for unknown hosts", () => {
    expect(deepLinkToPath("globeid://unknown")).toBe(null);
  });

  it("returns null for malformed URLs", () => {
    expect(deepLinkToPath("not a url")).toBe(null);
  });

  it("supports https universal-link parity", () => {
    expect(deepLinkToPath("https://app.globeid.app/trip/xyz")).toBe(
      "/trip/xyz",
    );
  });

  it("URL-encodes embedded slashes / special chars in id", () => {
    expect(deepLinkToPath("globeid://trip/foo bar")).toBe("/trip/foo%20bar");
  });
});
