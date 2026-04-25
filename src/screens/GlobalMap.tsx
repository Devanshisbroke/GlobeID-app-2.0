import React, { useState, lazy, Suspense } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { getAirport } from "@/lib/airports";
import {
  useUserStore,
  selectVisitedCountries,
  selectUpcomingCountries,
  formatTripDate,
} from "@/store/userStore";
import { getGlobalStats } from "@/lib/destinationAnalytics";
import { springs } from "@/hooks/useMotion";
import { easing } from "@/motion/motionConfig";
import { Globe, Plane, Clock, ChevronRight, Navigation, Activity, Users, Route, Radio } from "lucide-react";
import { cn } from "@/lib/utils";
import MapControls from "@/components/map/MapControls";
import SimulationHUD from "@/components/simulation/SimulationHUD";
import TravelTimelineSim from "@/components/simulation/TravelTimeline";
import ContinentTraffic from "@/components/simulation/ContinentTraffic";
import SpeedControl from "@/components/simulation/SpeedControl";

const GlobeScene = lazy(() => import("@/components/map/GlobeScene"));

const USER_LAT = 37.7749;
const USER_LNG = -122.4194;
const stats = getGlobalStats();

function useAnimatedNum(target: number, dur = 1500): number {
  const [val, setVal] = React.useState(0);
  React.useEffect(() => {
    const start = performance.now();
    let rafId = 0;
    const tick = (now: number) => {
      const p = Math.min((now - start) / dur, 1);
      setVal(Math.round(target * (1 - Math.pow(1 - p, 3))));
      if (p < 1) rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafId);
  }, [target, dur]);
  return val;
}

const LiveFlightStats: React.FC = () => {
  const flights = useAnimatedNum(stats.totalFlightsToday);
  const routes = useAnimatedNum(stats.totalRoutes);
  return (
    <GlassCard className="py-2.5 px-3 flex items-center justify-between" interactive={false}>
      <div className="flex items-center gap-1.5">
        <div className="w-2 h-2 rounded-full bg-accent animate-pulse" />
        <span className="text-[10px] text-muted-foreground font-medium">Live</span>
      </div>
      <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
        <Activity className="w-3 h-3" />
        <span className="font-bold text-foreground">{flights.toLocaleString()}</span> flights
      </div>
      <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
        <Route className="w-3 h-3" />
        <span className="font-bold text-foreground">{routes.toLocaleString()}</span> routes
      </div>
      <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
        <Users className="w-3 h-3" />
        <span className="font-bold text-foreground">{stats.topRoute}</span>
      </div>
    </GlassCard>
  );
};

const GlobalMap: React.FC = () => {
  const [showHistory, setShowHistory] = useState(true);
  const [showAirports, setShowAirports] = useState(true);
  const [showPanel, setShowPanel] = useState(true);
  const [isLoaded, setIsLoaded] = useState(false);
  const [simMode, setSimMode] = useState(false);
  const [simSpeed, setSimSpeed] = useState(1);
  const [simHour, setSimHour] = useState(12);

  const travelHistory = useUserStore((s) => s.travelHistory);
  const upcomingFlights = React.useMemo(
    () =>
      travelHistory
        .filter((r) => r.type === "upcoming" || r.type === "current")
        .slice()
        .sort((a, b) => a.date.localeCompare(b.date)),
    [travelHistory]
  );
  const pastFlights = React.useMemo(
    () =>
      travelHistory
        .filter((r) => r.type === "past")
        .slice()
        .sort((a, b) => b.date.localeCompare(a.date)),
    [travelHistory]
  );
  const visitedCountries = React.useMemo(
    () => selectVisitedCountries(travelHistory),
    [travelHistory]
  );
  const upcomingCountries = React.useMemo(
    () => selectUpcomingCountries(travelHistory),
    [travelHistory]
  );

  return (
    <div className="relative min-h-[100dvh] -mx-4 -mt-6" style={{ marginBottom: "-5rem" }}>
      {/* 3D Globe — pointer-events contained to this layer */}
      <div
        className="absolute inset-0"
        style={{
          background: "#020617",
          touchAction: "none", // Globe area: let Three.js handle gestures
        }}
      >
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
            transition={{ duration: 0.5, ease: easing.cinematic }}
            onAnimationComplete={() => setIsLoaded(true)}
          >
            <GlobeScene
              showHistory={showHistory}
              showAirports={showAirports}
              userLat={USER_LAT}
              userLng={USER_LNG}
              showSimulation={simMode}
              simSpeed={simSpeed}
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

      {/* Simulation mode toggle — top left */}
      <motion.button
        onClick={() => setSimMode(!simMode)}
        whileTap={{ scale: 0.9 }}
        className={cn(
          "absolute top-4 left-4 z-20 flex items-center gap-2 px-3 py-2 rounded-xl border shadow-depth-sm transition-colors",
          simMode
            ? "bg-primary/20 border-primary/40 text-primary backdrop-blur-xl"
            : "bg-background/60 border-border/[0.15] text-muted-foreground backdrop-blur-xl"
        )}
      >
        <Radio className="w-3.5 h-3.5" strokeWidth={2} />
        <span className="text-[10px] font-bold uppercase tracking-wider">Simulation</span>
        {simMode && <div className="w-1.5 h-1.5 rounded-full bg-accent animate-pulse" />}
      </motion.button>

      {/* Simulation HUD overlay */}
      <AnimatePresence>
        {simMode && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="absolute top-14 left-4 right-4 z-10 space-y-2"
          >
            <SimulationHUD speed={simSpeed} />
          </motion.div>
        )}
      </AnimatePresence>

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

      {/* Flight Info Panel — scrollable, touch-action allows vertical scroll */}
      <AnimatePresence>
        {showPanel && (
          <motion.div
            initial={{ y: 200, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 200, opacity: 0 }}
            transition={springs.gentle}
            className="absolute bottom-20 left-0 right-0 z-10 px-4 pb-2 space-y-3 max-h-[45vh] overflow-y-auto overscroll-contain"
            style={{ touchAction: "pan-y", WebkitOverflowScrolling: "touch" }}
          >
            {/* Simulation controls when in sim mode */}
            {simMode && (
              <GlassCard className="space-y-3 py-3 px-3" interactive={false}>
                <SpeedControl speed={simSpeed} onSpeedChange={setSimSpeed} />
                <TravelTimelineSim hour={simHour} onHourChange={setSimHour} />
                <ContinentTraffic />
              </GlassCard>
            )}

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
                  <p className="text-sm font-bold text-foreground">{travelHistory.length}</p>
                </div>
              </GlassCard>
              <GlassCard className="flex-1 py-2.5 px-3 flex items-center gap-2" interactive={false}>
                <Navigation className="w-4 h-4 text-warning" strokeWidth={1.8} />
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
                        <div className="w-9 h-9 rounded-xl bg-gradient-brand flex items-center justify-center shrink-0">
                          <Plane className="w-4 h-4 text-primary-foreground" strokeWidth={1.8} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-bold text-foreground">{flight.from}</span>
                            <div className="flex-1 h-px bg-gradient-to-r from-primary/40 to-accent/40 mx-1" />
                            <span className="text-sm font-bold text-foreground">{flight.to}</span>
                          </div>
                          <p className="text-[10px] text-muted-foreground mt-0.5">
                            {flight.airline} · {flight.duration} · {formatTripDate(flight.date)}
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
                        <p className="text-[10px] text-muted-foreground">{flight.airline} · {formatTripDate(flight.date)}</p>
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
                  <span key={country} className="px-2.5 py-1 rounded-lg text-[10px] font-semibold bg-accent/15 text-accent border border-accent/20">
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
