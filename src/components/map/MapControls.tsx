import React from "react";
import { motion } from "framer-motion";
import { Route, Plane, RotateCcw } from "lucide-react";
import { cn } from "@/lib/utils";
import { springs } from "@/hooks/useMotion";

interface MapControlsProps {
  showHistory: boolean;
  showAirports: boolean;
  onToggleHistory: () => void;
  onToggleAirports: () => void;
}

const MapControls: React.FC<MapControlsProps> = ({
  showHistory,
  showAirports,
  onToggleHistory,
  onToggleAirports,
}) => {
  const controls = [
    { icon: Route, label: "Routes", active: showHistory, onClick: onToggleHistory },
    { icon: Plane, label: "Airports", active: showAirports, onClick: onToggleAirports },
  ];

  return (
    <div className="absolute top-4 right-4 z-20 flex flex-col gap-2">
      {controls.map((ctrl) => {
        const Icon = ctrl.icon;
        return (
          <motion.button
            key={ctrl.label}
            onClick={ctrl.onClick}
            whileTap={{ scale: 0.92 }}
            transition={springs.snappy}
            className={cn(
              "flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold min-h-[38px]",
              "bg-background/60 backdrop-blur-[20px] border border-border/[0.15]",
              "shadow-[0_4px_20px_rgba(0,0,0,0.3)]",
              ctrl.active
                ? "text-primary border-primary/20"
                : "text-muted-foreground"
            )}
            aria-label={ctrl.label}
            aria-pressed={ctrl.active}
          >
            <Icon className="w-3.5 h-3.5" strokeWidth={1.8} />
            <span className="text-[11px]">{ctrl.label}</span>
          </motion.button>
        );
      })}
    </div>
  );
};

export default MapControls;
