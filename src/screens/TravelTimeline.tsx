import React, { useMemo, useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import {
  buildTimeline,
  computeStats,
  computeAchievements,
  type TimelineEntry,
} from "@/lib/travelTimeline";
import { getIcon } from "@/lib/iconMap";
import { spring, staggerItem, easing } from "@/motion/motionConfig";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import {
  Plane,
  Globe,
  Route,
  Calendar,
  ChevronDown,
  Filter,
  Play,
  Trophy,
  MapPin,
  Clock,
  ArrowLeft,
} from "lucide-react";

type FilterTab = "all" | "2026" | "2025";
type ViewTab = "timeline" | "achievements" | "continents";

const TravelTimeline: React.FC = () => {
  const navigate = useNavigate();
  const [yearFilter, setYearFilter] = useState<FilterTab>("all");
  const [continentFilter, setContinentFilter] = useState<string>("all");
  const [viewTab, setViewTab] = useState<ViewTab>("timeline");
  const [selectedEntry, setSelectedEntry] = useState<string | null>(null);
  const [replaying, setReplaying] = useState(false);
  const [replayIndex, setReplayIndex] = useState(0);

  const allEntries = useMemo(() => buildTimeline(), []);
  const stats = useMemo(() => computeStats(allEntries), [allEntries]);
  const achievements = useMemo(() => computeAchievements(stats), [stats]);

  const filteredEntries = useMemo(() => {
    return allEntries.filter((e) => {
      if (yearFilter !== "all" && e.year.toString() !== yearFilter) return false;
      if (continentFilter !== "all" && e.continent !== continentFilter) return false;
      return true;
    });
  }, [allEntries, yearFilter, continentFilter]);

  const handleReplay = useCallback(async () => {
    setReplaying(true);
    setReplayIndex(0);
    haptics.medium();
    const pastEntries = allEntries.filter((e) => e.type === "past");
    for (let i = 0; i < pastEntries.length; i++) {
      setReplayIndex(i);
      setSelectedEntry(pastEntries[i].id);
      await new Promise((r) => setTimeout(r, 1200));
    }
    setReplaying(false);
  }, [allEntries]);

  const handleEntryClick = (entry: TimelineEntry) => {
    haptics.tap();
    setSelectedEntry(selectedEntry === entry.id ? null : entry.id);
  };

  const statCards = [
    { icon: Globe, label: "Countries", value: stats.totalCountries.toString(), color: "text-ocean-aqua" },
    { icon: Plane, label: "Flights", value: stats.totalFlights.toString(), color: "text-aurora-purple" },
    { icon: Route, label: "Distance", value: `${(stats.totalDistance / 1000).toFixed(0)}k km`, color: "text-sunset-orange" },
    { icon: Clock, label: "Longest", value: stats.longestFlight ? `${(stats.longestFlight.distance / 1000).toFixed(1)}k` : "—", color: "text-forest-emerald" },
  ];

  const viewTabs: { key: ViewTab; label: string; icon: React.ElementType }[] = [
    { key: "timeline", label: "Timeline", icon: Calendar },
    { key: "achievements", label: "Badges", icon: Trophy },
    { key: "continents", label: "Continents", icon: Globe },
  ];

  return (
    <div className="px-4 py-6 space-y-5 min-h-screen">
      {/* Header */}
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-2">
          <button
            onClick={() => navigate("/travel")}
            className="w-9 h-9 rounded-xl glass flex items-center justify-center border border-border/30"
          >
            <ArrowLeft className="w-4 h-4 text-muted-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground tracking-tight">Travel Timeline</h1>
            <p className="text-xs text-muted-foreground">Your journey around the world</p>
          </div>
          <button
            onClick={handleReplay}
            disabled={replaying}
            className={cn(
              "ml-auto w-10 h-10 rounded-xl flex items-center justify-center transition-all",
              replaying
                ? "bg-primary/20 text-primary animate-pulse"
                : "glass border border-border/30 text-muted-foreground hover:text-primary"
            )}
          >
            <Play className="w-4 h-4" fill={replaying ? "currentColor" : "none"} />
          </button>
        </div>
      </AnimatedPage>

      {/* Stats Header */}
      <AnimatedPage staggerIndex={1}>
        <div className="grid grid-cols-4 gap-2">
          {statCards.map((s, i) => {
            const Icon = s.icon;
            return (
              <GlassCard key={s.label} depth="md" interactive={false} className="text-center py-3 px-2">
                <Icon className={cn("w-4 h-4 mx-auto mb-1", s.color)} strokeWidth={1.8} />
                <p className="text-lg font-bold text-foreground tabular-nums">{s.value}</p>
                <p className="text-[9px] text-muted-foreground uppercase tracking-wider">{s.label}</p>
              </GlassCard>
            );
          })}
        </div>
      </AnimatedPage>

      {/* View Tabs */}
      <AnimatedPage staggerIndex={2}>
        <div className="flex gap-1 p-1 rounded-2xl glass border border-border/40">
          {viewTabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onClick={() => setViewTab(tab.key)}
                className={cn(
                  "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-semibold transition-all min-h-[40px]",
                  viewTab === tab.key
                    ? "bg-gradient-ocean text-primary-foreground shadow-depth-sm"
                    : "text-muted-foreground"
                )}
              >
                <Icon className="w-3.5 h-3.5" strokeWidth={1.8} />
                {tab.label}
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {/* Content */}
      <AnimatePresence mode="wait">
        {viewTab === "timeline" && (
          <motion.div
            key="timeline"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={spring.card}
            className="space-y-4"
          >
            {/* Filters */}
            <div className="flex gap-2 items-center">
              <Filter className="w-3.5 h-3.5 text-muted-foreground" />
              {(["all", "2026", "2025"] as FilterTab[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setYearFilter(f)}
                  className={cn(
                    "px-3 py-1.5 rounded-lg text-xs font-semibold transition-all min-h-[32px]",
                    yearFilter === f
                      ? "bg-primary text-primary-foreground shadow-glow-sm"
                      : "glass text-muted-foreground"
                  )}
                >
                  {f === "all" ? "All Years" : f}
                </button>
              ))}
              <select
                value={continentFilter}
                onChange={(e) => setContinentFilter(e.target.value)}
                className="ml-auto px-2 py-1.5 rounded-lg glass border border-border/40 text-xs text-foreground bg-transparent outline-none"
              >
                <option value="all">All Regions</option>
                {stats.continents
                  .filter((c) => c.count > 0)
                  .map((c) => (
                    <option key={c.name} value={c.name}>
                      {c.name}
                    </option>
                  ))}
              </select>
            </div>

            {/* Timeline */}
            <div className="relative">
              {/* Vertical line */}
              <div className="absolute left-[18px] top-0 bottom-0 w-[2px] bg-gradient-to-b from-primary/40 via-accent/30 to-transparent" />

              <div className="space-y-1">
                {filteredEntries.map((entry, i) => {
                  const isSelected = selectedEntry === entry.id;
                  const isReplayActive = replaying && replayIndex >= i;

                  return (
                    <motion.div
                      key={entry.id}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{
                        opacity: replaying ? (isReplayActive ? 1 : 0.3) : 1,
                        x: 0,
                      }}
                      transition={{ ...spring.card, delay: i * 0.08 }}
                      className="relative pl-10"
                    >
                      {/* Timeline dot */}
                      <motion.div
                        className={cn(
                          "absolute left-[11px] top-5 w-[16px] h-[16px] rounded-full border-2 z-10 transition-colors",
                          entry.type === "upcoming"
                            ? "border-accent bg-accent/20"
                            : isSelected
                              ? "border-primary bg-primary shadow-glow-sm"
                              : "border-primary/50 bg-card"
                        )}
                        animate={isSelected ? { scale: 1.3 } : { scale: 1 }}
                        transition={spring.bounce}
                      />

                      <GlassCard
                        className={cn(
                          "relative overflow-hidden",
                          isSelected && "ring-1 ring-primary/30 shadow-glow-sm"
                        )}
                        depth={isSelected ? "lg" : "sm"}
                        onClick={() => handleEntryClick(entry)}
                      >
                        {/* Accent strip */}
                        <div
                          className={cn(
                            "absolute left-0 top-0 bottom-0 w-[3px] rounded-l-2xl",
                            entry.type === "upcoming" ? "bg-accent" : "bg-primary"
                          )}
                        />

                        <div className="flex items-center gap-3">
                          <div
                            className={cn(
                              "w-9 h-9 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm",
                              entry.type === "upcoming" ? "bg-gradient-forest" : "bg-gradient-ocean"
                            )}
                          >
                            <Plane className="w-4 h-4 text-primary-foreground" strokeWidth={1.8} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-bold text-foreground tracking-tight">
                              {entry.originIata} → {entry.destinationIata}
                            </p>
                            <p className="text-xs text-muted-foreground truncate">
                              {entry.originCity} to {entry.destinationCity}
                            </p>
                          </div>
                          <div className="text-right shrink-0">
                            <p className="text-xs font-semibold text-foreground tabular-nums">
                              {entry.distance.toLocaleString()} km
                            </p>
                            <p className="text-[10px] text-muted-foreground">{entry.month} {entry.year}</p>
                          </div>
                        </div>

                        {/* Expanded detail */}
                        <AnimatePresence>
                          {isSelected && (
                            <motion.div
                              initial={{ height: 0, opacity: 0 }}
                              animate={{ height: "auto", opacity: 1 }}
                              exit={{ height: 0, opacity: 0 }}
                              transition={{ duration: 0.25, ease: easing.cinematic }}
                              className="overflow-hidden"
                            >
                              <div className="mt-3 pt-3 border-t border-border/30 grid grid-cols-3 gap-3 text-xs">
                                <div>
                                  <p className="text-muted-foreground">Airline</p>
                                  <p className="text-foreground font-medium">{entry.airline}</p>
                                </div>
                                <div>
                                  <p className="text-muted-foreground">Flight</p>
                                  <p className="text-foreground font-medium">{entry.flightNumber}</p>
                                </div>
                                <div>
                                  <p className="text-muted-foreground">Duration</p>
                                  <p className="text-foreground font-medium">{entry.duration}</p>
                                </div>
                              </div>
                              <div className="mt-2 flex gap-2">
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    navigate("/map");
                                  }}
                                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-primary/10 text-primary text-xs font-semibold transition-all hover:bg-primary/20 min-h-[32px]"
                                >
                                  <MapPin className="w-3 h-3" /> View on Map
                                </button>
                                <span
                                  className={cn(
                                    "flex items-center px-2.5 py-1.5 rounded-lg text-[10px] font-semibold",
                                    entry.type === "upcoming"
                                      ? "bg-accent/15 text-accent"
                                      : "bg-secondary text-muted-foreground"
                                  )}
                                >
                                  {entry.type === "upcoming" ? "Upcoming" : "Completed"}
                                </span>
                              </div>
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </GlassCard>
                    </motion.div>
                  );
                })}

                {filteredEntries.length === 0 && (
                  <p className="text-xs text-muted-foreground text-center py-12">
                    No flights match the selected filters
                  </p>
                )}
              </div>
            </div>
          </motion.div>
        )}

        {viewTab === "achievements" && (
          <motion.div
            key="achievements"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={spring.card}
            className="space-y-3"
          >
            <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">
              Travel Achievements
            </h3>
            <div className="grid grid-cols-2 gap-2.5">
              {achievements.map((ach, i) => {
                const AchIcon = getIcon(ach.icon);
                return (
                  <motion.div
                    key={ach.id}
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ ...spring.card, delay: i * 0.06 }}
                  >
                    <GlassCard
                      className={cn(
                        "text-center py-4 relative overflow-hidden",
                        !ach.unlocked && "opacity-40 grayscale"
                      )}
                      depth={ach.unlocked ? "md" : "sm"}
                    >
                      {ach.unlocked && (
                        <div
                          className={cn(
                            "absolute top-0 right-0 w-16 h-16 rounded-full blur-2xl opacity-20",
                            ach.gradient
                          )}
                        />
                      )}
                      <div
                        className={cn(
                          "w-10 h-10 rounded-xl flex items-center justify-center mx-auto mb-2 shadow-depth-sm",
                          ach.unlocked ? ach.gradient : "bg-secondary"
                        )}
                      >
                        <AchIcon
                          className={cn(
                            "w-5 h-5",
                            ach.unlocked ? "text-primary-foreground" : "text-muted-foreground"
                          )}
                          strokeWidth={1.8}
                        />
                      </div>
                      <p className="text-xs font-bold text-foreground">{ach.title}</p>
                      <p className="text-[10px] text-muted-foreground mt-0.5 leading-tight">
                        {ach.description}
                      </p>
                      {ach.unlocked && (
                        <span className="inline-block mt-2 text-[9px] px-2 py-0.5 rounded-full bg-accent/15 text-accent font-semibold">
                          Unlocked
                        </span>
                      )}
                    </GlassCard>
                  </motion.div>
                );
              })}
            </div>
          </motion.div>
        )}

        {viewTab === "continents" && (
          <motion.div
            key="continents"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={spring.card}
            className="space-y-3"
          >
            <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">
              Continent Progress
            </h3>
            {stats.continents.map((cont, i) => {
              const visited = cont.count > 0;
              return (
                <motion.div
                  key={cont.name}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ ...spring.card, delay: i * 0.06 }}
                >
                  <GlassCard depth="md" className={cn(!visited && "opacity-50")}>
                    <div className="flex items-center gap-3">
                      <div
                        className={cn(
                          "w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm",
                          visited ? "bg-gradient-ocean" : "bg-secondary"
                        )}
                      >
                        <Globe
                          className={cn(
                            "w-5 h-5",
                            visited ? "text-primary-foreground" : "text-muted-foreground"
                          )}
                          strokeWidth={1.8}
                        />
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-bold text-foreground">{cont.name}</p>
                        {visited ? (
                          <p className="text-xs text-muted-foreground">
                            {cont.countries.join(", ")}
                          </p>
                        ) : (
                          <p className="text-xs text-muted-foreground italic">Not yet visited</p>
                        )}
                      </div>
                      <div className="text-right">
                        <p className="text-lg font-bold text-foreground tabular-nums">{cont.count}</p>
                        <p className="text-[9px] text-muted-foreground uppercase">
                          {cont.count === 1 ? "country" : "countries"}
                        </p>
                      </div>
                    </div>
                    {/* Progress bar */}
                    <div className="mt-3 h-1.5 rounded-full bg-secondary/60 overflow-hidden">
                      <motion.div
                        className="h-full rounded-full bg-gradient-ocean"
                        initial={{ width: 0 }}
                        animate={{ width: `${Math.min((cont.count / 8) * 100, 100)}%` }}
                        transition={{ duration: 0.6, ease: easing.cinematic, delay: i * 0.1 }}
                      />
                    </div>
                  </GlassCard>
                </motion.div>
              );
            })}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default TravelTimeline;
