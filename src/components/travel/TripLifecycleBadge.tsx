import React from "react";
import { cn } from "@/lib/utils";
import type { TripLifecycleState } from "@shared/types/lifecycle";

const palette: Record<TripLifecycleState, { bg: string; text: string; label: string }> = {
  planning: {
    bg: "bg-secondary/60",
    text: "text-muted-foreground",
    label: "Planning",
  },
  booked: {
    bg: "bg-primary/15",
    text: "text-primary",
    label: "Booked",
  },
  active: {
    bg: "bg-emerald-500/15",
    text: "text-emerald-500",
    label: "Active",
  },
  complete: {
    bg: "bg-foreground/8",
    text: "text-foreground/60",
    label: "Complete",
  },
};

const TripLifecycleBadge: React.FC<{
  state: TripLifecycleState;
  className?: string;
}> = ({ state, className }) => {
  const p = palette[state];
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded",
        p.bg,
        p.text,
        className,
      )}
      data-lifecycle-state={state}
    >
      {state === "active" ? (
        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
      ) : null}
      {p.label}
    </span>
  );
};

export default TripLifecycleBadge;
