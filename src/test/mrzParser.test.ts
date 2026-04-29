import { describe, it, expect } from "vitest";
import { classifyDocument, parseMrz } from "@/lib/mrzParser";

describe("parseMrz — TD3 passport", () => {
  // ICAO 9303 Appendix example — John Doe, USA passport.
  // Actual check digits computed per the spec.
  const line1 = "P<USADOE<<JOHN<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";
  const line2 = "L898902C36USA7408122F1204159ZE184226B<<<<<10";

  it("parses the canonical ICAO example", () => {
    const r = parseMrz(`${line1}\n${line2}`);
    expect(r.kind).toBe("td3");
    expect(r.fields).not.toBeNull();
    expect(r.fields!.surname).toBe("DOE");
    expect(r.fields!.givenNames).toBe("JOHN");
    expect(r.fields!.issuingCountry).toBe("USA");
    expect(r.fields!.nationality).toBe("USA");
    expect(r.fields!.documentNumber).toBe("L898902C3");
    expect(r.fields!.dateOfBirth).toBe("1974-08-12");
    expect(r.fields!.dateOfExpiry).toBe("2012-04-15");
    expect(r.fields!.sex).toBe("F");
  });

  it("accepts extra surrounding text (messy OCR)", () => {
    const noisy = `JUNK 1 2 3\n${line1}\n${line2}\nmore noise`;
    const r = parseMrz(noisy);
    expect(r.kind).toBe("td3");
    expect(r.fields!.surname).toBe("DOE");
  });

  it("returns unknown for non-MRZ input", () => {
    const r = parseMrz("Just some random text\nthat isn't an MRZ");
    expect(r.kind).toBe("unknown");
    expect(r.fields).toBeNull();
  });
});

describe("classifyDocument", () => {
  it("classifies TD3 MRZ as passport", () => {
    const line1 = "P<USADOE<<JOHN<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";
    const line2 = "L898902C36USA7408122F1204159ZE184226B<<<<<10";
    expect(classifyDocument(`${line1}\n${line2}`)).toBe("passport");
  });

  it("classifies visa keywords", () => {
    expect(classifyDocument("Schengen VISA issued by Germany")).toBe("visa");
  });

  it("classifies id_card keywords", () => {
    expect(classifyDocument("NATIONAL ID card\nNumber 1234")).toBe("id_card");
  });

  it("returns unknown for gibberish", () => {
    expect(classifyDocument("hello world lorem ipsum")).toBe("unknown");
  });
});
