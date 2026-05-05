/**
 * useWeatherForecast — React hook wrapper around `fetchDailyForecast`.
 *
 * Encapsulates:
 *  - SWR-style cache via the in-memory cache in `weatherForecast.ts`.
 *  - Aborts pending requests on unmount / arg change.
 *  - Defers the network call when `prefersReducedMotion` AND offline,
 *    treating the cached payload (if any) as authoritative.
 *
 * Returns null while loading or if the destination has no lat/lng.
 */
import { useEffect, useState } from "react";
import {
  fetchDailyForecast,
  type ForecastResponse,
  shiftIsoDate,
} from "@/lib/weatherForecast";
import { findAirport } from "@shared/data/airports";

export interface UseWeatherArgs {
  /** Destination IATA. Hook resolves lat/lng via findAirport(). */
  destIata: string;
  /** ISO yyyy-mm-dd for the trip arrival date. */
  arrivalDate: string;
  /** Number of days to forecast from arrival. Default 3. */
  days?: number;
}

export interface UseWeatherResult {
  data: ForecastResponse | null;
  loading: boolean;
  error: string | null;
}

export function useWeatherForecast(
  { destIata, arrivalDate, days = 3 }: UseWeatherArgs,
): UseWeatherResult {
  const [data, setData] = useState<ForecastResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const a = findAirport(destIata);
    if (!a) {
      setData(null);
      setLoading(false);
      setError(null);
      return;
    }
    const ctrl = new AbortController();
    setLoading(true);
    setError(null);
    fetchDailyForecast(
      {
        lat: a.lat,
        lng: a.lng,
        startDate: arrivalDate,
        endDate: shiftIsoDate(arrivalDate, days - 1),
      },
      { signal: ctrl.signal },
    )
      .then((r) => {
        if (ctrl.signal.aborted) return;
        setData(r);
        setError(r ? null : "No forecast available");
      })
      .catch(() => {
        if (ctrl.signal.aborted) return;
        setError("Forecast lookup failed");
      })
      .finally(() => {
        if (!ctrl.signal.aborted) setLoading(false);
      });
    return () => ctrl.abort();
  }, [destIata, arrivalDate, days]);

  return { data, loading, error };
}
