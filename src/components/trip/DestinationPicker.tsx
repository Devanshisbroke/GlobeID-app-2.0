import React, { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Search, Plus, X, MapPin } from "lucide-react";
import { airports, getAirport } from "@/lib/airports";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { cn } from "@/lib/utils";

const DestinationPicker: React.FC = () => {
  const [query, setQuery] = useState("");
  const { currentDestinations, addDestination, removeDestination } = useTripPlannerStore();

  const results = useMemo(() => {
    if (!query.trim()) return [];
    const q = query.toLowerCase();
    return airports
      .filter(
        (a) =>
          (a.city.toLowerCase().includes(q) ||
            a.iata.toLowerCase().includes(q) ||
            a.country.toLowerCase().includes(q)) &&
          !currentDestinations.includes(a.iata)
      )
      .slice(0, 6);
  }, [query, currentDestinations]);

  return (
    <div className="space-y-3">
      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search city or airport…"
          className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border/40 text-sm bg-transparent focus:outline-none focus:ring-2 focus:ring-primary/30 placeholder:text-muted-foreground"
        />
      </div>

      {/* Results */}
      <AnimatePresence>
        {results.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="glass rounded-xl border border-border/30 overflow-hidden divide-y divide-border/20"
          >
            {results.map((apt) => (
              <button
                key={apt.iata}
                onClick={() => { addDestination(apt.iata); setQuery(""); }}
                className="w-full flex items-center gap-3 px-3 py-2.5 hover:bg-primary/5 transition-colors text-left"
              >
                <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <MapPin className="w-4 h-4 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground truncate">{apt.city}</p>
                  <p className="text-xs text-muted-foreground">{apt.iata} · {apt.country}</p>
                </div>
                <Plus className="w-4 h-4 text-muted-foreground" />
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Selected destinations */}
      <div className="space-y-1.5">
        <AnimatePresence mode="popLayout">
          {currentDestinations.map((iata, idx) => {
            const apt = getAirport(iata);
            if (!apt) return null;
            return (
              <motion.div
                key={iata}
                layout
                initial={{ opacity: 0, x: -16 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 16, scale: 0.9 }}
                transition={{ type: "spring", stiffness: 300, damping: 25 }}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl glass border border-border/30"
              >
                <div className={cn(
                  "w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold",
                  idx === 0 ? "bg-accent text-accent-foreground" : "bg-primary/15 text-primary"
                )}>
                  {idx + 1}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground">{apt.city}</p>
                  <p className="text-xs text-muted-foreground">{apt.iata} · {apt.country}</p>
                </div>
                {idx < currentDestinations.length - 1 && (
                  <div className="text-xs text-muted-foreground/60">→</div>
                )}
                <button
                  onClick={() => removeDestination(iata)}
                  className="w-6 h-6 rounded-full hover:bg-destructive/10 flex items-center justify-center transition-colors"
                >
                  <X className="w-3.5 h-3.5 text-muted-foreground" />
                </button>
              </motion.div>
            );
          })}
        </AnimatePresence>
      </div>
    </div>
  );
};

export default DestinationPicker;
