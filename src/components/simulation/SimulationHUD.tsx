import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { getSimulationStats } from "@/simulation/PlanetSimulation";
import { Plane, Users, Route, Zap } from "lucide-react";

function useAnimatedCounter(target: number, duration = 1200): number {
  const [val, setVal] = useState(0);
  useEffect(() => {
    const start = performance.now();
    let rafId = 0;
    const tick = (now: number) => {
      const p = Math.min((now - start) / duration, 1);
      setVal(Math.round(target * (1 - Math.pow(1 - p, 3))));
      if (p < 1) rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafId);
  }, [target, duration]);
  return val;
}

interface Props {
  speed: number;
}

const SimulationHUD: React.FC<Props> = ({ speed }) => {
  const stats = getSimulationStats(speed);
  const flights = useAnimatedCounter(stats.flightsSimulated);
  const passengers = useAnimatedCounter(stats.passengersSimulated);
  const routes = useAnimatedCounter(stats.routesActive);

  const items = [
    { icon: Plane, label: "Flights", value: flights.toLocaleString(), color: "text-primary" },
    { icon: Users, label: "Passengers", value: passengers.toLocaleString(), color: "text-accent" },
    { icon: Route, label: "Routes", value: routes.toLocaleString(), color: "text-warning" },
  ];

  return (
    <div className="flex gap-2">
      {items.map((item) => {
        const Icon = item.icon;
        return (
          <GlassCard key={item.label} className="flex-1 py-2 px-2.5 text-center" interactive={false}>
            <Icon className={`w-3.5 h-3.5 mx-auto mb-1 ${item.color}`} strokeWidth={1.8} />
            <p className="text-xs font-bold text-foreground tabular-nums">{item.value}</p>
            <p className="text-[9px] text-muted-foreground">{item.label}</p>
          </GlassCard>
        );
      })}
    </div>
  );
};

export default SimulationHUD;
