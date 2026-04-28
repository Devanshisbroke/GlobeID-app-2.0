/**
 * Slice-B — single read hook surfacing the intelligence engines to React.
 *
 * Subscribes to all the source stores via shallow Zustand selectors so the
 * memoised result only re-evaluates when an input actually changes. The
 * engines themselves are pure, so React can safely call them inside
 * `useMemo` without effects.
 *
 * Returns: `{ context, services }` where:
 *  - `context` is the `ContextResult` from `evaluateContext()`
 *  - `services` is the ranked tab list from `rankServices()`
 *
 * The hook does NOT trigger hydration. Callers should still call each
 * store's `hydrate()` (Home, AppChromeV2). This hook is a pure projection.
 */
import { useMemo } from "react";
import { useShallow } from "zustand/react/shallow";
import { useLifecycleStore } from "@/store/lifecycleStore";
import { useWeatherStore } from "@/store/weatherStore";
import { useScoreStore } from "@/store/scoreStore";
import { useLoyaltyStore } from "@/store/loyaltyStore";
import { useBudgetStore } from "@/store/budgetStore";
import { useFraudStore } from "@/store/fraudStore";
import { useWalletStore } from "@/store/walletStore";
import { useSafetyStore } from "@/store/safetyStore";
import { evaluateContext, type ContextResult } from "./contextEngine";
import { rankServices, type ServiceRanking } from "./serviceEngine";
import { msUntilTripStart, nextLeg } from "./travelEngine";

const DAY = 24 * 60 * 60_000;

const IATA_TO_ISO: Record<string, string> = {
  SIN: "SG",
  HND: "JP",
  NRT: "JP",
  LHR: "GB",
  LGW: "GB",
  CDG: "FR",
  FRA: "DE",
  DXB: "AE",
  JFK: "US",
  EWR: "US",
  LAX: "US",
  SFO: "US",
  BKK: "TH",
  BOM: "IN",
  DEL: "IN",
  HKG: "HK",
  ICN: "KR",
  SYD: "AU",
  AMS: "NL",
  IST: "TR",
};

export interface IntelligenceResult {
  context: ContextResult;
  services: ServiceRanking[];
}

export function useIntelligence(): IntelligenceResult {
  const lifecycle = useLifecycleStore(
    useShallow((s) => ({ trips: s.trips, flightStatuses: s.flightStatuses })),
  );
  const weatherByIata = useWeatherStore((s) => s.byIata);
  const score = useScoreStore((s) => s.score);
  const loyalty = useLoyaltyStore((s) => s.snapshot);
  const budget = useBudgetStore((s) => s.snapshot);
  const fraudFindings = useFraudStore((s) => s.findings);
  const wallet = useWalletStore(
    useShallow((s) => ({ balances: s.balances, activeCountry: s.activeCountry })),
  );
  const contactsCount = useSafetyStore((s) => s.contacts.length);

  return useMemo(() => {
    const now = Date.now();
    const context = evaluateContext({
      now,
      trips: lifecycle.trips,
      flightStatuses: lifecycle.flightStatuses,
      weatherByIata,
      score,
      loyalty,
      budget,
      fraudFindings,
      walletBalances: wallet.balances,
      emergencyContactsCount: contactsCount,
      activeCountryIso2: wallet.activeCountry,
    });
    const upcoming =
      lifecycle.trips.find((t) => t.state === "active") ??
      lifecycle.trips
        .filter((t) => t.state === "booked" || t.state === "planning")
        .sort((a, b) => msUntilTripStart(a, now) - msUntilTripStart(b, now))[0] ??
      null;
    const nextDestIso2 = upcoming
      ? IATA_TO_ISO[(nextLeg(upcoming)?.toIata ?? "").toUpperCase()] ?? null
      : null;
    const days = upcoming ? msUntilTripStart(upcoming, now) / DAY : Number.POSITIVE_INFINITY;
    const services = rankServices({
      activeCountryIso2: wallet.activeCountry,
      nextTrip: upcoming,
      nextDestinationIso2: nextDestIso2,
      budget,
      daysToNextTrip: Number.isFinite(days) ? days : Number.POSITIVE_INFINITY,
    });
    return { context, services };
  }, [
    lifecycle.trips,
    lifecycle.flightStatuses,
    weatherByIata,
    score,
    loyalty,
    budget,
    fraudFindings,
    wallet.balances,
    wallet.activeCountry,
    contactsCount,
  ]);
}
