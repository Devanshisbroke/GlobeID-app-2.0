import React from "react";
import { motion } from "framer-motion";
import { Sparkles, Utensils, Landmark, Compass } from "lucide-react";
import { type Destination } from "@/lib/explorerData";

interface Props {
  destination: Destination;
}

const sections = [
  { key: "highlights", label: "Culture & Experiences", icon: Sparkles, colorClass: "text-accent" },
  { key: "cuisine", label: "Local Cuisine", icon: Utensils, colorClass: "text-sunset-gold" },
  { key: "landmarks", label: "Must-See Landmarks", icon: Landmark, colorClass: "text-primary" },
] as const;

const DestinationStory: React.FC<Props> = ({ destination }) => {
  return (
    <div className="space-y-3">
      {sections.map((section, si) => {
        const Icon = section.icon;
        const items = destination[section.key];
        return (
          <motion.div
            key={section.key}
            initial={{ opacity: 0, x: -12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: si * 0.1, duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="glass border border-border/30 rounded-xl p-3"
          >
            <div className="flex items-center gap-1.5 mb-2">
              <Icon className={`w-3.5 h-3.5 ${section.colorClass}`} strokeWidth={1.8} />
              <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest">{section.label}</span>
            </div>
            <div className="grid grid-cols-2 gap-1.5">
              {items.map((item, i) => (
                <motion.div
                  key={item}
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: si * 0.1 + i * 0.05 }}
                  className="text-xs text-foreground bg-secondary/40 rounded-lg px-2.5 py-1.5 border border-border/20"
                >
                  {item}
                </motion.div>
              ))}
            </div>
          </motion.div>
        );
      })}
    </div>
  );
};

export default DestinationStory;
