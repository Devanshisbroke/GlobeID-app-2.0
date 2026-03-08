export type VisaStatus = "visaFree" | "visaOnArrival" | "eVisa" | "visaRequired";

export interface VisaRequirement {
  status: VisaStatus;
  label: string;
  color: string;
  durationAllowed?: string;
  notes?: string;
}

const visaStatusLabels: Record<VisaStatus, { label: string; color: string }> = {
  visaFree: { label: "Visa Free", color: "text-accent" },
  visaOnArrival: { label: "Visa on Arrival", color: "text-primary" },
  eVisa: { label: "e-Visa Available", color: "text-neon-amber" },
  visaRequired: { label: "Visa Required", color: "text-destructive" },
};

// Mock visa rules: originCountry → destinationCountry → VisaStatus
const visaRules: Record<string, Record<string, { status: VisaStatus; duration?: string; notes?: string }>> = {
  India: {
    Thailand: { status: "visaOnArrival", duration: "15 days", notes: "Extendable for 7 days" },
    Japan: { status: "visaRequired", duration: "Up to 90 days", notes: "Apply at embassy or consulate" },
    Indonesia: { status: "visaFree", duration: "30 days", notes: "Tourist purposes only" },
    Singapore: { status: "visaRequired", duration: "30 days", notes: "E-visa also available" },
    UAE: { status: "visaOnArrival", duration: "14 days", notes: "Free visa on arrival" },
    "United States": { status: "visaRequired", duration: "Up to 10 years", notes: "B1/B2 visa required" },
    "United Kingdom": { status: "visaRequired", duration: "6 months", notes: "Standard visitor visa" },
    France: { status: "visaRequired", duration: "90 days", notes: "Schengen visa required" },
    Germany: { status: "visaRequired", duration: "90 days", notes: "Schengen visa required" },
    Nepal: { status: "visaFree", duration: "Unlimited", notes: "No visa needed for Indian nationals" },
    "Sri Lanka": { status: "eVisa", duration: "30 days", notes: "Apply online before travel" },
    Maldives: { status: "visaOnArrival", duration: "30 days", notes: "Free tourist visa" },
    Malaysia: { status: "eVisa", duration: "30 days", notes: "eNTRI or eVisa" },
    Australia: { status: "visaRequired", duration: "Up to 12 months", notes: "Apply online (eVisitor)" },
    Canada: { status: "visaRequired", duration: "Up to 6 months", notes: "Temporary resident visa" },
    Brazil: { status: "visaFree", duration: "90 days", notes: "No visa required since 2024" },
    Turkey: { status: "eVisa", duration: "30 days", notes: "Apply at evisa.gov.tr" },
    Kenya: { status: "eVisa", duration: "90 days", notes: "Apply online before travel" },
    "South Korea": { status: "visaRequired", duration: "90 days", notes: "Single entry visa" },
    Qatar: { status: "visaOnArrival", duration: "30 days", notes: "Free visa on arrival" },
    Egypt: { status: "visaOnArrival", duration: "30 days", notes: "Available at airports" },
    "New Zealand": { status: "visaRequired", duration: "9 months", notes: "Visitor visa required" },
    "South Africa": { status: "visaRequired", duration: "30 days", notes: "Apply at embassy" },
  },
  "United States": {
    Japan: { status: "visaFree", duration: "90 days", notes: "Visa waiver program" },
    Singapore: { status: "visaFree", duration: "90 days", notes: "No visa needed" },
    Thailand: { status: "visaFree", duration: "30 days", notes: "Visa exemption" },
    India: { status: "visaRequired", duration: "Up to 10 years", notes: "Tourist/business e-visa available" },
    "United Kingdom": { status: "visaFree", duration: "6 months", notes: "No visa for tourism" },
    France: { status: "visaFree", duration: "90 days", notes: "Schengen area" },
    UAE: { status: "visaFree", duration: "30 days", notes: "Visa on arrival" },
    Indonesia: { status: "visaOnArrival", duration: "30 days", notes: "Paid visa on arrival" },
    Brazil: { status: "visaFree", duration: "90 days", notes: "No visa required" },
    Australia: { status: "eVisa", duration: "90 days", notes: "ETA required" },
  },
};

export function getVisaRequirement(originCountry: string, destinationCountry: string): VisaRequirement {
  if (originCountry === destinationCountry) {
    return { status: "visaFree", label: "Home Country", color: "text-accent", durationAllowed: "Unlimited" };
  }

  const originRules = visaRules[originCountry];
  if (originRules) {
    const rule = originRules[destinationCountry];
    if (rule) {
      const meta = visaStatusLabels[rule.status];
      return {
        status: rule.status,
        label: meta.label,
        color: meta.color,
        durationAllowed: rule.duration,
        notes: rule.notes,
      };
    }
  }

  // Default: visa required for unknown combinations
  return {
    status: "visaRequired",
    label: "Visa Required",
    color: "text-destructive",
    notes: "Check embassy for details",
  };
}

// Helper: get all visa-free destinations for a nationality
export function getVisaFreeDestinations(nationality: string): string[] {
  const rules = visaRules[nationality];
  if (!rules) return [];
  return Object.entries(rules)
    .filter(([, r]) => r.status === "visaFree" || r.status === "visaOnArrival")
    .map(([country]) => country);
}
