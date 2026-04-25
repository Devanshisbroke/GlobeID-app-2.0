import React, { useState, lazy, Suspense } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowLeft, Globe, BarChart3, Sparkles, Radio } from "lucide-react";
import { cn } from "@/lib/utils";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { cinematicEase } from "@/cinematic/motionEngine";
import { getTopDestinations } from "@/lib/destinationAnalytics";

import IntelligenceHUD from "@/components/intelligence/IntelligenceHUD";
import DestinationCard from "@/components/intelligence/DestinationCard";
import TravelTrends from "@/components/intelligence/TravelTrends";

const GlobeScene = lazy(() => import("@/components/map/GlobeScene"));

const tabs = [
  { id: "overview" as const, label: "Overview", icon: Radio },
  { id: "destinations" as const, label: "Destinations", icon: Globe },
  { id: "trends" as const, label: "Trends", icon: BarChart3 },
];

const TravelIntelligence: React.FC = () => {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<"overview" | "destinations" | "trends">("overview");
  const [showGlobe, setShowGlobe] = useState(false);
  const topDests = getTopDestinations(8);

  return (
    <div className="space-y-0 pb-24">
      {/* Cinematic globe header */}
      <div className="relative h-56 overflow-hidden" style={{ touchAction: "pan-y" }}>
        {showGlobe ? (
          <Suspense fallback={<div className="w-full h-full bg-[#020617]" />}>
            {/* Decorative globe: not interactive, so vertical page scroll
                passes through the header instead of being captured by
                OrbitControls. */}
            <GlobeScene
              showHistory={false}
              showAirports={false}
              userLat={37.77}
              userLng={-122.42}
              interactive={false}
              autoRotate
            />
          </Suspense>
        ) : (
          <div className="w-full h-full bg-gradient-to-b from-[hsl(var(--ocean-deep))] to-background flex items-center justify-center">
            <motion.button
              onClick={() => setShowGlobe(true)}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex flex-col items-center gap-2"
            >
              <Globe className="w-10 h-10 text-primary/60" />
              <span className="text-xs text-muted-foreground">Tap to load globe</span>
            </motion.button>
          </div>
        )}

        {/* Overlay gradient */}
        <div className="absolute inset-x-0 bottom-0 h-20 bg-gradient-to-t from-background to-transparent" />

        {/* Back button */}
        <button
          onClick={() => navigate(-1)}
          className="absolute top-4 left-4 w-9 h-9 rounded-xl glass flex items-center justify-center active:scale-90 transition-transform z-10"
        >
          <ArrowLeft className="w-4.5 h-4.5 text-foreground" />
        </button>

        {/* Title */}
        <div className="absolute bottom-4 left-4 right-4 z-10">
          <h1 className="text-lg font-bold text-foreground flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-accent" />
            Travel Intelligence
          </h1>
          <p className="text-xs text-muted-foreground mt-0.5">Global travel analytics & predictions</p>
        </div>
      </div>

      <div className="px-4 space-y-5 pt-2">
        {/* HUD Stats */}
        <AnimatedPage>
          <IntelligenceHUD />
        </AnimatedPage>

        {/* Tab bar */}
        <div className="flex gap-1 p-1 rounded-xl bg-secondary/50">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={cn(
                  "flex-1 flex items-center justify-center gap-1.5 text-[11px] font-medium py-2 rounded-lg transition-all",
                  activeTab === tab.id ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
                )}
              >
                <Icon className="w-3.5 h-3.5" />
                {tab.label}
              </button>
            );
          })}
        </div>

        {/* Tab content */}
        <AnimatePresence mode="wait">
          {activeTab === "overview" && (
            <motion.div key="overview" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3, ease: cinematicEase }} className="space-y-3">
              <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Top Destinations</p>
              {topDests.slice(0, 5).map((d, i) => (
                <DestinationCard key={d.iata} dest={d} rank={i + 1} index={i} />
              ))}
            </motion.div>
          )}
          {activeTab === "destinations" && (
            <motion.div key="destinations" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3, ease: cinematicEase }} className="space-y-2">
              {topDests.map((d, i) => (
                <DestinationCard key={d.iata} dest={d} rank={i + 1} index={i} />
              ))}
            </motion.div>
          )}
          {activeTab === "trends" && (
            <motion.div key="trends" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3, ease: cinematicEase }}>
              <TravelTrends />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
};

export default TravelIntelligence;
