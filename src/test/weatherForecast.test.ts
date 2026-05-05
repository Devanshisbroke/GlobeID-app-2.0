import { describe, it, expect, beforeEach } from "vitest";
import {
  fetchDailyForecast,
  shiftIsoDate,
  emojiForWeatherCode,
  describeWeatherCode,
  __resetWeatherCache,
} from "@/lib/weatherForecast";

describe("weatherForecast", () => {
  beforeEach(() => __resetWeatherCache());

  describe("describeWeatherCode", () => {
    it("returns human-readable strings for known WMO codes", () => {
      expect(describeWeatherCode(0)).toBe("Clear sky");
      expect(describeWeatherCode(63)).toBe("Rain");
      expect(describeWeatherCode(95)).toBe("Thunderstorm");
    });
    it("falls back to a placeholder for unknown codes", () => {
      expect(describeWeatherCode(9999)).toBe("—");
    });
  });

  describe("emojiForWeatherCode", () => {
    it("maps WMO ranges to emojis", () => {
      expect(emojiForWeatherCode(0)).toBe("☀️");
      expect(emojiForWeatherCode(3)).toBe("☁️");
      expect(emojiForWeatherCode(63)).toBe("🌧️");
      expect(emojiForWeatherCode(95)).toBe("⛈️");
    });
  });

  describe("shiftIsoDate", () => {
    it("shifts the date by N days", () => {
      expect(shiftIsoDate("2026-01-30", 3)).toBe("2026-02-02");
      expect(shiftIsoDate("2026-01-01", -1)).toBe("2025-12-31");
    });
    it("returns the original on invalid input", () => {
      expect(shiftIsoDate("invalid", 3)).toBe("invalid");
    });
  });

  describe("fetchDailyForecast", () => {
    it("returns null on a non-OK response", async () => {
      const fakeFetch = (async () => ({
        ok: false,
        status: 500,
        json: async () => ({}),
      })) as unknown as typeof fetch;
      const r = await fetchDailyForecast(
        { lat: 1.3521, lng: 103.8198, startDate: "2026-02-01", endDate: "2026-02-03" },
        { fetchImpl: fakeFetch },
      );
      expect(r).toBeNull();
    });

    it("parses an Open-Meteo daily payload", async () => {
      const payload = {
        daily: {
          time: ["2026-02-01", "2026-02-02", "2026-02-03"],
          temperature_2m_max: [29, 30, 28],
          temperature_2m_min: [24, 25, 23],
          precipitation_sum: [0, 2, 8],
          weather_code: [0, 1, 63],
        },
      };
      const fakeFetch = (async () => ({
        ok: true,
        status: 200,
        json: async () => payload,
      })) as unknown as typeof fetch;
      const r = await fetchDailyForecast(
        { lat: 1.3521, lng: 103.8198, startDate: "2026-02-01", endDate: "2026-02-03" },
        { fetchImpl: fakeFetch, now: () => 1_000_000 },
      );
      expect(r).not.toBeNull();
      expect(r!.source).toBe("live");
      expect(r!.daily).toHaveLength(3);
      expect(r!.daily[2]!.summary).toBe("Rain");
    });

    it("dedupes a second call within the TTL via in-memory cache", async () => {
      const payload = {
        daily: {
          time: ["2026-02-01"],
          temperature_2m_max: [29],
          temperature_2m_min: [24],
          precipitation_sum: [0],
          weather_code: [0],
        },
      };
      let calls = 0;
      const fakeFetch = (async () => {
        calls += 1;
        return {
          ok: true,
          status: 200,
          json: async () => payload,
        } as Response;
      }) as unknown as typeof fetch;
      const args = {
        lat: 1.3521,
        lng: 103.8198,
        startDate: "2026-02-01",
        endDate: "2026-02-01",
      };
      const a = await fetchDailyForecast(args, {
        fetchImpl: fakeFetch,
        now: () => 1_000_000,
      });
      const b = await fetchDailyForecast(args, {
        fetchImpl: fakeFetch,
        now: () => 1_000_000 + 60_000,
      });
      expect(calls).toBe(1);
      expect(a!.source).toBe("live");
      expect(b!.source).toBe("cache");
    });
  });
});
