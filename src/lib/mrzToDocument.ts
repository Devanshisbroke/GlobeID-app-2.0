/**
 * Bridge: MRZ-parser output → wallet `TravelDocument`.
 *
 * `parseMrz()` returns the canonical ICAO 9303 fields. The wallet
 * surfaces (`PassStack`, `DocumentCard`) read from
 * `userStore.documents` which uses a friendlier `TravelDocument`
 * shape — country/flag in display form, masked number, status
 * derived from expiry. This module encapsulates that translation
 * (and the `id` derivation) so the scanner doesn't have to inline
 * the rules.
 */
import { resolveCountry, iso2ToFlag } from "@/lib/countries";
import type { MrzFields } from "@/lib/mrzParser";
import type { DocumentKind } from "@/lib/mrzParser";
import type { TravelDocument } from "@/store/userStore";

/**
 * Today as `YYYY-MM-DD` (UTC). Exported for tests.
 */
export function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10);
}

/** Stable ID derived from the document number so re-scans are idempotent. */
function travelDocumentId(kind: DocumentKind, fields: MrzFields): string {
  const digest = `${kind}-${fields.documentNumber}-${fields.dateOfExpiry}`;
  // Strip non-alphanum to stay URL-safe and human-debuggable.
  const slug = digest.replace(/[^a-z0-9-]/gi, "").toLowerCase();
  return `td-mrz-${slug}`;
}

/** TravelDocument.type the wallet supports. MRZ doesn't issue boarding passes. */
function mapKindToWalletType(kind: DocumentKind): TravelDocument["type"] | null {
  if (kind === "passport") return "passport";
  if (kind === "visa") return "visa";
  if (kind === "id_card") return "passport"; // closest visual analogue
  return null;
}

function deriveStatus(expiryIso: string, today = todayIsoDate()): TravelDocument["status"] {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(expiryIso)) return "pending";
  return expiryIso < today ? "expired" : "active";
}

function buildLabel(kind: DocumentKind, country: string, name: string): string {
  const k = kind === "passport" ? "Passport" : kind === "visa" ? "Visa" : "ID";
  // "Indian Passport — Devansh Barai" / "United States Visa — Jane Doe".
  if (name) return `${country} ${k} — ${name}`;
  return `${country} ${k}`;
}

/** Mask `documentNumber` for display: first 1 + bullet x4 + last 2. */
export function maskDocumentNumber(raw: string): string {
  const trimmed = raw.replace(/\s+/g, "");
  if (trimmed.length <= 4) return trimmed;
  const head = trimmed.slice(0, 1);
  const tail = trimmed.slice(-2);
  return `${head}••••${tail}`;
}

export interface MrzToDocumentInput {
  kind: DocumentKind;
  fields: MrzFields;
}

/**
 * Convert MRZ output into a wallet TravelDocument. Returns `null` when
 * the document type isn't representable (e.g. classifier returned
 * `unknown`) so the caller can fall back to encrypted-vault-only
 * storage.
 */
export function mrzFieldsToTravelDocument(
  input: MrzToDocumentInput,
  todayOverride?: string,
): TravelDocument | null {
  const walletType = mapKindToWalletType(input.kind);
  if (!walletType) return null;

  const issuing = resolveCountry(input.fields.issuingCountry);
  const nationality = resolveCountry(input.fields.nationality);

  // Issuing country wins for visas (US visa issued to an Indian
  // national → "United States Visa"). Passport: nationality.
  const country =
    input.kind === "visa" ? issuing.name : nationality.name || issuing.name;
  const flag =
    input.kind === "visa" ? issuing.flag : nationality.flag || issuing.flag;

  const fullName = [input.fields.givenNames, input.fields.surname]
    .filter(Boolean)
    .map((s) => s.trim())
    .filter(Boolean)
    .join(" ")
    .trim();

  return {
    id: travelDocumentId(input.kind, input.fields),
    type: walletType,
    label: buildLabel(input.kind, country, fullName),
    country,
    countryFlag: flag || iso2ToFlag(issuing.iso2),
    number: maskDocumentNumber(input.fields.documentNumber),
    issueDate: todayOverride ?? todayIsoDate(),
    expiryDate: input.fields.dateOfExpiry,
    status: deriveStatus(input.fields.dateOfExpiry, todayOverride),
  };
}
