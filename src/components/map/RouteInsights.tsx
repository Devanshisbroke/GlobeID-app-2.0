import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { getAirport } from "@/lib/airports";
import { Plane, Clock, Globe, Leaf, X, ArrowRight } from "lucide-react";
import { cn } from "@/lib/utils";

interface RouteInsightsProps {
  fromIata: string;
  toIata: string;
  onClose: () => void;
}

// Approximate distance calc using Haversine
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLng = (lng2 - lng1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Timezone offsets (approximate)
const timezoneOffsets: Record<string, number> = {
  SFO: -8, LAX: -8, JFK: -5, ORD: -6, MIA: -5, DFW: -6, SEA: -8, YYZ: -5, CUN: -6,
  LHR: 0, CDG: 1, FRA: 1, AMS: 1, MAD: 1, IST: 3, ZRH: 1,
  SIN: 8, NRT: 9, HND: 9, HKG: 8, PVG: 8, PEK: 8, ICN: 9, BKK: 7, DEL: 5.5, BOM: 5.5, KUL: 8,
  DXB: 4, AUH: 4, DOH: 3,
  SYD: 11, MEL: 11, AKL: 13,
  GRU: -3, BOG: -5, LIM: -5,
  JNB: 2, CAI: 2, NBO: 3,
};

const RouteInsights: React.FC<RouteInsightsProps> = ({ fromIata, toIata, onClose }) => {
  const from = getAirport(fromIata);
  const to = getAirport(toIata);

  if (!from || !to) {
    return (
      <AnimatedPage>
        <GlassCard><p className="text-sm text-muted-foreground">Route data unavailable</p></GlassCard>
      </AnimatedPage>
    );
  }

  const distanceKm = haversineKm(from.lat, from.lng, to.lat, to.lng);
  const distanceMi = distanceKm * 0.621371;
  const flightHours = distanceKm / 850; // avg speed 850 km/h
  const flightTimeStr = `${Math.floor(flightHours)}h ${Math.round((flightHours % 1) * 60)}m`;
  const co2Kg = Math.round(distanceKm * 0.115); // ~115g CO2 per km per passenger
  const tzDiff = (timezoneOffsets[toIata] ?? 0) - (timezoneOffsets[fromIata] ?? 0);
  const tzSign = tzDiff >= 0 ? "+" : "";

  return (
    <AnimatedPage>
      <GlassCard variant="premium" depth="lg" className="relative overflow-hidden">
        <div className="absolute top-0 right-0 w-24 h-24 rounded-full bg-gradient-cosmic blur-3xl opacity-10 pointer-events-none" />
        <button onClick={onClose} className="absolute top-3 right-3 w-7 h-7 rounded-full bg-secondary/60 flex items-center justify-center z-10">
          <X className="w-3.5 h-3.5 text-muted-foreground" />
        </button>

        {/* Route header */}
        <div className="flex items-center justify-center gap-3 mb-5">
          <div className="text-center">
            <p className="text-2xl font-bold text-foreground">{fromIata}</p>
            <p className="text-[10px] text-muted-foreground">{from.city}</p>
          </div>
          <div className="flex flex-col items-center px-4">
            <div className="w-20 h-px bg-gradient-to-r from-primary via-accent to-primary relative">
              <Plane className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 text-primary" />
            </div>
          </div>
          <div className="text-center">
            <p className="text-2xl font-bold text-foreground">{toIata}</p>
            <p className="text-[10px] text-muted-foreground">{to.city}</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-2.5">
          <div className="flex items-center gap-2.5 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <ArrowRight className="w-4 h-4 text-primary shrink-0" />
            <div>
              <p className="text-[10px] text-muted-foreground">Distance</p>
              <p className="text-sm font-bold text-foreground">{Math.round(distanceKm).toLocaleString()} km</p>
              <p className="text-[10px] text-muted-foreground">{Math.round(distanceMi).toLocaleString()} mi</p>
            </div>
          </div>

          <div className="flex items-center gap-2.5 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <Clock className="w-4 h-4 text-accent shrink-0" />
            <div>
              <p className="text-[10px] text-muted-foreground">Flight Time</p>
              <p className="text-sm font-bold text-foreground">{flightTimeStr}</p>
              <p className="text-[10px] text-muted-foreground">Est. direct</p>
            </div>
          </div>

          <div className="flex items-center gap-2.5 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <Globe className="w-4 h-4 text-neon-amber shrink-0" />
            <div>
              <p className="text-[10px] text-muted-foreground">Time Zone</p>
              <p className="text-sm font-bold text-foreground">{tzSign}{tzDiff}h</p>
              <p className="text-[10px] text-muted-foreground">difference</p>
            </div>
          </div>

          <div className="flex items-center gap-2.5 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <Leaf className="w-4 h-4 text-accent shrink-0" />
            <div>
              <p className="text-[10px] text-muted-foreground">CO₂ Est.</p>
              <p className="text-sm font-bold text-foreground">{co2Kg} kg</p>
              <p className="text-[10px] text-muted-foreground">per passenger</p>
            </div>
          </div>
        </div>
      </GlassCard>
    </AnimatedPage>
  );
};

export default RouteInsights;
