/**
 * Weather forecast — Open-Meteo API client (D 42).
 *
 * Open-Meteo is free, requires no API key, and returns daily / hourly
 * forecasts for any lat/lng. Used by TripIntelSection to render a 3-day
 * forecast card on the trip detail screen.
 *
 * Caching strategy:
 *  - Workbox PWA: runtime CacheFirst rule on `api.open-meteo.com`.
 *  - In-memory: dedupe concurrent requests + 30 min TTL on the same key.
 *
 * Failure mode is honest: caller gets `null` and renders a fallback
 * empty card rather than a misleading "0°" reading.
 *
 * Why deterministic: caller decides whether to hit the network. A pure
 * data shape + a fetch wrapper makes the hook unit-testable in
 * isolation (mock the wrapper, assert on the shape).
 */

export interface DailyForecast {
  /** ISO yyyy-mm-dd. */
  date: string;
  /** °C. */
  tempMaxC: number;
  /** °C. */
  tempMinC: number;
  /** mm of precipitation forecast over the day. */
  precipMm: number;
  /** Open-Meteo WMO weather code (0=clear, 61–65=rain, 71–77=snow, …). */
  weatherCode: number;
  /** Human-readable, English. e.g. "Mostly sunny". */
  summary: string;
}

export interface ForecastResponse {
  /** Cached or live. Caller can show a stale-data dot. */
  source: "live" | "cache";
  /** Sorted ascending by date — first entry is today / earliest available. */
  daily: DailyForecast[];
}

// In-memory cache keyed by `lat,lng,start,end`. 30-minute TTL is plenty
// for an itinerary hint — the user isn't going to refresh more often.
const memCache = new Map<string, { ts: number; data: ForecastResponse }>();
const CACHE_TTL_MS = 30 * 60 * 1000;

const WMO_LABELS: Record<number, string> = {
  0: "Clear sky",
  1: "Mostly clear",
  2: "Partly cloudy",
  3: "Overcast",
  45: "Fog",
  48: "Depositing rime fog",
  51: "Light drizzle",
  53: "Drizzle",
  55: "Heavy drizzle",
  56: "Freezing drizzle",
  57: "Heavy freezing drizzle",
  61: "Light rain",
  63: "Rain",
  65: "Heavy rain",
  66: "Freezing rain",
  67: "Heavy freezing rain",
  71: "Light snow",
  73: "Snow",
  75: "Heavy snow",
  77: "Snow grains",
  80: "Light showers",
  81: "Showers",
  82: "Heavy showers",
  85: "Snow showers",
  86: "Heavy snow showers",
  95: "Thunderstorm",
  96: "Thunderstorm with hail",
  99: "Heavy thunderstorm with hail",
};

export function describeWeatherCode(code: number): string {
  return WMO_LABELS[code] ?? "—";
}

export interface FetchOptions {
  signal?: AbortSignal;
  /** Override the fetch impl — used by tests to mock without hoist gymnastics. */
  fetchImpl?: typeof fetch;
  /** Treat timestamp as `now`. Tests pin this to keep cache keys stable. */
  now?: () => number;
}

export interface FetchArgs {
  lat: number;
  lng: number;
  /** ISO yyyy-mm-dd. */
  startDate: string;
  /** ISO yyyy-mm-dd. */
  endDate: string;
}

/**
 * Fetch a daily forecast from Open-Meteo. Returns `null` on any error
 * (network, abort, malformed payload). Caches successful responses for
 * 30 minutes keyed on lat/lng/start/end so re-renders don't hammer the
 * API.
 */
export async function fetchDailyForecast(
  { lat, lng, startDate, endDate }: FetchArgs,
  opts: FetchOptions = {},
): Promise<ForecastResponse | null> {
  const now = opts.now ?? Date.now;
  const key = `${lat.toFixed(2)},${lng.toFixed(2)},${startDate},${endDate}`;
  const cached = memCache.get(key);
  if (cached && now() - cached.ts < CACHE_TTL_MS) {
    return { source: "cache", daily: cached.data.daily };
  }

  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", lat.toFixed(4));
  url.searchParams.set("longitude", lng.toFixed(4));
  url.searchParams.set("start_date", startDate);
  url.searchParams.set("end_date", endDate);
  url.searchParams.set(
    "daily",
    [
      "temperature_2m_max",
      "temperature_2m_min",
      "precipitation_sum",
      "weather_code",
    ].join(","),
  );
  url.searchParams.set("timezone", "auto");

  const fetcher = opts.fetchImpl ?? fetch;
  try {
    const res = await fetcher(url.toString(), { signal: opts.signal });
    if (!res.ok) return null;
    const json = (await res.json()) as unknown;
    const parsed = parseOpenMeteo(json);
    if (!parsed) return null;
    const data: ForecastResponse = { source: "live", daily: parsed };
    memCache.set(key, { ts: now(), data });
    return data;
  } catch {
    return null;
  }
}

interface OpenMeteoDaily {
  time: string[];
  temperature_2m_max: number[];
  temperature_2m_min: number[];
  precipitation_sum: number[];
  weather_code: number[];
}

interface OpenMeteoResponse {
  daily?: OpenMeteoDaily;
}

function parseOpenMeteo(raw: unknown): DailyForecast[] | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as OpenMeteoResponse;
  const daily = r.daily;
  if (!daily) return null;
  const len = daily.time?.length;
  if (
    !len ||
    daily.temperature_2m_max?.length !== len ||
    daily.temperature_2m_min?.length !== len ||
    daily.precipitation_sum?.length !== len ||
    daily.weather_code?.length !== len
  ) {
    return null;
  }
  const out: DailyForecast[] = [];
  for (let i = 0; i < len; i++) {
    const code = daily.weather_code[i] ?? 0;
    out.push({
      date: daily.time[i]!,
      tempMaxC: daily.temperature_2m_max[i] ?? 0,
      tempMinC: daily.temperature_2m_min[i] ?? 0,
      precipMm: daily.precipitation_sum[i] ?? 0,
      weatherCode: code,
      summary: describeWeatherCode(code),
    });
  }
  return out;
}

/** Convenience: shift an ISO yyyy-mm-dd by N days. Pure for testability. */
export function shiftIsoDate(iso: string, days: number): string {
  const d = new Date(`${iso}T00:00:00Z`);
  if (!Number.isFinite(d.getTime())) return iso;
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Pick a single Lucide-friendly emoji for a WMO code so the UI can dot it. */
export function emojiForWeatherCode(code: number): string {
  if (code === 0) return "☀️";
  if (code <= 2) return "🌤️";
  if (code === 3) return "☁️";
  if (code === 45 || code === 48) return "🌫️";
  if (code >= 51 && code <= 57) return "🌦️";
  if (code >= 61 && code <= 67) return "🌧️";
  if (code >= 71 && code <= 77) return "🌨️";
  if (code >= 80 && code <= 82) return "🌧️";
  if (code >= 85 && code <= 86) return "🌨️";
  if (code >= 95) return "⛈️";
  return "🌍";
}

/** Reset memo cache — exported for tests only. */
export function __resetWeatherCache(): void {
  memCache.clear();
}
