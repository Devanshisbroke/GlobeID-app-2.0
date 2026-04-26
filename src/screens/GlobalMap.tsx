import React, { useState, lazy, Suspense } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Globe,
  Plane,
  Clock,
  ChevronRight,
  Navigation,
  Activity,
  Users,
  Route,
  Radio,
} from "lucide-react";
import {
  Surface,
  Pill,
  Text,
  spring,
  ease,
  duration,
} from "@/components/ui/v2";
import { getAirport } from "@/lib/airports";
import {
  useUserStore,
  selectVisitedCountries,
  selectUpcomingCountries,
  formatTripDate,
} from "@/store/userStore";
import { getGlobalStats } from "@/lib/destinationAnalytics";
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
    <Surface
      variant="elevated"
      radius="surface"
      className="flex items-center justify-between gap-2 px-3 py-2"
    >
      <span className="inline-flex items-center gap-1.5">
        <span className="w-2 h-2 rounded-full bg-state-accent animate-pulse" />
        <Text variant="caption-2" tone="tertiary">
          Live
        </Text>
      </span>
      <span className="inline-flex items-center gap-1">
        <Activity className="w-3 h-3 text-ink-tertiary" strokeWidth={1.8} />
        <Text variant="caption-2" tone="primary" className="font-semibold tabular-nums">
          {flights.toLocaleString()}
        </Text>
        <Text variant="caption-2" tone="tertiary">
          flights
        </Text>
      </span>
      <span className="inline-flex items-center gap-1">
        <Route className="w-3 h-3 text-ink-tertiary" strokeWidth={1.8} />
        <Text variant="caption-2" tone="primary" className="font-semibold tabular-nums">
          {routes.toLocaleString()}
        </Text>
        <Text variant="caption-2" tone="tertiary">
          routes
        </Text>
      </span>
      <span className="inline-flex items-center gap-1">
        <Users className="w-3 h-3 text-ink-tertiary" strokeWidth={1.8} />
        <Text variant="caption-2" tone="primary" className="font-semibold">
          {stats.topRoute}
        </Text>
      </span>
    </Surface>
  );
};

/**
 * GlobalMap — Phase 7 PR-ε.
 *
 * 3D globe layer (Three.js) preserved unchanged per locked decision Q7
 * (full-bleed Three.js on the Map tab). Visual reset is limited to the
 * floating glass panels overlaying the globe.
 *
 * Functional surface preserved verbatim:
 *  - Same state machine (`showHistory`, `showAirports`, `showPanel`,
 *    `simMode`, `simSpeed`, `simHour`, `isLoaded`).
 *  - Same store reads (`useUserStore.travelHistory`,
 *    `selectVisitedCountries`, `selectUpcomingCountries`).
 *  - Same lazy `GlobeScene` boundary.
 *  - Same simulation HUD + speed control + continent traffic widgets.
 *
 * Visual changes:
 *  - GlassCard floating panels → `Surface elevated`.
 *  - Country chips → `Pill tone="accent" weight="tinted"`.
 *  - Stat chips → `Surface elevated` row with v2 Text.
 *  - Upcoming-flight cards → `Surface elevated` rows; drops the gradient-
 *    brand icon-square pattern.
 *  - Past-flight cards → `Surface plain` rows.
 *  - framer-motion → motion@12; transitions tuned to v2 spring + ease.
 */
const GlobalMap: React.FC = () => {
  const [showHistory, setShowHistory] = useState(true);
  const [showAirports, setShowAirports] = useState(true);
  const [showPanel, setShowPanel] = useState(true);
  const [, setIsLoaded] = useState(false);
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
    [travelHistory],
  );
  const pastFlights = React.useMemo(
    () =>
      travelHistory
        .filter((r) => r.type === "past")
        .slice()
        .sort((a, b) => b.date.localeCompare(a.date)),
    [travelHistory],
  );
  const visitedCountries = React.useMemo(
    () => selectVisitedCountries(travelHistory),
    [travelHistory],
  );
  const upcomingCountries = React.useMemo(
    () => selectUpcomingCountries(travelHistory),
    [travelHistory],
  );

  return (
    <div
      className="relative min-h-[100dvh] -mx-4 -mt-6"
      style={{ marginBottom: "-5rem" }}
    >
      {/* 3D Globe — pointer-events contained to this layer */}
      <div
        className="absolute inset-0"
        style={{
          background: "#020617",
          touchAction: "none",
        }}
      >
        <Suspense
          fallback={
            <div className="flex items-center justify-center h-full flex-col gap-3">
              <div className="w-8 h-8 rounded-full border-2 border-brand/40 border-t-brand animate-spin" />
              <Text
                variant="caption-1"
                tone="tertiary"
                className="font-medium tracking-[0.18em] animate-pulse"
              >
                Rendering Earth…
              </Text>
            </div>
          }
        >
          <motion.div
            className="w-full h-full"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: duration.hero, ease: ease.decelerated }}
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
        whileTap={{ scale: 0.92 }}
        transition={spring.snap}
        className={cn(
          "absolute top-safe-4 left-safe-4 z-20 flex items-center gap-2 px-3 py-2 rounded-p7-input border shadow-p7-sm transition-colors duration-p7-pop ease-p7-standard",
          simMode
            ? "bg-brand-soft border-brand/40 text-brand backdrop-blur-xl"
            : "bg-surface-glass border-surface-hairline text-ink-tertiary backdrop-blur-xl",
        )}
      >
        <Radio className="w-3.5 h-3.5" strokeWidth={2} />
        <Text
          variant="caption-2"
          tone="primary"
          className="uppercase tracking-[0.18em] font-bold"
        >
          Simulation
        </Text>
        {simMode ? (
          <span className="w-1.5 h-1.5 rounded-full bg-state-accent animate-pulse" />
        ) : null}
      </motion.button>

      {/* Simulation HUD overlay */}
      <AnimatePresence>
        {simMode ? (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: duration.page, ease: ease.standard }}
            className="absolute top-14 left-4 right-4 z-10 space-y-2"
          >
            <SimulationHUD speed={simSpeed} />
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Bottom panel toggle */}
      <motion.button
        onClick={() => setShowPanel(!showPanel)}
        className="absolute bottom-24 right-4 z-20 w-10 h-10 rounded-full bg-surface-glass backdrop-blur-[20px] border border-surface-hairline flex items-center justify-center shadow-p7-md"
        whileTap={{ scale: 0.92 }}
        transition={spring.snap}
        aria-label="Toggle flight panel"
      >
        <ChevronRight
          className={cn(
            "w-4 h-4 text-ink-primary transition-transform duration-p7-pop",
            showPanel ? "rotate-90" : "-rotate-90",
          )}
        />
      </motion.button>

      {/* Flight Info Panel — scrollable */}
      <AnimatePresence>
        {showPanel ? (
          <motion.div
            initial={{ y: 200, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 200, opacity: 0 }}
            transition={spring.default}
            className="absolute bottom-20 left-0 right-0 z-10 px-4 pb-2 space-y-3 max-h-[45vh] overflow-y-auto overscroll-contain"
            style={{ touchAction: "pan-y", WebkitOverflowScrolling: "touch" }}
          >
            {/* Simulation controls when in sim mode */}
            {simMode ? (
              <Surface
                variant="elevated"
                radius="surface"
                className="space-y-3 px-3 py-3"
              >
                <SpeedControl speed={simSpeed} onSpeedChange={setSimSpeed} />
                <TravelTimelineSim hour={simHour} onHourChange={setSimHour} />
                <ContinentTraffic />
              </Surface>
            ) : null}

            {/* Live global stats */}
            <LiveFlightStats />

            {/* Stats bar */}
            <div className="flex gap-2">
              <StatTile
                icon={<Globe className="w-4 h-4 text-state-accent" strokeWidth={1.8} />}
                label="Visited"
                value={visitedCountries.length}
              />
              <StatTile
                icon={<Plane className="w-4 h-4 text-brand" strokeWidth={1.8} />}
                label="Flights"
                value={travelHistory.length}
              />
              <StatTile
                icon={<Navigation className="w-4 h-4 text-[hsl(var(--p7-warning))]" strokeWidth={1.8} />}
                label="Location"
                value="SFO"
              />
            </div>

            {/* Upcoming flights */}
            {upcomingFlights.length > 0 ? (
              <div>
                <Text
                  as="h3"
                  variant="caption-1"
                  tone="tertiary"
                  className="mb-2 px-1 uppercase tracking-[0.18em]"
                >
                  Upcoming Flights
                </Text>
                <div className="space-y-2">
                  {upcomingFlights.map((flight) => {
                    const from = getAirport(flight.from);
                    const to = getAirport(flight.to);
                    if (!from || !to) return null;
                    return (
                      <Surface
                        key={flight.id}
                        variant="elevated"
                        radius="surface"
                        className="px-4 py-3"
                      >
                        <div className="flex items-center gap-3">
                          <Plane
                            className="w-4 h-4 text-brand shrink-0"
                            strokeWidth={1.8}
                          />
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <Text variant="body-em" tone="primary">
                                {flight.from}
                              </Text>
                              <span className="flex-1 h-px bg-surface-hairline mx-1" />
                              <Text variant="body-em" tone="primary">
                                {flight.to}
                              </Text>
                            </div>
                            <Text variant="caption-2" tone="tertiary" className="mt-0.5">
                              {flight.airline} · {flight.duration} ·{" "}
                              {formatTripDate(flight.date)}
                            </Text>
                          </div>
                        </div>
                      </Surface>
                    );
                  })}
                </div>
              </div>
            ) : null}

            {/* Past flights */}
            {showHistory && pastFlights.length > 0 ? (
              <div>
                <Text
                  as="h3"
                  variant="caption-1"
                  tone="tertiary"
                  className="mb-2 px-1 uppercase tracking-[0.18em]"
                >
                  Flight History
                </Text>
                <div className="space-y-2">
                  {pastFlights.map((flight) => (
                    <Surface
                      key={flight.id}
                      variant="plain"
                      radius="surface"
                      className="px-4 py-3"
                    >
                      <div className="flex items-center gap-3">
                        <Clock
                          className="w-3.5 h-3.5 text-ink-tertiary shrink-0"
                          strokeWidth={1.8}
                        />
                        <div className="flex-1 min-w-0">
                          <Text variant="callout" tone="primary">
                            {flight.from} → {flight.to}
                          </Text>
                          <Text variant="caption-2" tone="tertiary">
                            {flight.airline} · {formatTripDate(flight.date)}
                          </Text>
                        </div>
                        <Text variant="caption-2" tone="tertiary">
                          {flight.duration}
                        </Text>
                      </div>
                    </Surface>
                  ))}
                </div>
              </div>
            ) : null}

            {/* Countries */}
            <div>
              <Text
                as="h3"
                variant="caption-1"
                tone="tertiary"
                className="mb-2 px-1 uppercase tracking-[0.18em]"
              >
                Countries
              </Text>
              <div className="flex flex-wrap gap-1.5">
                {visitedCountries.map((country) => (
                  <Pill key={country} tone="accent" weight="tinted">
                    {country}
                  </Pill>
                ))}
                {upcomingCountries
                  .filter((c) => !visitedCountries.includes(c))
                  .map((country) => (
                    <Pill key={country} tone="brand" weight="outline">
                      {country}
                    </Pill>
                  ))}
              </div>
            </div>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
};

export default GlobalMap;

const StatTile: React.FC<{
  icon: React.ReactNode;
  label: string;
  value: string | number;
}> = ({ icon, label, value }) => (
  <Surface
    variant="elevated"
    radius="surface"
    className="flex-1 px-3 py-2 flex items-center gap-2"
  >
    <span aria-hidden>{icon}</span>
    <div>
      <Text variant="caption-2" tone="tertiary">
        {label}
      </Text>
      <Text variant="body-em" tone="primary" className="tabular-nums">
        {value}
      </Text>
    </div>
  </Surface>
);
