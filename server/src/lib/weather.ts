import type { WeatherForecast, WeatherKind } from "../../../shared/types/weather.js";

/**
 * Slice-B Phase-15 — Open-Meteo proxy.
 *
 * Open-Meteo: free, keyless, no auth. https://open-meteo.com/en/docs
 * The server proxies + caches so the client never needs network access
 * to a third-party host (and we can rate-limit per user).
 */

export const OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast";

export interface OpenMeteoDailyResponse {
  latitude: number;
  longitude: number;
  timezone: string;
  generationtime_ms?: number;
  daily?: {
    time: string[];
    temperature_2m_max: number[];
    temperature_2m_min: number[];
    precipitation_sum: number[];
    weathercode: number[];
    windspeed_10m_max?: number[];
  };
}

export function weatherKindFromCode(code: number): WeatherKind {
  if (code === 0) return "clear";
  if (code === 1 || code === 2) return "partly_cloudy";
  if (code === 3) return "cloudy";
  if (code >= 45 && code <= 48) return "fog";
  if (code >= 51 && code <= 57) return "drizzle";
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return "rain";
  if (code >= 71 && code <= 77 || code === 85 || code === 86) return "snow";
  if (code >= 95) return "thunderstorm";
  return "unknown";
}

export function parseOpenMeteo(
  data: OpenMeteoDailyResponse,
  meta: { iata: string; city: string; country: string },
): WeatherForecast {
  const daily = data.daily ?? {
    time: [],
    temperature_2m_max: [],
    temperature_2m_min: [],
    precipitation_sum: [],
    weathercode: [],
    windspeed_10m_max: [],
  };
  const days = daily.time.map((d, i) => ({
    date: d,
    tempMaxC: daily.temperature_2m_max?.[i] ?? 0,
    tempMinC: daily.temperature_2m_min?.[i] ?? 0,
    precipitationMm: daily.precipitation_sum?.[i] ?? 0,
    windKph: daily.windspeed_10m_max?.[i] ?? 0,
    weatherCode: daily.weathercode?.[i] ?? 0,
    kind: weatherKindFromCode(daily.weathercode?.[i] ?? 0),
  }));
  return {
    iata: meta.iata,
    city: meta.city,
    country: meta.country,
    latitude: data.latitude,
    longitude: data.longitude,
    timezone: data.timezone,
    days,
    generatedAt: new Date().toISOString(),
    source: "open-meteo",
  };
}

export async function fetchOpenMeteo(
  lat: number,
  lng: number,
  days: number,
): Promise<OpenMeteoDailyResponse> {
  const url = new URL(OPEN_METEO_URL);
  url.searchParams.set("latitude", lat.toFixed(4));
  url.searchParams.set("longitude", lng.toFixed(4));
  url.searchParams.set(
    "daily",
    "temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,windspeed_10m_max",
  );
  url.searchParams.set("forecast_days", String(Math.max(1, Math.min(16, days))));
  url.searchParams.set("timezone", "auto");
  const res = await fetch(url, { headers: { "user-agent": "globe-id-app/1.0 (+slice-b)" } });
  if (!res.ok) {
    throw new Error(`open-meteo upstream error: ${res.status} ${res.statusText}`);
  }
  return (await res.json()) as OpenMeteoDailyResponse;
}
