import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Plane, AlertCircle, Clock, MapPin, Info } from "lucide-react";
import { cn } from "@/lib/utils";
import { useLifecycleStore } from "@/store/lifecycleStore";
import type { FlightStatus, FlightStatusKind } from "@shared/types/lifecycle";

const statusPalette: Record<
  FlightStatusKind,
  { label: string; tone: string; bg: string }
> = {
  scheduled: { label: "Scheduled", tone: "text-primary", bg: "bg-primary/10" },
  boarding: { label: "Boarding", tone: "text-emerald-500", bg: "bg-emerald-500/10" },
  departed: { label: "Departed", tone: "text-emerald-600", bg: "bg-emerald-500/10" },
  in_air: { label: "In air", tone: "text-emerald-500", bg: "bg-emerald-500/10" },
  landed: { label: "Landed", tone: "text-foreground/60", bg: "bg-foreground/8" },
  delayed: { label: "Delayed", tone: "text-amber-500", bg: "bg-amber-500/10" },
  cancelled: { label: "Cancelled", tone: "text-destructive", bg: "bg-destructive/10" },
};

interface FlightStatusCardProps {
  legId: string;
  className?: string;
}

const FlightStatusCard: React.FC<FlightStatusCardProps> = ({ legId, className }) => {
  const cached = useLifecycleStore((s) => s.flightStatuses[legId]);
  const fetchFlightStatus = useLifecycleStore((s) => s.fetchFlightStatus);
  const [status, setStatus] = useState<FlightStatus | null>(cached ?? null);
  const [loading, setLoading] = useState(!cached);

  useEffect(() => {
    if (cached) {
      setStatus(cached);
      setLoading(false);
      return;
    }
    let mounted = true;
    setLoading(true);
    void fetchFlightStatus(legId).then((s) => {
      if (!mounted) return;
      setStatus(s);
      setLoading(false);
    });
    return () => {
      mounted = false;
    };
  }, [legId, cached, fetchFlightStatus]);

  if (loading) {
    return (
      <div
        className={cn(
          "rounded-xl border border-border bg-card p-3 animate-pulse h-24",
          className,
        )}
      />
    );
  }
  if (!status) {
    return (
      <div
        className={cn(
          "rounded-xl border border-border bg-card p-3 flex items-center gap-2 text-xs text-muted-foreground",
          className,
        )}
      >
        <AlertCircle className="w-4 h-4" />
        Flight status unavailable.
      </div>
    );
  }

  const p = statusPalette[status.statusKind];
  const showDelay = status.statusKind === "delayed" && status.delayMinutes > 0;

  return (
    <motion.div
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      className={cn("rounded-xl border border-border bg-card p-3 space-y-2", className)}
      data-flight-status={status.statusKind}
      data-flight-id={status.id}
    >
      <div className="flex items-start gap-2">
        <Plane className={cn("w-4 h-4 mt-0.5", p.tone)} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="text-sm font-semibold text-foreground truncate">
              {status.flightNumber ?? status.airline}
            </p>
            <span
              className={cn(
                "text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded",
                p.bg,
                p.tone,
              )}
            >
              {p.label}
            </span>
          </div>
          <p className="text-[11.5px] text-muted-foreground mt-0.5 font-mono">
            {status.fromIata} → {status.toIata} · {status.scheduledDate}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-3 text-[11px] text-muted-foreground pl-6">
        {status.gate ? (
          <span className="flex items-center gap-1">
            <MapPin className="w-3 h-3" /> Gate {status.gate}
            {status.terminal ? ` · ${status.terminal}` : ""}
          </span>
        ) : null}
        {showDelay ? (
          <span className="flex items-center gap-1 text-amber-500">
            <Clock className="w-3 h-3" /> +{status.delayMinutes}m
          </span>
        ) : null}
      </div>

      {/* Required surface marker — Phase 9-β honors "no fake features" by
          always showing the demo flag. */}
      <div className="flex items-start gap-1.5 text-[10px] text-muted-foreground/70 italic pt-1.5 border-t border-border">
        <Info className="w-3 h-3 shrink-0 mt-0.5" />
        <span className="leading-tight">{status.demoNote}</span>
      </div>
    </motion.div>
  );
};

export default FlightStatusCard;
