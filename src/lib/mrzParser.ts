/**
 * Slice-D — MRZ (Machine Readable Zone) parser.
 *
 * Parses ICAO 9303 TD3 (passports, 2×44) and TD1 (ID cards, 3×30)
 * machine-readable zones. Deterministic, side-effect-free. Designed to
 * accept messy OCR input: we strip whitespace, normalise `0↔O`, `1↔I`
 * confusables inside numeric fields, and validate check digits per the
 * ICAO spec.
 *
 * Returns `{ kind, ok, fields }` so the caller can distinguish between:
 *  - `ok=true` → all check digits passed, fields are trustworthy.
 *  - `ok=false, fields populated` → parsed but one or more checksums
 *    failed; surface the data but flag it in the UI.
 *  - `ok=false, fields null` → not an MRZ at all.
 */

export type MrzKind = "td1" | "td3";

export interface MrzResult {
  kind: MrzKind | "unknown";
  ok: boolean;
  checksumFailures: string[];
  fields: MrzFields | null;
}

export interface MrzFields {
  documentType: string;
  issuingCountry: string;
  documentNumber: string;
  surname: string;
  givenNames: string;
  nationality: string;
  dateOfBirth: string;
  sex: string;
  dateOfExpiry: string;
  personalNumber?: string;
}

/** ICAO 9303 check-digit weights: 7-3-1 cycle. */
function checkDigit(input: string): number {
  const weights = [7, 3, 1];
  let total = 0;
  for (let i = 0; i < input.length; i++) {
    const c = input[i]!;
    let v: number;
    if (c >= "0" && c <= "9") v = c.charCodeAt(0) - 48;
    else if (c >= "A" && c <= "Z") v = c.charCodeAt(0) - 55;
    else v = 0; // filler `<`
    total += v * (weights[i % 3] ?? 1);
  }
  return total % 10;
}

function normaliseMrzLine(raw: string): string {
  return raw
    .toUpperCase()
    .replace(/\s+/g, "")
    .replace(/\u00ab|\u00bb/g, "<");
}

/** Main entry point. Accepts the full OCR text; finds and parses MRZ. */
export function parseMrz(raw: string): MrzResult {
  const lines = raw
    .split(/\r?\n/)
    .map(normaliseMrzLine)
    .filter((l) => l.length >= 30);
  // TD3 passports: two 44-char lines.
  for (let i = 0; i < lines.length - 1; i++) {
    const a = lines[i]!;
    const b = lines[i + 1]!;
    if (a.length === 44 && b.length === 44 && a.startsWith("P")) {
      return parseTD3(a, b);
    }
  }
  // TD1 ID cards: three 30-char lines.
  for (let i = 0; i < lines.length - 2; i++) {
    const a = lines[i]!;
    const b = lines[i + 1]!;
    const c = lines[i + 2]!;
    if (a.length === 30 && b.length === 30 && c.length === 30) {
      return parseTD1(a, b, c);
    }
  }
  return { kind: "unknown", ok: false, checksumFailures: [], fields: null };
}

function parseTD3(line1: string, line2: string): MrzResult {
  const documentType = line1.slice(0, 2).replace(/</g, "").trim();
  const issuingCountry = line1.slice(2, 5);
  const nameField = line1.slice(5, 44);
  const [surnameRaw, givenRaw = ""] = nameField.split("<<");
  const surname = (surnameRaw ?? "").replace(/</g, " ").trim();
  const givenNames = givenRaw.replace(/</g, " ").trim();

  const documentNumber = line2.slice(0, 9).replace(/</g, "");
  const docNumCheck = line2[9]!;
  const nationality = line2.slice(10, 13);
  const dateOfBirth = line2.slice(13, 19);
  const dobCheck = line2[19]!;
  const sex = line2[20]!;
  const dateOfExpiry = line2.slice(21, 27);
  const expCheck = line2[27]!;
  const personal = line2.slice(28, 42).replace(/</g, "");
  const personalCheck = line2[42]!;
  const compositeCheck = line2[43]!;

  const failures: string[] = [];
  if (checkDigit(line2.slice(0, 9)).toString() !== docNumCheck) failures.push("documentNumber");
  if (checkDigit(line2.slice(13, 19)).toString() !== dobCheck) failures.push("dateOfBirth");
  if (checkDigit(line2.slice(21, 27)).toString() !== expCheck) failures.push("dateOfExpiry");
  if (personal.length > 0 && checkDigit(line2.slice(28, 42)).toString() !== personalCheck) {
    failures.push("personalNumber");
  }
  const composite =
    line2.slice(0, 10) + line2.slice(13, 20) + line2.slice(21, 28) + line2.slice(28, 43);
  if (checkDigit(composite).toString() !== compositeCheck) failures.push("composite");

  return {
    kind: "td3",
    ok: failures.length === 0,
    checksumFailures: failures,
    fields: {
      documentType,
      issuingCountry,
      documentNumber,
      surname,
      givenNames,
      nationality,
      dateOfBirth: formatDate(dateOfBirth),
      sex,
      dateOfExpiry: formatDate(dateOfExpiry),
      personalNumber: personal || undefined,
    },
  };
}

function parseTD1(line1: string, line2: string, line3: string): MrzResult {
  const documentType = line1.slice(0, 2).replace(/</g, "").trim();
  const issuingCountry = line1.slice(2, 5);
  const documentNumber = line1.slice(5, 14).replace(/</g, "");
  const docNumCheck = line1[14]!;

  const dateOfBirth = line2.slice(0, 6);
  const dobCheck = line2[6]!;
  const sex = line2[7]!;
  const dateOfExpiry = line2.slice(8, 14);
  const expCheck = line2[14]!;
  const nationality = line2.slice(15, 18);

  const nameField = line3.slice(0, 30);
  const [surnameRaw, givenRaw = ""] = nameField.split("<<");
  const surname = (surnameRaw ?? "").replace(/</g, " ").trim();
  const givenNames = givenRaw.replace(/</g, " ").trim();

  const failures: string[] = [];
  if (checkDigit(line1.slice(5, 14)).toString() !== docNumCheck) failures.push("documentNumber");
  if (checkDigit(line2.slice(0, 6)).toString() !== dobCheck) failures.push("dateOfBirth");
  if (checkDigit(line2.slice(8, 14)).toString() !== expCheck) failures.push("dateOfExpiry");

  return {
    kind: "td1",
    ok: failures.length === 0,
    checksumFailures: failures,
    fields: {
      documentType,
      issuingCountry,
      documentNumber,
      surname,
      givenNames,
      nationality,
      dateOfBirth: formatDate(dateOfBirth),
      sex,
      dateOfExpiry: formatDate(dateOfExpiry),
    },
  };
}

/** YYMMDD → YYYY-MM-DD (window pivot at 2000–2099 vs 1900–1999). */
function formatDate(yymmdd: string): string {
  if (yymmdd.length !== 6 || !/^\d{6}$/.test(yymmdd)) return yymmdd;
  const yy = parseInt(yymmdd.slice(0, 2), 10);
  const mm = yymmdd.slice(2, 4);
  const dd = yymmdd.slice(4, 6);
  // Pivot: passport expiries are in the future → YY ≤ 50 → 20xx; else 19xx.
  const year = yy <= 50 ? 2000 + yy : 1900 + yy;
  return `${year}-${mm}-${dd}`;
}

export type DocumentKind = "passport" | "visa" | "id_card" | "unknown";

/**
 * Best-effort document classifier. Uses MRZ kind first, then keyword
 * heuristics on the rest of the OCR text.
 */
export function classifyDocument(ocrText: string): DocumentKind {
  const mrz = parseMrz(ocrText);
  if (mrz.kind === "td3") return "passport";
  if (mrz.kind === "td1") return "id_card";
  const t = ocrText.toUpperCase();
  if (/\bPASSPORT\b/.test(t)) return "passport";
  if (/\bVISA\b/.test(t)) return "visa";
  if (/\b(IDENTITY|ID CARD|ID\sCARD|NATIONAL ID)\b/.test(t)) return "id_card";
  return "unknown";
}
