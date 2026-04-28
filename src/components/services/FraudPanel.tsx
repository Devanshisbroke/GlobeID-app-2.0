import React, { useEffect, useState, useCallback } from "react";
import { AlertTriangle, Loader2, ShieldCheck } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/button";
import { useFraudStore } from "@/store/fraudStore";
import { cn } from "@/lib/utils";

const SEVERITY_COLOR = {
  high: "text-rose-500",
  medium: "text-amber-500",
  low: "text-sky-500",
} as const;

const FraudPanel: React.FC = () => {
  const findings = useFraudStore((s) => s.findings);
  const scanned = useFraudStore((s) => s.scanned);
  const lastScan = useFraudStore((s) => s.lastScan);
  const refresh = useFraudStore((s) => s.refresh);
  const runScan = useFraudStore((s) => s.runScan);
  const lastError = useFraudStore((s) => s.lastError);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const onScan = useCallback(async () => {
    setBusy(true);
    try {
      await runScan();
    } finally {
      setBusy(false);
    }
  }, [runScan]);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-5 h-5 text-primary" />
          <p className="text-sm font-bold text-foreground">Wallet fraud scan</p>
        </div>
        <p className="text-xs text-muted-foreground">
          Scanned {scanned} debits. Rules: velocity, duplicate, amount-z, geo-jump, off-hours.
        </p>
        {lastScan && (
          <p className="text-[11px] text-muted-foreground">
            Last scan: {lastScan.alertsCreated} new alerts, {lastScan.alertsDuplicate} dedup'd.
          </p>
        )}
        <Button size="sm" disabled={busy} onClick={onScan} className="w-full">
          {busy ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null}
          Run scan
        </Button>
        {lastError && <p className="text-[11px] text-destructive">{lastError}</p>}
      </GlassCard>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">Findings</p>
        {findings.length === 0 ? (
          <p className="text-xs text-muted-foreground">No suspicious patterns detected.</p>
        ) : (
          <div className="space-y-2">
            {findings.map((f) => (
              <div key={f.signature} className="flex items-start gap-2">
                <AlertTriangle className={cn("w-4 h-4 mt-0.5 shrink-0", SEVERITY_COLOR[f.severity])} />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-semibold text-foreground capitalize">{f.rule.replace("_", " ")}</p>
                  <p className="text-[11px] text-muted-foreground">{f.message}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </GlassCard>
    </div>
  );
};

export default React.memo(FraudPanel);
