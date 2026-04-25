import React from "react";
import { CloudOff, AlertCircle } from "lucide-react";
import { useUserStore } from "@/store/userStore";

/**
 * Tiny offline / error indicator. Renders nothing in the steady-state
 * `synced` / `idle` / `loading` cases so the UI is unchanged in the
 * happy path; only surfaces when the user has queued offline work or
 * when a hard error needs flagging.
 */
const SyncBadge: React.FC = () => {
  const syncStatus = useUserStore((s) => s.syncStatus);
  const pending = useUserStore((s) => s.pendingMutations.length);

  if (syncStatus !== "offline-pending" && syncStatus !== "error") return null;

  const isOffline = syncStatus === "offline-pending";
  const Icon = isOffline ? CloudOff : AlertCircle;
  const label = isOffline
    ? pending > 0
      ? `Offline · ${pending} queued`
      : "Offline"
    : "Sync error";

  return (
    <div
      role="status"
      className="fixed top-4 left-1/2 -translate-x-1/2 z-40 flex items-center gap-1.5 px-2.5 py-1 rounded-full glass border border-border/40 text-[10px] font-medium text-foreground/80"
    >
      <Icon className="w-3 h-3" />
      <span>{label}</span>
    </div>
  );
};

export default SyncBadge;
