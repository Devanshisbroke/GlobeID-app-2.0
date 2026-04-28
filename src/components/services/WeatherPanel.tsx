import React, { useEffect, useState } from "react";
import { Cloud, CloudDrizzle, CloudFog, CloudLightning, CloudSnow, Loader2, Sun, CloudRain } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useWeatherStore } from "@/store/weatherStore";
import type { WeatherKind } from "@shared/types/weather";

const KIND_ICON: Record<WeatherKind, React.ElementType> = {
  clear: Sun,
  partly_cloudy: Cloud,
  cloudy: Cloud,
  fog: CloudFog,
  drizzle: CloudDrizzle,
  rain: CloudRain,
  snow: CloudSnow,
  thunderstorm: CloudLightning,
  unknown: Cloud,
};

const WeatherPanel: React.FC = () => {
  const byIata = useWeatherStore((s) => s.byIata);
  const loading = useWeatherStore((s) => s.loading);
  const lastError = useWeatherStore((s) => s.lastError);
  const fetchFor = useWeatherStore((s) => s.fetchFor);
  const [iata, setIata] = useState("LHR");

  useEffect(() => {
    void fetchFor(iata);
    // only on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const code = iata.toUpperCase();
  const entry = byIata[code];
  const isLoading = loading.has(code);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Forecast lookup</p>
        <div className="flex gap-2">
          <Input
            value={iata}
            onChange={(e) => setIata(e.target.value.toUpperCase().slice(0, 3))}
            placeholder="IATA (e.g. LHR)"
            className="text-xs font-mono uppercase"
          />
          <Button size="sm" onClick={() => void fetchFor(code, 7, true)} disabled={isLoading}>
            {isLoading ? <Loader2 className="w-3 h-3 animate-spin" /> : "Fetch"}
          </Button>
        </div>
        {lastError && <p className="text-[11px] text-destructive">{lastError}</p>}
      </GlassCard>

      {entry && (
        <GlassCard className="p-4">
          <div className="flex items-center justify-between mb-2">
            <p className="text-sm font-bold text-foreground">
              {entry.forecast.city}, {entry.forecast.country}
            </p>
            <p className="text-[10px] text-muted-foreground font-mono">{entry.forecast.timezone}</p>
          </div>
          <div className="grid grid-cols-7 gap-2">
            {entry.forecast.days.slice(0, 7).map((d) => {
              const Icon = KIND_ICON[d.kind];
              return (
                <div key={d.date} className="flex flex-col items-center text-center">
                  <p className="text-[10px] text-muted-foreground">{d.date.slice(5)}</p>
                  <Icon className="w-5 h-5 text-foreground my-1" />
                  <p className="text-[11px] font-semibold text-foreground">{Math.round(d.tempMaxC)}°</p>
                  <p className="text-[10px] text-muted-foreground">{Math.round(d.tempMinC)}°</p>
                </div>
              );
            })}
          </div>
          <p className="text-[10px] text-muted-foreground mt-3 text-right">
            source: open-meteo · {new Date(entry.forecast.generatedAt).toLocaleTimeString()}
          </p>
        </GlassCard>
      )}
    </div>
  );
};

export default React.memo(WeatherPanel);
