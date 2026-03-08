import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { useAlertsStore } from "@/store/alertsStore";
import { ShieldCheck, Plane, AlertTriangle, Bell, X } from "lucide-react";
import { cn } from "@/lib/utils";

const alertIcons = {
  visa_change: ShieldCheck,
  flight_disruption: Plane,
  advisory: AlertTriangle,
  info: Bell,
};

const severityStyles = {
  high: "border-destructive/30 bg-destructive/5",
  medium: "border-neon-amber/30 bg-neon-amber/5",
  low: "border-border/30",
};

const severityColors = {
  high: "text-destructive",
  medium: "text-neon-amber",
  low: "text-muted-foreground",
};

const TravelAlerts: React.FC = () => {
  const { alerts, markRead, dismissAlert } = useAlertsStore();
  const unread = alerts.filter((a) => !a.read);

  if (unread.length === 0) return null;

  return (
    <div className="space-y-2">
      {unread.slice(0, 3).map((alert) => {
        const Icon = alertIcons[alert.type];
        return (
          <GlassCard
            key={alert.id}
            className={cn("relative", severityStyles[alert.severity])}
            onClick={() => markRead(alert.id)}
          >
            <button
              onClick={(e) => { e.stopPropagation(); dismissAlert(alert.id); }}
              className="absolute top-2 right-2 w-5 h-5 rounded-full bg-secondary/60 flex items-center justify-center"
            >
              <X className="w-3 h-3 text-muted-foreground" />
            </button>
            <div className="flex items-start gap-3 pr-6">
              <Icon className={cn("w-4 h-4 mt-0.5 shrink-0", severityColors[alert.severity])} />
              <div>
                <p className="text-xs font-semibold text-foreground">{alert.title}</p>
                <p className="text-[10px] text-muted-foreground mt-0.5 leading-relaxed">{alert.description}</p>
                <p className="text-[9px] text-muted-foreground/60 mt-1">{alert.timestamp}</p>
              </div>
            </div>
          </GlassCard>
        );
      })}
    </div>
  );
};

export default TravelAlerts;
