/**
 * Slice-B Phase-11 — visa catalog.
 *
 * Curated subset; real B2B visa-API integration would replace this. Each
 * row is a (citizenshipCountry × destinationCountry) pair with the
 * canonical visa policy at the time of writing. Pricing is in USD.
 */

export type VisaPolicyKind =
  | "visa_free"
  | "visa_on_arrival"
  | "evisa"
  | "consulate"
  | "not_admitted";

export interface VisaPolicy {
  /** ISO-2 country code of the traveller's nationality. */
  citizenshipIso2: string;
  /** ISO-2 country code of the destination. */
  destinationIso2: string;
  destinationName: string;
  kind: VisaPolicyKind;
  /** Maximum stay in days (null when not relevant — e.g. 'not_admitted'). */
  maxStayDays: number | null;
  /** Estimated processing time in business days (null when 'visa_free'). */
  processingDays: number | null;
  /** Government fee in USD (0 for free / visa-free). */
  feeUsd: number;
  requirements: string[];
  /** Source citation — kept honest. */
  source: string;
}

export const visaCatalog: VisaPolicy[] = [
  // Indian passport holders
  { citizenshipIso2: "IN", destinationIso2: "AE", destinationName: "United Arab Emirates", kind: "visa_on_arrival", maxStayDays: 60, processingDays: 1, feeUsd: 100, requirements: ["Passport (6mo validity)", "Confirmed return ticket", "Hotel booking"], source: "icp.gov.ae" },
  { citizenshipIso2: "IN", destinationIso2: "TH", destinationName: "Thailand", kind: "visa_on_arrival", maxStayDays: 15, processingDays: 1, feeUsd: 60, requirements: ["Passport", "Return ticket", "Proof of THB 10,000 funds"], source: "thaiembassy.com" },
  { citizenshipIso2: "IN", destinationIso2: "SG", destinationName: "Singapore", kind: "evisa", maxStayDays: 30, processingDays: 3, feeUsd: 30, requirements: ["Passport", "Photo", "Bank statement", "Cover letter"], source: "ica.gov.sg" },
  { citizenshipIso2: "IN", destinationIso2: "US", destinationName: "United States", kind: "consulate", maxStayDays: 180, processingDays: 21, feeUsd: 185, requirements: ["DS-160", "Interview at embassy", "Proof of ties to home country", "Bank statements"], source: "travel.state.gov" },
  { citizenshipIso2: "IN", destinationIso2: "GB", destinationName: "United Kingdom", kind: "consulate", maxStayDays: 180, processingDays: 15, feeUsd: 130, requirements: ["Online application", "Biometrics", "Proof of funds (£3000+)", "Travel insurance"], source: "gov.uk" },
  { citizenshipIso2: "IN", destinationIso2: "JP", destinationName: "Japan", kind: "consulate", maxStayDays: 90, processingDays: 5, feeUsd: 25, requirements: ["Passport", "Itinerary", "Bank statement (₹1L+)", "ITR"], source: "in.emb-japan.go.jp" },
  { citizenshipIso2: "IN", destinationIso2: "DE", destinationName: "Germany", kind: "consulate", maxStayDays: 90, processingDays: 12, feeUsd: 90, requirements: ["Schengen application", "Travel insurance €30k+", "Hotel + flight bookings", "Bank statement (last 3 months)"], source: "india.diplo.de" },
  { citizenshipIso2: "IN", destinationIso2: "FR", destinationName: "France", kind: "consulate", maxStayDays: 90, processingDays: 12, feeUsd: 90, requirements: ["Schengen application", "Travel insurance €30k+", "Itinerary", "Bank statement"], source: "france-visas.gouv.fr" },
  { citizenshipIso2: "IN", destinationIso2: "MY", destinationName: "Malaysia", kind: "evisa", maxStayDays: 30, processingDays: 2, feeUsd: 25, requirements: ["Passport", "Photo", "Return ticket", "Hotel booking"], source: "imi.gov.my" },
  { citizenshipIso2: "IN", destinationIso2: "ID", destinationName: "Indonesia", kind: "visa_on_arrival", maxStayDays: 30, processingDays: 1, feeUsd: 35, requirements: ["Passport", "Return ticket", "Hotel"], source: "imigrasi.go.id" },
  { citizenshipIso2: "IN", destinationIso2: "TR", destinationName: "Turkey", kind: "evisa", maxStayDays: 30, processingDays: 1, feeUsd: 50, requirements: ["Passport", "Hotel booking"], source: "evisa.gov.tr" },

  // US passport holders
  { citizenshipIso2: "US", destinationIso2: "GB", destinationName: "United Kingdom", kind: "visa_free", maxStayDays: 180, processingDays: null, feeUsd: 0, requirements: ["Valid passport"], source: "gov.uk" },
  { citizenshipIso2: "US", destinationIso2: "DE", destinationName: "Germany", kind: "visa_free", maxStayDays: 90, processingDays: null, feeUsd: 0, requirements: ["Valid passport"], source: "schengenvisainfo.com" },
  { citizenshipIso2: "US", destinationIso2: "JP", destinationName: "Japan", kind: "visa_free", maxStayDays: 90, processingDays: null, feeUsd: 0, requirements: ["Valid passport"], source: "mofa.go.jp" },
  { citizenshipIso2: "US", destinationIso2: "IN", destinationName: "India", kind: "evisa", maxStayDays: 60, processingDays: 4, feeUsd: 25, requirements: ["e-Visa application", "Photo", "Passport scan"], source: "indianvisaonline.gov.in" },
  { citizenshipIso2: "US", destinationIso2: "AE", destinationName: "United Arab Emirates", kind: "visa_on_arrival", maxStayDays: 30, processingDays: 1, feeUsd: 0, requirements: ["Valid passport (6mo)", "Return ticket"], source: "icp.gov.ae" },
  { citizenshipIso2: "US", destinationIso2: "CN", destinationName: "China", kind: "consulate", maxStayDays: 60, processingDays: 7, feeUsd: 140, requirements: ["Application form", "Passport", "Photo", "Interview at consulate"], source: "china-embassy.gov.cn" },

  // UK passport holders
  { citizenshipIso2: "GB", destinationIso2: "DE", destinationName: "Germany", kind: "visa_free", maxStayDays: 90, processingDays: null, feeUsd: 0, requirements: ["Valid passport"], source: "schengenvisainfo.com" },
  { citizenshipIso2: "GB", destinationIso2: "US", destinationName: "United States", kind: "evisa", maxStayDays: 90, processingDays: 3, feeUsd: 21, requirements: ["ESTA application", "Valid passport"], source: "esta.cbp.dhs.gov" },
  { citizenshipIso2: "GB", destinationIso2: "IN", destinationName: "India", kind: "evisa", maxStayDays: 60, processingDays: 4, feeUsd: 10, requirements: ["e-Visa application", "Photo"], source: "indianvisaonline.gov.in" },
  { citizenshipIso2: "GB", destinationIso2: "AE", destinationName: "United Arab Emirates", kind: "visa_on_arrival", maxStayDays: 30, processingDays: 1, feeUsd: 0, requirements: ["Valid passport"], source: "icp.gov.ae" },
];

export function findVisaPolicy(
  citizenshipIso2: string,
  destinationIso2: string,
): VisaPolicy | null {
  const cIso = citizenshipIso2.toUpperCase();
  const dIso = destinationIso2.toUpperCase();
  return visaCatalog.find(
    (v) => v.citizenshipIso2 === cIso && v.destinationIso2 === dIso,
  ) ?? null;
}
