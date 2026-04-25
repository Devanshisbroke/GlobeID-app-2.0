import React, { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Plane, Users, Route, MapPin, Activity } from "lucide-react";
import { cn } from "@/lib/utils";
import { getGlobalStats, type GlobalStats } from "@/lib/destinationAnalytics";
import { cinematicEase } from "@/cinematic/motionEngine";

function useAnimatedNumber(target: number, duration = 2000): number {
  const [value, setValue] = useState(0);
  useEffect(() => {
    const start = performance.now();
    let rafId = 0;
    const animate = (now: number) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setValue(Math.round(target * eased));
      if (progress < 1) rafId = requestAnimationFrame(animate);
    };
    rafId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(rafId);
  }, [target, duration]);
  return value;
}

function formatNum(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(0)}K`;
  return n.toLocaleString();
}

const IntelligenceHUD: React.FC<{ className?: string }> = ({ className }) => {
  const stats = getGlobalStats();
  const flights = useAnimatedNumber(stats.totalFlightsToday);
  const passengers = useAnimatedNumber(stats.totalPassengers);
  const routes = useAnimatedNumber(stats.totalRoutes);

  const items = [
    { icon: Plane, label: "Flights Today", value: formatNum(flights), color: "from-[hsl(var(--primary))] to-[hsl(var(--ocean-aqua))]" },
    { icon: Users, label: "Passengers", value: formatNum(passengers), color: "from-[hsl(var(--accent))] to-[hsl(var(--ocean-turquoise))]" },
    { icon: Route, label: "Active Routes", value: formatNum(routes), color: "from-[hsl(var(--ocean-deep))] to-[hsl(var(--primary))]" },
  ];

  return (
    <div className={cn("space-y-3", className)}>
      <div className="grid grid-cols-3 gap-2">
        {items.map((item, i) => {
          const Icon = item.icon;
          return (
            <motion.div
              key={item.label}
              initial={{ opacity: 0, y: 12, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ delay: i * 0.08, duration: 0.45, ease: cinematicEase }}
              className="glass rounded-xl p-3 text-center"
            >
              <div className={cn("w-8 h-8 mx-auto rounded-lg bg-gradient-to-br flex items-center justify-center mb-1.5", item.color)}>
                <Icon className="w-4 h-4 text-primary-foreground" />
              </div>
              <p className="text-sm font-bold text-foreground">{item.value}</p>
              <p className="text-[9px] text-muted-foreground">{item.label}</p>
            </motion.div>
          );
        })}
      </div>

      {/* Live indicators */}
      <div className="flex items-center justify-between glass rounded-lg p-2.5">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-accent animate-pulse" />
          <span className="text-[10px] text-muted-foreground">Live</span>
        </div>
        <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
          <MapPin className="w-3 h-3" />
          Top: {stats.topRoute}
        </div>
        <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
          <Activity className="w-3 h-3" />
          #{stats.mostPopularCity}
        </div>
      </div>
    </div>
  );
};

export default IntelligenceHUD;
