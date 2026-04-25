import React from "react";
import { motion } from "framer-motion";
import { MapPin, Star, Calendar, X, Utensils, Mountain } from "lucide-react";
import { type Destination } from "@/lib/explorerData";
import { cn } from "@/lib/utils";

interface Props {
  destination: Destination;
  onClose: () => void;
}

const DestinationCard: React.FC<Props> = ({ destination, onClose }) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 40, scale: 0.95 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: 40, scale: 0.95 }}
      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      className="glass border border-border/30 rounded-2xl overflow-hidden shadow-depth-lg"
    >
      {/* Hero gradient */}
      <div className="relative h-32 bg-gradient-to-br from-primary/30 via-accent/20 to-primary/10 flex items-end p-4">
        <div className="absolute inset-0 bg-gradient-to-t from-background/80 to-transparent" />
        <motion.button
          onClick={onClose}
          whileTap={{ scale: 0.9 }}
          className="absolute top-3 right-3 w-8 h-8 rounded-full glass border border-border/30 flex items-center justify-center z-10"
        >
          <X className="w-4 h-4 text-foreground" />
        </motion.button>
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-1">
            <span className="text-2xl">{destination.emoji}</span>
            <h3 className="text-xl font-bold text-foreground">{destination.city}</h3>
          </div>
          <div className="flex items-center gap-1.5 text-muted-foreground">
            <MapPin className="w-3 h-3" />
            <span className="text-xs">{destination.country} · {destination.continent}</span>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-3">
        <p className="text-xs text-muted-foreground leading-relaxed">{destination.description}</p>

        {/* Stats */}
        <div className="flex gap-2">
          <div className="flex items-center gap-1 px-2 py-1 rounded-lg bg-accent/10 border border-accent/20">
            <Star className="w-3 h-3 text-accent" />
            <span className="text-[10px] font-bold text-accent">{destination.popularity}</span>
          </div>
          <div className="flex items-center gap-1 px-2 py-1 rounded-lg bg-primary/10 border border-primary/20">
            <Calendar className="w-3 h-3 text-primary" />
            <span className="text-[10px] font-bold text-primary">{destination.bestSeason}</span>
          </div>
        </div>

        {/* Highlights */}
        <div>
          <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold mb-1.5">Highlights</p>
          <div className="flex flex-wrap gap-1">
            {destination.highlights.map((h) => (
              <span key={h} className="text-[10px] px-2 py-0.5 rounded-full bg-secondary/60 text-foreground border border-border/20">
                {h}
              </span>
            ))}
          </div>
        </div>

        {/* Cuisine */}
        <div>
          <div className="flex items-center gap-1 mb-1.5">
            <Utensils className="w-3 h-3 text-muted-foreground" />
            <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold">Cuisine</p>
          </div>
          <div className="flex flex-wrap gap-1">
            {destination.cuisine.map((c) => (
              <span key={c} className="text-[10px] px-2 py-0.5 rounded-full bg-warning/10 text-warning border border-warning/20">
                {c}
              </span>
            ))}
          </div>
        </div>

        {/* Landmarks */}
        <div>
          <div className="flex items-center gap-1 mb-1.5">
            <Mountain className="w-3 h-3 text-muted-foreground" />
            <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold">Landmarks</p>
          </div>
          <div className="flex flex-wrap gap-1">
            {destination.landmarks.map((l) => (
              <span key={l} className="text-[10px] px-2 py-0.5 rounded-full bg-accent/10 text-accent border border-accent/20">
                {l}
              </span>
            ))}
          </div>
        </div>
      </div>
    </motion.div>
  );
};

export default DestinationCard;
