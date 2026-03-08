import React, { lazy, Suspense, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useTripPlannerStore, type TripTheme } from "@/store/tripPlannerStore";
import DestinationPicker from "@/components/trip/DestinationPicker";
import TripSummary from "@/components/trip/TripSummary";
import TripProgressBar from "@/components/trip/TripProgressBar";
import { haptics } from "@/utils/haptics";
import {
  Save, Trash2, ArrowLeft, Palmtree, Briefcase, Mountain, Globe2,
  Bookmark, ChevronDown, Plus,
} from "lucide-react";
import { cn } from "@/lib/utils";

const themeOptions: { key: TripTheme; label: string; icon: React.ElementType; gradient: string }[] = [
  { key: "vacation", label: "Vacation", icon: Palmtree, gradient: "from-cyan-500/20 to-blue-500/20" },
  { key: "business", label: "Business", icon: Briefcase, gradient: "from-slate-500/20 to-zinc-500/20" },
  { key: "backpacking", label: "Backpacking", icon: Mountain, gradient: "from-emerald-500/20 to-lime-500/20" },
  { key: "world_tour", label: "World Tour", icon: Globe2, gradient: "from-violet-500/20 to-purple-500/20" },
];

const TripPlanner: React.FC = () => {
  const navigate = useNavigate();
  const {
    currentDestinations, currentName, currentTheme, savedTrips,
    setCurrentName, setCurrentTheme, saveCurrentTrip, clearCurrent,
    loadTrip, deleteTrip,
  } = useTripPlannerStore();
  const [showSaved, setShowSaved] = useState(false);

  const handleSave = () => {
    if (currentDestinations.length < 2) return;
    haptics.success();
    saveCurrentTrip();
  };

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        {/* Header */}
        <div className="flex items-center gap-3 mb-2">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-foreground">Trip Planner</h1>
            <p className="text-xs text-muted-foreground">Design your journey on the globe</p>
          </div>
          <button
            onClick={() => setShowSaved(!showSaved)}
            className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center relative"
          >
            <Bookmark className="w-4 h-4 text-foreground" />
            {savedTrips.length > 0 && (
              <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-primary text-primary-foreground text-[9px] font-bold flex items-center justify-center">
                {savedTrips.length}
              </span>
            )}
          </button>
        </div>

        {/* Saved trips dropdown */}
        <AnimatePresence>
          {showSaved && savedTrips.length > 0 && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              className="overflow-hidden"
            >
              <GlassCard interactive={false} className="space-y-2 mb-4">
                <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Saved Trips</p>
                {savedTrips.map((trip) => (
                  <div key={trip.id} className="flex items-center gap-2 p-2 rounded-lg hover:bg-primary/5 transition-colors">
                    <button onClick={() => { loadTrip(trip.id); setShowSaved(false); }} className="flex-1 text-left">
                      <p className="text-sm font-medium text-foreground">{trip.name}</p>
                      <p className="text-[10px] text-muted-foreground">
                        {trip.destinations.join(" → ")} · {trip.theme}
                      </p>
                    </button>
                    <button onClick={() => deleteTrip(trip.id)} className="w-6 h-6 rounded-full hover:bg-destructive/10 flex items-center justify-center">
                      <Trash2 className="w-3 h-3 text-muted-foreground" />
                    </button>
                  </div>
                ))}
              </GlassCard>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Trip name */}
        <GlassCard interactive={false} className="space-y-3">
          <input
            value={currentName}
            onChange={(e) => setCurrentName(e.target.value)}
            className="w-full bg-transparent text-lg font-bold text-foreground focus:outline-none placeholder:text-muted-foreground"
            placeholder="Trip name…"
          />

          {/* Theme selector */}
          <div className="flex gap-2">
            {themeOptions.map((t) => {
              const Icon = t.icon;
              const active = currentTheme === t.key;
              return (
                <button
                  key={t.key}
                  onClick={() => setCurrentTheme(t.key)}
                  className={cn(
                    "flex-1 py-2 rounded-xl text-xs font-medium transition-all flex flex-col items-center gap-1",
                    active
                      ? `bg-gradient-to-br ${t.gradient} border border-primary/30 text-foreground`
                      : "glass border border-border/20 text-muted-foreground"
                  )}
                >
                  <Icon className="w-4 h-4" />
                  {t.label}
                </button>
              );
            })}
          </div>
        </GlassCard>

        {/* Progress bar */}
        <TripProgressBar />

        {/* Destination picker */}
        <GlassCard interactive={false} className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-foreground">Destinations</h2>
            <span className="text-[10px] text-muted-foreground">{currentDestinations.length} stops</span>
          </div>
          <DestinationPicker />
        </GlassCard>

        {/* Trip summary */}
        <GlassCard interactive={false}>
          <h2 className="text-sm font-semibold text-foreground mb-3">Trip Summary</h2>
          <TripSummary />
        </GlassCard>

        {/* Actions */}
        <div className="flex gap-3">
          <button
            onClick={handleSave}
            disabled={currentDestinations.length < 2}
            className={cn(
              "flex-1 py-3 rounded-xl text-sm font-semibold flex items-center justify-center gap-2 transition-all",
              currentDestinations.length >= 2
                ? "bg-primary text-primary-foreground shadow-glow-sm"
                : "glass border border-border/30 text-muted-foreground opacity-50"
            )}
          >
            <Save className="w-4 h-4" />
            Save Trip
          </button>
          <button
            onClick={() => { clearCurrent(); haptics.selection(); }}
            className="px-4 py-3 rounded-xl glass border border-border/30 text-sm text-muted-foreground"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </AnimatedPage>
    </div>
  );
};

export default TripPlanner;
