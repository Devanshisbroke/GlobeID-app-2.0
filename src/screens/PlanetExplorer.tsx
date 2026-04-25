import React, { useState, useCallback, lazy, Suspense } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, Compass, Map, Award, Sparkles, Route } from "lucide-react";
import { cn } from "@/lib/utils";
import { GlassCard } from "@/components/ui/GlassCard";
import { destinations, explorationPaths, type Destination } from "@/lib/explorerData";
import DestinationCard from "@/components/explorer/DestinationCard";
import DiscoveryFeed from "@/components/explorer/DiscoveryFeed";
import CultureHighlights from "@/components/explorer/CultureHighlights";
import ExplorerHUD from "@/components/explorer/ExplorerHUD";
import DiscoveryAchievements from "@/components/explorer/DiscoveryAchievements";
import { springs } from "@/hooks/useMotion";

const GlobeScene = lazy(() => import("@/components/map/GlobeScene"));

type Tab = "discover" | "paths" | "achievements";

const PlanetExplorer: React.FC = () => {
  const navigate = useNavigate();
  const [selectedDest, setSelectedDest] = useState<Destination | null>(null);
  const [discoveredIds, setDiscoveredIds] = useState<string[]>(["paris", "tokyo", "newyork"]);
  const [activeTab, setActiveTab] = useState<Tab>("discover");
  const [activePath, setActivePath] = useState<string | undefined>();
  const [showPanel, setShowPanel] = useState(true);

  const handleSelect = useCallback((d: Destination) => {
    setSelectedDest(d);
    if (!discoveredIds.includes(d.id)) {
      setDiscoveredIds((prev) => [...prev, d.id]);
    }
  }, [discoveredIds]);

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: "discover", label: "Discover", icon: Compass },
    { key: "paths", label: "Paths", icon: Route },
    { key: "achievements", label: "Awards", icon: Award },
  ];

  return (
    <div className="relative min-h-[100dvh] -mx-4 -mt-6" style={{ marginBottom: "-5rem" }}>
      {/* 3D Globe */}
      <div
        className="absolute inset-0"
        style={{ background: "#020617", touchAction: "none" }}
      >
        <Suspense
          fallback={
            <div className="flex items-center justify-center h-full flex-col gap-3">
              <div className="w-8 h-8 rounded-full border-2 border-primary/40 border-t-primary animate-spin" />
              <p className="text-xs text-muted-foreground font-medium tracking-wider animate-pulse">Rendering Planet…</p>
            </div>
          }
        >
          <motion.div
            className="w-full h-full"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.5, ease: "easeOut" }}
          >
            <GlobeScene
              showHistory={false}
              showAirports={false}
              userLat={selectedDest?.lat ?? 20}
              userLng={selectedDest?.lng ?? 0}
              showIntelligence={false}
              showExplorer
              explorerPathId={activePath}
              discoveredIds={discoveredIds}
            />
          </motion.div>
        </Suspense>
      </div>

      {/* Top bar */}
      <div className="absolute top-4 left-4 right-4 z-20 flex items-center gap-2">
        <motion.button
          onClick={() => navigate(-1)}
          whileTap={{ scale: 0.9 }}
          className="w-10 h-10 rounded-full bg-background/60 backdrop-blur-xl border border-border/[0.15] flex items-center justify-center shadow-depth-sm"
        >
          <ArrowLeft className="w-4 h-4 text-foreground" />
        </motion.button>
        <div className="flex-1 flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-accent" />
          <span className="text-sm font-bold text-foreground">Planet Explorer</span>
        </div>
        <motion.button
          onClick={() => setShowPanel(!showPanel)}
          whileTap={{ scale: 0.9 }}
          className={cn(
            "px-3 py-2 rounded-xl border shadow-depth-sm transition-colors backdrop-blur-xl",
            showPanel
              ? "bg-primary/20 border-primary/40 text-primary"
              : "bg-background/60 border-border/[0.15] text-muted-foreground"
          )}
        >
          <Map className="w-3.5 h-3.5" />
        </motion.button>
      </div>

      {/* Explorer HUD */}
      <div className="absolute top-16 left-4 right-4 z-10">
        <ExplorerHUD discoveredIds={discoveredIds} currentDestination={selectedDest?.id} />
      </div>

      {/* Selected destination card */}
      <AnimatePresence>
        {selectedDest && !showPanel && (
          <div className="absolute bottom-24 left-4 right-4 z-20">
            <DestinationCard destination={selectedDest} onClose={() => setSelectedDest(null)} />
          </div>
        )}
      </AnimatePresence>

      {/* Bottom Panel — scrollable with proper touch-action */}
      <AnimatePresence>
        {showPanel && (
          <motion.div
            initial={{ y: 300, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 300, opacity: 0 }}
            transition={springs.gentle}
            className="absolute bottom-20 left-0 right-0 z-10 px-4 pb-2 max-h-[55vh] overflow-y-auto overscroll-contain space-y-3"
            style={{ touchAction: "pan-y", WebkitOverflowScrolling: "touch" }}
          >
            {/* Tab bar */}
            <div className="flex gap-1 p-1 glass border border-border/30 rounded-xl">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                const active = activeTab === tab.key;
                return (
                  <motion.button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key)}
                    whileTap={{ scale: 0.95 }}
                    className={cn(
                      "flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-[10px] font-bold uppercase tracking-wider transition-colors",
                      active ? "bg-primary text-primary-foreground shadow-glow-sm" : "text-muted-foreground"
                    )}
                  >
                    <Icon className="w-3 h-3" strokeWidth={2} />
                    {tab.label}
                  </motion.button>
                );
              })}
            </div>

            {/* Selected destination details */}
            <AnimatePresence mode="wait">
              {selectedDest && activeTab === "discover" && (
                <motion.div
                  key="dest-detail"
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -12 }}
                >
                  <DestinationCard destination={selectedDest} onClose={() => setSelectedDest(null)} />
                  <div className="mt-3">
                    <CultureHighlights destination={selectedDest} />
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Discovery feed */}
            {activeTab === "discover" && !selectedDest && (
              <DiscoveryFeed onSelect={handleSelect} discoveredIds={discoveredIds} />
            )}

            {/* Exploration paths */}
            {activeTab === "paths" && (
              <div className="space-y-2">
                <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold px-1">Exploration Routes</p>
                {explorationPaths.map((path) => (
                  <motion.button
                    key={path.id}
                    onClick={() => setActivePath(activePath === path.id ? undefined : path.id)}
                    whileTap={{ scale: 0.97 }}
                    className={cn(
                      "w-full glass border rounded-xl p-3 text-left transition-colors",
                      activePath === path.id ? "border-primary/40" : "border-border/30"
                    )}
                  >
                    <div className="flex items-center gap-2 mb-1">
                      <div className="w-2.5 h-2.5 rounded-full" style={{ background: path.color }} />
                      <span className="text-xs font-bold text-foreground">{path.name}</span>
                    </div>
                    <p className="text-[10px] text-muted-foreground mb-2">{path.description}</p>
                    <div className="flex gap-1 flex-wrap">
                      {path.stops.map((stopId) => {
                        const d = destinations.find((dd) => dd.id === stopId);
                        return d ? (
                          <span
                            key={stopId}
                            onClick={(e) => { e.stopPropagation(); handleSelect(d); }}
                            className="text-[10px] px-2 py-0.5 rounded-full bg-secondary/60 text-foreground border border-border/20 cursor-pointer hover:border-primary/30"
                          >
                            {d.emoji} {d.city}
                          </span>
                        ) : null;
                      })}
                    </div>
                  </motion.button>
                ))}
              </div>
            )}

            {/* Achievements */}
            {activeTab === "achievements" && (
              <DiscoveryAchievements discoveredIds={discoveredIds} landmarkCount={3} />
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default PlanetExplorer;
