import { describe, it, expect } from "vitest";
import {
  lookupVisaPolicy,
  labelForBand,
  toneForBand,
  isoForCountry,
} from "@/lib/visaRequirements";

describe("visaRequirements", () => {
  it("returns visa-free for US → UK", () => {
    const p = lookupVisaPolicy("US", "GB");
    expect(p.band).toBe("visa_free");
    expect(p.maxDays).toBe(180);
  });

  it("returns ESTA / evisa for foreigners → US", () => {
    expect(lookupVisaPolicy("GB", "US").band).toBe("evisa");
    expect(lookupVisaPolicy("DE", "US").band).toBe("evisa");
  });

  it("falls back to visa_required for unknown pairs", () => {
    const p = lookupVisaPolicy("ZZ", "AA");
    expect(p.band).toBe("visa_required");
    expect(p.passportValidityMonths).toBe(6);
  });

  it("labelForBand returns human strings", () => {
    expect(labelForBand("visa_free")).toBe("Visa-free");
    expect(labelForBand("voa")).toBe("Visa on arrival");
    expect(labelForBand("evisa")).toBe("eVisa required");
    expect(labelForBand("visa_required")).toBe("Visa required");
    expect(labelForBand("no_relations")).toBe("Restricted");
  });

  it("toneForBand maps to UI tones", () => {
    expect(toneForBand("visa_free")).toBe("success");
    expect(toneForBand("evisa")).toBe("info");
    expect(toneForBand("visa_required")).toBe("warning");
    expect(toneForBand("no_relations")).toBe("critical");
  });

  it("isoForCountry resolves common country names", () => {
    expect(isoForCountry("United States")).toBe("US");
    expect(isoForCountry("Japan")).toBe("JP");
    expect(isoForCountry("Atlantis")).toBeNull();
  });
});
