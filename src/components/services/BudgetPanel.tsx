import React, { useEffect, useState, useCallback } from "react";
import { Loader2, PiggyBank, Plus, Trash2 } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useBudgetStore } from "@/store/budgetStore";
import { cn } from "@/lib/utils";

const PERIODS = ["trip", "monthly", "yearly", "global"] as const;
type Period = (typeof PERIODS)[number];

const STATUS_COLOR = {
  under: "text-emerald-500",
  near: "text-amber-500",
  over: "text-rose-500",
} as const;

const BudgetPanel: React.FC = () => {
  const snapshot = useBudgetStore((s) => s.snapshot);
  const hydrated = useBudgetStore((s) => s.hydrated);
  const hydrate = useBudgetStore((s) => s.hydrate);
  const upsert = useBudgetStore((s) => s.upsert);
  const remove = useBudgetStore((s) => s.remove);
  const lastError = useBudgetStore((s) => s.lastError);

  const [scope, setScope] = useState("category:food");
  const [cap, setCap] = useState(200);
  const [period, setPeriod] = useState<Period>("trip");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  const onAdd = useCallback(async () => {
    if (!scope.trim() || !(cap > 0)) return;
    setBusy(true);
    try {
      await upsert({
        scope: scope.trim(),
        capAmount: cap,
        currency: snapshot?.defaultCurrency ?? "USD",
        period,
        alertThreshold: 0.8,
      });
    } finally {
      setBusy(false);
    }
  }, [scope, cap, period, snapshot, upsert]);

  if (!hydrated) {
    return (
      <GlassCard className="p-4 flex items-center gap-2 text-sm text-muted-foreground">
        <Loader2 className="w-4 h-4 animate-spin" /> Loading budget…
      </GlassCard>
    );
  }
  if (!snapshot) {
    return <GlassCard className="p-4 text-sm text-destructive">{lastError ?? "Budget unavailable."}</GlassCard>;
  }

  return (
    <div className="space-y-3">
      <GlassCard className="p-4">
        <div className="flex items-center gap-2 mb-3">
          <PiggyBank className="w-5 h-5 text-primary" />
          <p className="text-sm font-bold text-foreground">Active caps</p>
        </div>
        {snapshot.usage.length === 0 ? (
          <p className="text-xs text-muted-foreground">No caps yet — add one below.</p>
        ) : (
          <div className="space-y-3">
            {snapshot.usage.map((u) => (
              <div key={u.scope} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-mono text-foreground truncate">{u.scope}</span>
                  <span className={cn("font-semibold", STATUS_COLOR[u.status])}>
                    {u.spent.toFixed(2)} / {u.cap.capAmount.toFixed(2)} {u.cap.currency}
                  </span>
                </div>
                <div className="h-1.5 rounded-full bg-secondary overflow-hidden">
                  <div
                    className={cn(
                      "h-full",
                      u.status === "over"
                        ? "bg-rose-500"
                        : u.status === "near"
                          ? "bg-amber-400"
                          : "bg-emerald-500",
                    )}
                    style={{ width: `${Math.min(100, Math.max(0, u.fractionUsed * 100))}%` }}
                  />
                </div>
                <div className="flex items-center justify-between text-[10px] text-muted-foreground">
                  <span>
                    {u.cap.period} · alert at {(u.cap.alertThreshold * 100).toFixed(0)}%
                  </span>
                  <button
                    onClick={() => void remove(u.scope)}
                    className="flex items-center gap-1 hover:text-destructive"
                  >
                    <Trash2 className="w-3 h-3" /> remove
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </GlassCard>

      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Add or update cap</p>
        <Input
          value={scope}
          onChange={(e) => setScope(e.target.value)}
          placeholder="scope: category:food, trip:trip-id, global"
          className="text-xs"
        />
        <div className="grid grid-cols-2 gap-2">
          <Input
            type="number"
            min={1}
            value={cap}
            onChange={(e) => setCap(Number(e.target.value))}
            placeholder="cap amount"
            className="text-xs"
          />
          <select
            value={period}
            onChange={(e) => setPeriod(e.target.value as Period)}
            className="rounded-md border border-input bg-background text-xs px-2"
          >
            {PERIODS.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
        <Button size="sm" onClick={onAdd} disabled={busy} className="w-full">
          <Plus className="w-3 h-3 mr-1" /> Save cap
        </Button>
        {lastError && <p className="text-[11px] text-destructive">{lastError}</p>}
      </GlassCard>
    </div>
  );
};

export default React.memo(BudgetPanel);
