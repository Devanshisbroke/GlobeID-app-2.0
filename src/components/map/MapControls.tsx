import React from "react";
import { motion } from "motion/react";
import { Route, Plane } from "lucide-react";
import { spring } from "@/components/ui/v2";
import { cn } from "@/lib/utils";

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
            whileTap={{ scale: 0.94 }}
            transition={spring.snap}
            className={cn(
              "flex items-center gap-2 px-3 py-2 rounded-p7-input text-p7-caption-1",
              "bg-[hsl(var(--p7-glass-tint))] border border-surface-hairline",
              "[backdrop-filter:blur(var(--p7-glass-blur))_saturate(1.4)]",
              "[-webkit-backdrop-filter:blur(var(--p7-glass-blur))_saturate(1.4)]",
              "shadow-p7-sm min-h-[38px] transition-colors",
              ctrl.active ? "text-brand" : "text-ink-secondary",
            )}
            aria-label={ctrl.label}
            aria-pressed={ctrl.active}
          >
            <Icon className="w-3.5 h-3.5" strokeWidth={1.8} />
            <span>{ctrl.label}</span>
          </motion.button>
        );
      })}
    </div>
  );
};

export default MapControls;
