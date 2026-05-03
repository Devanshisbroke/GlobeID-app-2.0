/** Static metadata describing every identity-score factor.
 *  Split out from `ScoreFactorDrawer.tsx` so HMR fast-refresh stays
 *  happy on that component. */
import { ShieldCheck, Globe, Plane, Fingerprint } from "lucide-react";
import type { ComponentType } from "react";

export interface ScoreFactorMeta {
  id: string;
  label: string;
  Icon: ComponentType<{ className?: string }>;
  description: string;
  tips: string[];
}

export const SCORE_FACTOR_META: readonly ScoreFactorMeta[] = [
  {
    id: "documents-verified",
    label: "Documents Verified",
    Icon: ShieldCheck,
    description:
      "Counts the identity documents you've successfully verified — passport, visa, driver's licence, national ID. Each verified document independently raises your trust signal with airlines, hotels, and border agencies.",
    tips: [
      "Scan your passport and visas in the Documents tab",
      "Add a secondary ID (driver's licence) for redundancy",
      "Re-verify documents that approach expiry",
    ],
  },
  {
    id: "countries-visited",
    label: "Countries Visited",
    Icon: Globe,
    description:
      "A measure of your travel breadth. Each new country contributes once — repeat visits don't double-count. Used as a soft signal for premium status programmes and visa-on-arrival eligibility checks.",
    tips: [
      "Scan boarding passes from past trips so they're auto-counted",
      "Add a manual record for trips that pre-date the app",
      "Verify entry stamps via passport scan to lift the multiplier",
    ],
  },
  {
    id: "travel-activity",
    label: "Travel Activity",
    Icon: Plane,
    description:
      "Reflects how recently and frequently you travel. A 90-day rolling window weighted by trip distance and complexity (multi-leg, international vs domestic).",
    tips: [
      "Log a trip every 90 days to keep the rolling window full",
      "International multi-leg trips lift this faster than domestic",
      "Scan your boarding passes so each leg counts",
    ],
  },
  {
    id: "biometric-match",
    label: "Biometric Match",
    Icon: Fingerprint,
    description:
      "Whether your enrolled face/fingerprint biometric matches the photo on your verified primary ID. A binary check — match or mismatch — and the heaviest single contributor to your overall score.",
    tips: [
      "Enrol via Identity → Biometric Setup",
      "Re-enrol if your appearance has changed substantially",
      "Use clear, front-facing lighting during enrolment",
    ],
  },
] as const;
