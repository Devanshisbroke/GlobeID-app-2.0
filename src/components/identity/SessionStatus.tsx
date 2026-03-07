import React from "react";
import { cn } from "@/lib/utils";
import { ShieldCheck, Loader2, AlertTriangle, Clock } from "lucide-react";

interface SessionStatusProps {
  status: "idle" | "waiting" | "processing" | "verified" | "expired" | "failed";
  sessionId?: string;
  className?: string;
}

const statusMap = {
  idle: { icon: Clock, label: "Ready to link", color: "text-muted-foreground" },
  waiting: { icon: Clock, label: "Waiting for kiosk scan…", color: "text-accent" },
  processing: { icon: Loader2, label: "Verifying…", color: "text-accent" },
  verified: { icon: ShieldCheck, label: "Identity verified", color: "text-accent" },
  expired: { icon: AlertTriangle, label: "Session expired", color: "text-destructive" },
  failed: { icon: AlertTriangle, label: "Verification failed", color: "text-destructive" },
};

const SessionStatus: React.FC<SessionStatusProps> = ({ status, sessionId, className }) => {
  const config = statusMap[status];
  const Icon = config.icon;

  return (
    <div className={cn("flex items-center gap-2 rounded-xl px-3 py-2 glass", className)}>
      <Icon
        className={cn(
          "w-4 h-4",
          config.color,
          status === "processing" && "animate-spin",
          status === "waiting" && "animate-pulse"
        )}
      />
      <span className={cn("text-xs font-medium", config.color)}>
        {config.label}
      </span>
      {sessionId && status !== "idle" && (
        <span className="text-[10px] text-muted-foreground ml-auto font-mono">
          {sessionId.slice(0, 8)}
        </span>
      )}
    </div>
  );
};

export default SessionStatus;
