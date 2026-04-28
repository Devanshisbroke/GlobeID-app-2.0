import React, { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Car } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";

const VEHICLES = ["bike", "auto", "sedan", "suv", "premium"] as const;
type Vehicle = (typeof VEHICLES)[number];

interface Estimate {
  distanceKm: number;
  fareUsd: number;
  etaMinutes: number;
  vehicle: string;
  label: string;
  capacity: number;
  surge: number;
}

const RidesPanel: React.FC = () => {
  const [fromIata, setFromIata] = useState("LHR");
  const [toLat, setToLat] = useState(51.5074);
  const [toLng, setToLng] = useState(-0.1278);
  const [vehicle, setVehicle] = useState<Vehicle>("sedan");
  const [surge, setSurge] = useState(1.0);
  const [estimates, setEstimates] = useState<Estimate[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const estimateAll = async () => {
    setLoading(true);
    setError(null);
    try {
      const results = await Promise.all(
        VEHICLES.map((v) =>
          api.rides
            .estimate({ fromIata, toLat, toLng, vehicle: v, surge })
            .catch(() => null),
        ),
      );
      setEstimates(results.filter((r): r is Estimate => r !== null));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Estimate failed");
      setEstimates([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void estimateAll();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Ride estimator</p>
        <div className="grid grid-cols-3 gap-2">
          <Input
            value={fromIata}
            onChange={(e) => setFromIata(e.target.value.toUpperCase().slice(0, 3))}
            placeholder="from IATA"
            className="text-xs font-mono uppercase"
          />
          <Input
            type="number"
            value={toLat}
            onChange={(e) => setToLat(Number(e.target.value))}
            placeholder="to lat"
            className="text-xs font-mono"
            step={0.0001}
          />
          <Input
            type="number"
            value={toLng}
            onChange={(e) => setToLng(Number(e.target.value))}
            placeholder="to lng"
            className="text-xs font-mono"
            step={0.0001}
          />
        </div>
        <div className="grid grid-cols-2 gap-2">
          <select
            value={vehicle}
            onChange={(e) => setVehicle(e.target.value as Vehicle)}
            className="rounded-md border border-input bg-background text-xs px-2 py-1.5 capitalize"
          >
            {VEHICLES.map((v) => (
              <option key={v} value={v}>
                {v}
              </option>
            ))}
          </select>
          <Input
            type="number"
            min={0.5}
            max={5}
            step={0.1}
            value={surge}
            onChange={(e) => setSurge(Number(e.target.value))}
            placeholder="surge x"
            className="text-xs"
          />
        </div>
        <Button size="sm" onClick={estimateAll} disabled={loading} className="w-full">
          {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null} Refresh estimates
        </Button>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {estimates.map((e) => (
        <GlassCard key={e.vehicle} className="p-3 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
            <Car className="w-5 h-5 text-primary" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-foreground capitalize">{e.label}</p>
            <p className="text-[11px] text-muted-foreground">
              {e.distanceKm.toFixed(1)} km · {e.etaMinutes} min · cap {e.capacity}
            </p>
          </div>
          <div className="text-right">
            <p className="text-sm font-bold text-foreground">${e.fareUsd.toFixed(2)}</p>
            {e.surge !== 1 && <p className="text-[10px] text-amber-500">{e.surge.toFixed(1)}× surge</p>}
          </div>
        </GlassCard>
      ))}
    </div>
  );
};

export default React.memo(RidesPanel);
