/**
 * Ground transport deep-links (BACKLOG D 49).
 *
 * Given a destination IATA, expose the ride-hail providers active in
 * that market with a `geo:` / app deep-link the user can tap from
 * TripDetail.
 *
 * Coverage table is curated, not crowdsourced. Each entry maps
 * (countryIso → provider list). Default = uber + bolt + local taxi.
 */

import { getAirport } from "@/lib/airports";

export type RideProvider =
  | "uber"
  | "lyft"
  | "bolt"
  | "ola"
  | "didi"
  | "grab"
  | "freenow"
  | "kakao_t"
  | "careem";

interface ProviderDef {
  id: RideProvider;
  label: string;
  /** App deep-link template; supports {lat}/{lng} substitution. */
  deepLink: (args: { lat: number; lng: number; label?: string }) => string;
  /** Web fallback (works on every device). */
  webLink: (args: { lat: number; lng: number; label?: string }) => string;
  /** Tone for UI badge. */
  tone: "primary" | "accent" | "neutral";
}

const PROVIDER_DEF: Record<RideProvider, ProviderDef> = {
  uber: {
    id: "uber",
    label: "Uber",
    deepLink: ({ lat, lng }) =>
      `uber://?action=setPickup&pickup=my_location&dropoff[latitude]=${lat}&dropoff[longitude]=${lng}`,
    webLink: ({ lat, lng }) =>
      `https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=${lat}&dropoff[longitude]=${lng}`,
    tone: "primary",
  },
  lyft: {
    id: "lyft",
    label: "Lyft",
    deepLink: ({ lat, lng }) =>
      `lyft://ridetype?id=lyft&destination[latitude]=${lat}&destination[longitude]=${lng}`,
    webLink: ({ lat, lng }) => `https://ride.lyft.com/ridetype?destination[latitude]=${lat}&destination[longitude]=${lng}`,
    tone: "accent",
  },
  bolt: {
    id: "bolt",
    label: "Bolt",
    deepLink: ({ lat, lng }) => `bolt://action/setDestination?destinationLatitude=${lat}&destinationLongitude=${lng}`,
    webLink: ({ lat, lng }) => `https://bolt.eu/?destinationLat=${lat}&destinationLng=${lng}`,
    tone: "neutral",
  },
  ola: {
    id: "ola",
    label: "Ola",
    deepLink: ({ lat, lng }) => `olacabs://app/launch?drop_lat=${lat}&drop_lng=${lng}`,
    webLink: ({ lat, lng }) => `https://book.olacabs.com/?drop_lat=${lat}&drop_lng=${lng}`,
    tone: "neutral",
  },
  didi: {
    id: "didi",
    label: "DiDi",
    deepLink: ({ lat, lng }) => `didi://order?lat=${lat}&lng=${lng}`,
    webLink: () => `https://www.didiglobal.com/`,
    tone: "neutral",
  },
  grab: {
    id: "grab",
    label: "Grab",
    deepLink: ({ lat, lng }) => `grab://open?screenType=BOOKING&dropOffLatitude=${lat}&dropOffLongitude=${lng}`,
    webLink: () => `https://www.grab.com/`,
    tone: "neutral",
  },
  freenow: {
    id: "freenow",
    label: "FREE NOW",
    deepLink: ({ lat, lng }) => `freenow://destination?lat=${lat}&lng=${lng}`,
    webLink: () => `https://www.free-now.com/`,
    tone: "neutral",
  },
  kakao_t: {
    id: "kakao_t",
    label: "Kakao T",
    deepLink: () => `kakaotaxi://`,
    webLink: () => `https://kakaomobility.com/service/kakaot/`,
    tone: "neutral",
  },
  careem: {
    id: "careem",
    label: "Careem",
    deepLink: ({ lat, lng }) => `careem://booking?dropoff_lat=${lat}&dropoff_lng=${lng}`,
    webLink: () => `https://www.careem.com/`,
    tone: "neutral",
  },
};

const DEFAULT_PROVIDERS: RideProvider[] = ["uber", "bolt"];

const COUNTRY_PROVIDERS: Record<string, RideProvider[]> = {
  // Country names matching `airports.country` from shared/data/airports.ts
  "United States": ["uber", "lyft"],
  Canada: ["uber", "lyft"],
  Mexico: ["uber", "didi"],
  "United Kingdom": ["uber", "bolt", "freenow"],
  Germany: ["uber", "bolt", "freenow"],
  France: ["uber", "bolt", "freenow"],
  Spain: ["uber", "bolt", "freenow"],
  Netherlands: ["uber", "bolt"],
  Switzerland: ["uber", "bolt"],
  Turkey: ["uber", "bolt"],
  Singapore: ["grab"],
  Malaysia: ["grab"],
  Thailand: ["grab", "bolt"],
  Indonesia: ["grab"],
  India: ["uber", "ola"],
  China: ["didi"],
  Japan: ["uber", "didi"],
  "South Korea": ["uber", "kakao_t"],
  UAE: ["uber", "careem"],
  Qatar: ["uber", "careem"],
  Australia: ["uber", "didi"],
  "New Zealand": ["uber"],
  Brazil: ["uber", "didi"],
};

export interface RideOption {
  id: RideProvider;
  label: string;
  deepLink: string;
  webLink: string;
  tone: ProviderDef["tone"];
}

export function ridesForAirport(iata: string): RideOption[] {
  const apt = getAirport(iata);
  if (!apt) return [];
  const ids = COUNTRY_PROVIDERS[apt.country] ?? DEFAULT_PROVIDERS;
  return ids.map((id) => {
    const def = PROVIDER_DEF[id];
    return {
      id,
      label: def.label,
      deepLink: def.deepLink({ lat: apt.lat, lng: apt.lng, label: apt.city }),
      webLink: def.webLink({ lat: apt.lat, lng: apt.lng, label: apt.city }),
      tone: def.tone,
    };
  });
}
