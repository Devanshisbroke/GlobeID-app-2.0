import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { Zap } from "lucide-react";

const SPEEDS = [1, 5, 20];

interface Props {
  speed: number;
  onSpeedChange: (s: number) => void;
}

const SpeedControl: React.FC<Props> = ({ speed, onSpeedChange }) => {
  return (
    <div className="flex items-center gap-2">
      <Zap className="w-3 h-3 text-muted-foreground" />
      <span className="text-[10px] text-muted-foreground font-semibold uppercase tracking-widest">Speed</span>
      <div className="flex gap-1 ml-auto">
        {SPEEDS.map((s) => (
          <motion.button
            key={s}
            onClick={() => onSpeedChange(s)}
            whileTap={{ scale: 0.9 }}
            className={cn(
              "px-2.5 py-1 rounded-lg text-[10px] font-bold transition-colors",
              speed === s
                ? "bg-primary text-primary-foreground shadow-glow-sm"
                : "bg-secondary/60 text-muted-foreground hover:bg-secondary"
            )}
          >
            {s}x
          </motion.button>
        ))}
      </div>
    </div>
  );
};

export default SpeedControl;
