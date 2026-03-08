import React from "react";
import { motion } from "framer-motion";
import { Slider } from "@/components/ui/slider";
import { getTimeMultiplier } from "@/simulation/PlanetSimulation";
import { Clock } from "lucide-react";

interface Props {
  hour: number;
  onHourChange: (h: number) => void;
}

const TravelTimeline: React.FC<Props> = ({ hour, onHourChange }) => {
  const mult = getTimeMultiplier(hour);
  const label = `${hour.toString().padStart(2, "0")}:00`;
  const isPeak = mult > 0.7;

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1.5">
          <Clock className="w-3 h-3 text-muted-foreground" />
          <span className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold">Time of Day</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="text-xs font-bold text-foreground tabular-nums">{label}</span>
          {isPeak && (
            <motion.span
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-[9px] px-1.5 py-0.5 rounded-full bg-accent/15 text-accent font-semibold"
            >
              Peak
            </motion.span>
          )}
        </div>
      </div>

      <Slider
        value={[hour]}
        onValueChange={([v]) => onHourChange(v)}
        min={0}
        max={23}
        step={1}
        className="w-full"
      />

      {/* Mini sparkline */}
      <div className="flex items-end gap-px h-6">
        {Array.from({ length: 24 }, (_, h) => {
          const m = getTimeMultiplier(h);
          return (
            <div
              key={h}
              className="flex-1 rounded-t-sm transition-all duration-200"
              style={{
                height: `${m * 100}%`,
                background: h === hour
                  ? "hsl(var(--accent))"
                  : `hsl(var(--primary) / ${0.15 + m * 0.3})`,
              }}
            />
          );
        })}
      </div>
    </div>
  );
};

export default TravelTimeline;
