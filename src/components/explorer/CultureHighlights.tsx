import React from "react";
import { motion } from "framer-motion";
import { type Destination } from "@/lib/explorerData";
import { Sparkles, Music, BookOpen, UtensilsCrossed } from "lucide-react";

interface Props {
  destination: Destination;
}

const categories = [
  { label: "Festivals & Culture", icon: Music, items: (d: Destination) => d.highlights, colorVar: "--accent" },
  { label: "Cuisine", icon: UtensilsCrossed, items: (d: Destination) => d.cuisine, colorVar: "--sunset-gold" },
  { label: "Historical Sites", icon: BookOpen, items: (d: Destination) => d.landmarks, colorVar: "--aurora-purple" },
];

const CultureHighlights: React.FC<Props> = ({ destination }) => {
  return (
    <div className="space-y-2">
      {categories.map((cat, ci) => {
        const Icon = cat.icon;
        const items = cat.items(destination);
        return (
          <motion.div
            key={cat.label}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: ci * 0.08 }}
            className="glass border border-border/30 rounded-xl p-3"
          >
            <div className="flex items-center gap-1.5 mb-2">
              <Icon className="w-3.5 h-3.5" style={{ color: `hsl(var(${cat.colorVar}))` }} strokeWidth={1.8} />
              <span className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold">{cat.label}</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {items.map((item) => (
                <span key={item} className="text-[10px] px-2 py-1 rounded-lg bg-secondary/50 text-foreground border border-border/20">
                  {item}
                </span>
              ))}
            </div>
          </motion.div>
        );
      })}
    </div>
  );
};

export default CultureHighlights;
