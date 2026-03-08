import React, { useState, useEffect, lazy, Suspense } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { flightRoutes, getAirport, visitedCountries, upcomingCountries } from "@/lib/airports";
import { getGlobalStats } from "@/lib/destinationAnalytics";
import { springs } from "@/hooks/useMotion";
import { Globe, Plane, Clock, ChevronRight, Navigation, Activity, Users, Route } from "lucide-react";
import { cn } from "@/lib/utils";
import MapControls from "@/components/map/MapControls";

const GlobeScene = lazy(() => import("@/components/map/GlobeScene"));

const USER_LAT = 37.7749;
const USER_LNG = -122.4194;

const GlobalMap: React.FC = () => {
  const [showHistory, setShowHistory] = useState(true);
  const [showAirports, setShowAirports] = useState(true);
  const [showPanel, setShowPanel] = useState(true);
  const [isLoaded, setIsLoaded] = useState(false);

  const upcomingFlights = flightRoutes.filter(r => r.type === "upcoming");
  const pastFlights = flightRoutes.filter(r => r.type === "past");

  return (
    <div className="relative min-h-screen -mx-4 -mt-6" style={{ marginBottom: "-5rem" }}>
      {/* 3D Globe */}
      <div className="absolute inset-0" style={{ background: "#020617" }}>
        <Suspense
          fallback={
            <div className="flex items-center justify-center h-full flex-col gap-3">
              <div className="w-8 h-8 rounded-full border-2 border-primary/40 border-t-primary animate-spin" />
              <p className="text-xs text-muted-foreground font-medium tracking-wider animate-pulse">
                Rendering Earth…
              </p>
            </div>
          }
        >
          <motion.div
            className="w-full h-full"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.2, ease: "easeOut" }}
            onAnimationComplete={() => setIsLoaded(true)}
          >
            <GlobeScene
              showHistory={showHistory}
              showAirports={showAirports}
              userLat={USER_LAT}
              userLng={USER_LNG}
            />
          </motion.div>
        </Suspense>
      </div>

      {/* Map Controls — top right glass */}
      <MapControls
        showHistory={showHistory}
        showAirports={showAirports}
        onToggleHistory={() => setShowHistory(!showHistory)}
        onToggleAirports={() => setShowAirports(!showAirports)}
      />

      {/* Bottom panel toggle */}
      <motion.button
        onClick={() => setShowPanel(!showPanel)}
        className="absolute bottom-24 right-4 z-20 w-10 h-10 rounded-full bg-background/60 backdrop-blur-[20px] border border-border/[0.15] flex items-center justify-center shadow-[0_4px_20px_rgba(0,0,0,0.3)]"
        whileTap={{ scale: 0.9 }}
        transition={springs.bounce}
        aria-label="Toggle flight panel"
      >
        <ChevronRight
          className={cn(
            "w-4 h-4 text-foreground transition-transform",
            showPanel ? "rotate-90" : "-rotate-90"
          )}
        />
      </motion.button>

      {/* Flight Info Panel */}
      <AnimatePresence>
        {showPanel && (
          <motion.div
            initial={{ y: 200, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 200, opacity: 0 }}
            transition={springs.gentle}
            className="absolute bottom-20 left-0 right-0 z-10 px-4 pb-2 space-y-3 max-h-[45vh] overflow-y-auto momentum-scroll"
          >
            {/* Live global stats */}
            <LiveFlightStats />

            {/* Stats bar */}
            <div className="flex gap-2">
              <GlassCard className="flex-1 py-2.5 px-3 flex items-center gap-2" interactive={false}>
                <Globe className="w-4 h-4 text-accent" strokeWidth={1.8} />
                <div>
                  <p className="text-[10px] text-muted-foreground">Visited</p>
                  <p className="text-sm font-bold text-foreground">{visitedCountries.length}</p>
                </div>
              </GlassCard>
              <GlassCard className="flex-1 py-2.5 px-3 flex items-center gap-2" interactive={false}>
                <Plane className="w-4 h-4 text-primary" strokeWidth={1.8} />
                <div>
                  <p className="text-[10px] text-muted-foreground">Flights</p>
                  <p className="text-sm font-bold text-foreground">{flightRoutes.length}</p>
                </div>
              </GlassCard>
              <GlassCard className="flex-1 py-2.5 px-3 flex items-center gap-2" interactive={false}>
                <Navigation className="w-4 h-4 text-neon-amber" strokeWidth={1.8} />
                <div>
                  <p className="text-[10px] text-muted-foreground">Location</p>
                  <p className="text-sm font-bold text-foreground">SFO</p>
                </div>
              </GlassCard>
            </div>

            {/* Upcoming flights */}
            {upcomingFlights.length > 0 && (
              <div>
                <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold mb-2 px-1">Upcoming Flights</p>
                {upcomingFlights.map((flight) => {
                  const from = getAirport(flight.from);
                  const to = getAirport(flight.to);
                  if (!from || !to) return null;
                  return (
                    <GlassCard key={flight.id} className="mb-2" variant="premium" depth="md">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-gradient-aurora flex items-center justify-center shrink-0">
                          <Plane className="w-4 h-4 text-primary-foreground" strokeWidth={1.8} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-bold text-foreground">{flight.from}</span>
                            <div className="flex-1 h-px bg-gradient-to-r from-primary/40 to-accent/40 mx-1" />
                            <span className="text-sm font-bold text-foreground">{flight.to}</span>
                          </div>
                          <p className="text-[10px] text-muted-foreground mt-0.5">
                            {flight.airline} · {flight.duration} · {flight.date}
                          </p>
                        </div>
                      </div>
                    </GlassCard>
                  );
                })}
              </div>
            )}

            {/* Past flights */}
            {showHistory && pastFlights.length > 0 && (
              <div>
                <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold mb-2 px-1">Flight History</p>
                {pastFlights.map((flight) => (
                  <GlassCard key={flight.id} className="mb-2 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                        <Clock className="w-3.5 h-3.5 text-muted-foreground" strokeWidth={1.8} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-foreground">{flight.from} → {flight.to}</p>
                        <p className="text-[10px] text-muted-foreground">{flight.airline} · {flight.date}</p>
                      </div>
                      <span className="text-[10px] text-muted-foreground">{flight.duration}</span>
                    </div>
                  </GlassCard>
                ))}
              </div>
            )}

            {/* Countries */}
            <div>
              <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold mb-2 px-1">Countries</p>
              <div className="flex flex-wrap gap-1.5">
                {visitedCountries.map((country) => (
                  <span key={country} className="px-2.5 py-1 rounded-lg text-[10px] font-semibold bg-accent/15 text-accent border border-accent/20">
                    {country}
                  </span>
                ))}
                {upcomingCountries.filter(c => !visitedCountries.includes(c)).map((country) => (
                  <span key={country} className="px-2.5 py-1 rounded-lg text-[10px] font-semibold bg-aurora-purple/15 text-aurora-purple border border-aurora-purple/20">
                    {country}
                  </span>
                ))}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default GlobalMap;
