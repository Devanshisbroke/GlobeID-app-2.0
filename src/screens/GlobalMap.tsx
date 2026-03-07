/**
 * Global Map — interactive travel map showing destinations and travel paths.
 */
import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { Plane, Hotel, MapPin, Navigation, ChevronRight, Globe } from "lucide-react";
import { cn } from "@/lib/utils";

interface MapLocation {
  id: string;
  name: string;
  country: string;
  flag: string;
  lat: number;
  lng: number;
  type: "current" | "past" | "upcoming";
  icon: React.ElementType;
  detail: string;
}

const locations: MapLocation[] = [
  { id: "loc-1", name: "San Francisco", country: "United States", flag: "🇺🇸", lat: 37.7749, lng: -122.4194, type: "current", icon: MapPin, detail: "Current location" },
  { id: "loc-2", name: "Singapore", country: "Singapore", flag: "🇸🇬", lat: 1.3521, lng: 103.8198, type: "upcoming", icon: Plane, detail: "Flight SQ31 · Mar 10" },
  { id: "loc-3", name: "Mumbai", country: "India", flag: "🇮🇳", lat: 19.076, lng: 72.8777, type: "upcoming", icon: Hotel, detail: "Taj Mahal Palace · Mar 15" },
  { id: "loc-4", name: "Dubai", country: "UAE", flag: "🇦🇪", lat: 25.2048, lng: 55.2708, type: "past", icon: MapPin, detail: "Visited Feb 2026" },
  { id: "loc-5", name: "Tokyo", country: "Japan", flag: "🇯🇵", lat: 35.6762, lng: 139.6503, type: "past", icon: MapPin, detail: "Visited Jan 2026" },
];

const typeGradients = {
  current: "bg-gradient-ocean",
  upcoming: "bg-gradient-cosmic",
  past: "bg-secondary/60",
};

const typeLabels = {
  current: "Now",
  upcoming: "Upcoming",
  past: "Visited",
};

const GlobalMap: React.FC = () => {
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <div className="px-4 py-6 space-y-5">
      <AnimatedPage>
        <div className="flex items-center justify-between mb-1">
          <h1 className="text-xl font-bold text-foreground flex items-center gap-2">
            <Navigation className="w-5 h-5 text-primary" strokeWidth={1.8} />
            Global Map
          </h1>
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full glass text-[10px] text-muted-foreground font-medium">
            <Globe className="w-3 h-3 text-accent" /> 5 destinations
          </div>
        </div>
        <p className="text-xs text-muted-foreground">Your travel footprint across the world</p>
      </AnimatedPage>

      {/* Map visualization */}
      <AnimatedPage staggerIndex={1}>
        <GlassCard className="relative overflow-hidden p-0" variant="premium" depth="lg">
          <div className="relative w-full aspect-[16/10] bg-gradient-to-br from-secondary/30 via-card to-secondary/20 overflow-hidden">
            {/* Grid pattern */}
            <div className="absolute inset-0 bg-grid-pattern opacity-20" />
            {/* Ambient gradient overlay */}
            <div className="absolute inset-0 bg-gradient-to-br from-primary/4 via-transparent to-accent/3 pointer-events-none" />

            {/* Travel path lines */}
            <svg className="absolute inset-0 w-full h-full" viewBox="0 0 800 500" preserveAspectRatio="xMidYMid meet">
              <defs>
                <linearGradient id="pathGradient1" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="hsl(var(--primary))" stopOpacity="0.5" />
                  <stop offset="100%" stopColor="hsl(var(--accent))" stopOpacity="0.3" />
                </linearGradient>
                <linearGradient id="pathGradient2" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="hsl(var(--accent))" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="hsl(var(--neon-amber))" stopOpacity="0.3" />
                </linearGradient>
              </defs>
              {/* SFO to SIN path */}
              <path d="M 160 180 Q 400 80 620 280" stroke="url(#pathGradient1)" fill="none" strokeWidth="2" strokeDasharray="8 4" />
              {/* SIN to BOM path */}
              <path d="M 620 280 Q 560 260 520 250" stroke="url(#pathGradient2)" fill="none" strokeWidth="2" strokeDasharray="8 4" />
              {/* Past: Dubai */}
              <path d="M 520 250 Q 480 240 460 245" stroke="hsl(var(--muted-foreground) / 0.15)" fill="none" strokeWidth="1" strokeDasharray="4 4" />
            </svg>

            {/* Location markers */}
            {[
              { x: "20%", y: "36%", loc: locations[0] },
              { x: "77.5%", y: "56%", loc: locations[1] },
              { x: "65%", y: "50%", loc: locations[2] },
              { x: "57.5%", y: "49%", loc: locations[3] },
              { x: "82%", y: "35%", loc: locations[4] },
            ].map(({ x, y, loc }) => {
              const isSelected = selected === loc.id;
              const MarkerIcon = loc.icon;
              return (
                <button
                  key={loc.id}
                  onClick={() => setSelected(isSelected ? null : loc.id)}
                  className="absolute group transition-all duration-[var(--motion-small)]"
                  style={{ left: x, top: y, transform: "translate(-50%, -50%)" }}
                >
                  {/* Pulse ring for current */}
                  {loc.type === "current" && (
                    <span className="absolute inset-0 -m-4 rounded-full bg-primary/15 animate-glow-pulse" />
                  )}
                  <div className={cn(
                    "w-10 h-10 rounded-full flex items-center justify-center shadow-depth-md transition-all",
                    typeGradients[loc.type],
                    isSelected && "scale-125 shadow-glow-md ring-2 ring-primary/40",
                    "group-hover:scale-110"
                  )}>
                    <MarkerIcon className="w-4.5 h-4.5 text-primary-foreground" strokeWidth={1.8} />
                  </div>
                  {/* Tooltip */}
                  {isSelected && (
                    <div className="absolute top-full mt-2 left-1/2 -translate-x-1/2 glass-premium rounded-xl px-3 py-2 min-w-[150px] animate-scale-in z-10 border border-border/40 shadow-depth-lg">
                      <p className="text-xs font-bold text-foreground whitespace-nowrap">{loc.flag} {loc.name}</p>
                      <p className="text-[10px] text-muted-foreground whitespace-nowrap">{loc.detail}</p>
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Legend */}
      <AnimatedPage staggerIndex={2}>
        <div className="flex gap-4 px-1">
          {(["current", "upcoming", "past"] as const).map((type) => (
            <div key={type} className="flex items-center gap-1.5">
              <div className={cn("w-3 h-3 rounded-full", typeGradients[type])} />
              <span className="text-[10px] text-muted-foreground font-medium capitalize">{typeLabels[type]}</span>
            </div>
          ))}
        </div>
      </AnimatedPage>

      {/* Destinations list */}
      <AnimatedPage staggerIndex={3}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Destinations</h3>
        <div className="space-y-2">
          {locations.map((loc) => {
            const LocIcon = loc.icon;
            return (
              <GlassCard
                key={loc.id}
                className={cn("flex items-center gap-3 cursor-pointer py-3 touch-bounce", selected === loc.id && "border-primary/30")}
                onClick={() => setSelected(selected === loc.id ? null : loc.id)}
              >
                <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm", typeGradients[loc.type])}>
                  <LocIcon className="w-4.5 h-4.5 text-primary-foreground" strokeWidth={1.8} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    <span className="text-sm w-6 h-6 rounded-md bg-secondary/40 flex items-center justify-center border border-border/20">{loc.flag}</span>
                    <p className="text-sm font-semibold text-foreground">{loc.name}</p>
                  </div>
                  <p className="text-xs text-muted-foreground mt-0.5">{loc.detail}</p>
                </div>
                <span className={cn(
                  "text-[10px] px-2 py-0.5 rounded-full font-semibold",
                  loc.type === "current" ? "bg-primary/15 text-primary" :
                  loc.type === "upcoming" ? "bg-accent/15 text-accent" :
                  "bg-muted text-muted-foreground"
                )}>
                  {typeLabels[loc.type]}
                </span>
                <ChevronRight className="w-4 h-4 text-muted-foreground/50" />
              </GlassCard>
            );
          })}
        </div>
      </AnimatedPage>
    </div>
  );
};

export default GlobalMap;
