import React from "react";
import { ShieldCheck, Plane, AlertTriangle, Bell, X } from "lucide-react";
import { Surface, Text } from "@/components/ui/v2";
import { useAlertsStore } from "@/store/alertsStore";
import { cn } from "@/lib/utils";

const ALERT_ICON = {
  visa_change: ShieldCheck,
  flight_disruption: Plane,
  advisory: AlertTriangle,
  info: Bell,
} as const;

const SEVERITY_RING = {
  high: "border-critical/40",
  medium: "border-[hsl(var(--p7-warning))]/40",
  low: "border-surface-hairline",
} as const;

const SEVERITY_TONE = {
  high: "text-critical",
  medium: "text-[hsl(var(--p7-warning))]",
  low: "text-ink-tertiary",
} as const;

const TravelAlerts: React.FC = () => {
  const { alerts, markRead, dismissAlert } = useAlertsStore();
  const unread = alerts.filter((a) => !a.read);

  if (unread.length === 0) return null;

  return (
    <div className="space-y-2">
      {unread.slice(0, 3).map((alert) => {
        const Icon = ALERT_ICON[alert.type];
        return (
          <Surface
            key={alert.id}
            variant="elevated"
            radius="surface"
            className={cn("relative p-3.5 cursor-pointer", SEVERITY_RING[alert.severity])}
            onClick={() => markRead(alert.id)}
          >
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                dismissAlert(alert.id);
              }}
              aria-label="Dismiss alert"
              className="absolute top-2 right-2 w-6 h-6 rounded-full bg-surface-overlay flex items-center justify-center"
            >
              <X className="w-3 h-3 text-ink-tertiary" />
            </button>
            <div className="flex items-start gap-3 pr-6">
              <Icon
                className={cn("w-4 h-4 mt-0.5 shrink-0", SEVERITY_TONE[alert.severity])}
              />
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <Text variant="caption-1" tone="primary" className="font-semibold">
                    {alert.title}
                  </Text>
                  {alert.source === "system" && (
                    <span
                      className="w-1.5 h-1.5 rounded-full bg-state-accent shadow-[0_0_6px_currentColor]"
                      title="System-derived from your travel + wallet state"
                    />
                  )}
                </div>
                <Text variant="caption-2" tone="secondary" className="mt-0.5 leading-relaxed">
                  {alert.description}
                </Text>
                <Text variant="caption-2" tone="tertiary" className="mt-1">
                  {alert.timestamp}
                </Text>
              </div>
            </div>
          </Surface>
        );
      })}
    </div>
  );
};

export default TravelAlerts;
