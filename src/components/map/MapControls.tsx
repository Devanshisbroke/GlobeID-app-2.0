import React from "react";
import { motion } from "framer-motion";
import { ZoomIn, ZoomOut, LocateFixed, Route, Plane, Layers } from "lucide-react";
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
    { icon: Route, label: "Travel History", active: showHistory, onClick: onToggleHistory },
    { icon: Plane, label: "Airports", active: showAirports, onClick: onToggleAirports },
  ];

  return (
    <>
      {/* Toggle buttons — top right */}
      <div className="absolute top-4 left-4 z-20 flex flex-col gap-2">
        {controls.map((ctrl) => {
          const Icon = ctrl.icon;
          return (
            <motion.button
              key={ctrl.label}
              onClick={ctrl.onClick}
              whileTap={{ scale: 0.92 }}
              transition={springs.snappy}
              className={cn(
                "flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold min-h-[40px]",
                "glass border border-border/30 backdrop-blur-xl",
                ctrl.active
                  ? "text-primary border-primary/30 shadow-glow-sm"
                  : "text-muted-foreground"
              )}
              aria-label={ctrl.label}
              aria-pressed={ctrl.active}
            >
              <Icon className="w-4 h-4" strokeWidth={1.8} />
              <span className="hidden sm:inline">{ctrl.label}</span>
            </motion.button>
          );
        })}
      </div>
    </>
  );
};

export default MapControls;
