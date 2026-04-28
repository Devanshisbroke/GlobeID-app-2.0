import React from "react";
import { motion } from "framer-motion";
import { MapPin, Plane, Sparkles } from "lucide-react";
import { useTravelContext } from "@/hooks/useTravelContext";
import { cn } from "@/lib/utils";

/**
 * ContextBanner — surfaces the current location + active/next trip + flag count
 * at the top of Home. Renders a subtle one-liner; collapses entirely when no
 * meaningful context is available.
 *
 * Phase 9-β: this is the *visible proof* the context engine is wired.
 */
const ContextBanner: React.FC<{ className?: string }> = ({ className }) => {
  const ctx = useTravelContext();
  if (!ctx) return null;

  const { location, activeTrip, nextTrip, automationFlags } = ctx;

  const parts: { icon: typeof MapPin; label: string }[] = [];
  if (location.country) {
    parts.push({
      icon: MapPin,
      label:
        location.source === "wallet"
          ? `In ${location.country}`
          : location.source === "travel"
          ? `Last seen in ${location.country}`
          : `Home: ${location.country}`,
    });
  }
  if (activeTrip) {
    parts.push({ icon: Plane, label: `Active: ${activeTrip.destinationCountry}` });
  } else if (nextTrip) {
    parts.push({
      icon: Plane,
      label:
        nextTrip.daysAway === 0
          ? `Today: ${nextTrip.destinationCountry}`
          : `${nextTrip.destinationCountry} in ${nextTrip.daysAway}d`,
    });
  }
  if (automationFlags.length > 0) {
    parts.push({
      icon: Sparkles,
      label: `${automationFlags.length} flag${automationFlags.length === 1 ? "" : "s"}`,
    });
  }

  if (parts.length === 0) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: -4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className={cn(
        "flex items-center gap-3 px-3 py-1.5 text-[11px] text-muted-foreground",
        className,
      )}
      data-context-source={location.source}
    >
      {parts.map((p, i) => {
        const Icon = p.icon;
        return (
          <React.Fragment key={p.label}>
            {i > 0 ? <span className="text-foreground/20">·</span> : null}
            <span className="flex items-center gap-1">
              <Icon className="w-3 h-3 shrink-0" />
              <span className="truncate">{p.label}</span>
            </span>
          </React.Fragment>
        );
      })}
    </motion.div>
  );
};

export default ContextBanner;
