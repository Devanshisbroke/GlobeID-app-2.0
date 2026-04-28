import { z } from "zod";

/**
 * Slice-B — weather (Open-Meteo).
 *
 * Open-Meteo is a free, keyless forecast API. The server proxies it so we
 * can rate-limit / cache, and so the client never needs network access to
 * a third-party host.
 *
 * https://open-meteo.com/en/docs
 */

export const weatherKindEnum = z.enum([
  "clear",
  "partly_cloudy",
  "cloudy",
  "fog",
  "drizzle",
  "rain",
  "snow",
  "thunderstorm",
  "unknown",
]);
export type WeatherKind = z.infer<typeof weatherKindEnum>;

export const weatherDayForecastSchema = z.object({
  /** ISO YYYY-MM-DD date in the location's local timezone. */
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  tempMaxC: z.number(),
  tempMinC: z.number(),
  precipitationMm: z.number().min(0),
  windKph: z.number().min(0),
  kind: weatherKindEnum,
  /** Open-Meteo's raw WMO weather code (0..99). */
  weatherCode: z.number().int().min(0).max(100),
});
export type WeatherDayForecast = z.infer<typeof weatherDayForecastSchema>;

export const weatherForecastSchema = z.object({
  iata: z.string().length(3),
  city: z.string(),
  country: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  timezone: z.string(),
  days: z.array(weatherDayForecastSchema),
  /** ISO timestamp from the upstream provider (when the forecast was generated). */
  generatedAt: z.string(),
  /** Always set on real data. Distinguishes from any future demo/fallback path. */
  source: z.literal("open-meteo"),
});
export type WeatherForecast = z.infer<typeof weatherForecastSchema>;
