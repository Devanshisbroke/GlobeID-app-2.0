import React, { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Stamp, FileText } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";
import type { VisaPolicy } from "@shared/data/visaCatalog";

const KIND_LABEL: Record<VisaPolicy["kind"], string> = {
  visa_free: "Visa free",
  visa_on_arrival: "Visa on arrival",
  evisa: "e-Visa",
  consulate: "Consulate visa",
  not_admitted: "Not admitted",
};

const VisaPanel: React.FC = () => {
  const [citizenship, setCitizenship] = useState("IN");
  const [destination, setDestination] = useState("AE");
  const [policy, setPolicy] = useState<VisaPolicy | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const lookup = async () => {
    setLoading(true);
    setError(null);
    try {
      const p = await api.visa.policy(citizenship, destination);
      setPolicy(p);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Lookup failed");
      setPolicy(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void lookup();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Visa policy lookup</p>
        <div className="grid grid-cols-2 gap-2">
          <Input
            value={citizenship}
            onChange={(e) => setCitizenship(e.target.value.toUpperCase().slice(0, 2))}
            placeholder="Citizen ISO-2 (e.g. IN)"
            className="text-xs font-mono uppercase"
          />
          <Input
            value={destination}
            onChange={(e) => setDestination(e.target.value.toUpperCase().slice(0, 2))}
            placeholder="Dest ISO-2 (e.g. AE)"
            className="text-xs font-mono uppercase"
          />
        </div>
        <Button size="sm" onClick={lookup} disabled={loading} className="w-full">
          {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null} Look up
        </Button>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {policy && (
        <GlassCard className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <Stamp className="w-5 h-5 text-primary" />
            <p className="text-sm font-bold text-foreground">{policy.destinationName}</p>
            <span className="ml-auto text-[10px] uppercase tracking-widest text-muted-foreground">{KIND_LABEL[policy.kind]}</span>
          </div>
          <div className="grid grid-cols-3 gap-2 mb-3">
            <Tile label="Stay" value={policy.maxStayDays !== null ? `${policy.maxStayDays}d` : "–"} />
            <Tile label="Process" value={policy.processingDays !== null ? `${policy.processingDays}d` : "—"} />
            <Tile label="Fee" value={policy.feeUsd === 0 ? "Free" : `$${policy.feeUsd}`} />
          </div>
          <p className="text-[10px] uppercase tracking-widest text-muted-foreground mb-1.5">Requirements</p>
          <ul className="space-y-1">
            {policy.requirements.map((r) => (
              <li key={r} className="flex items-start gap-2 text-[11px] text-foreground">
                <FileText className="w-3 h-3 mt-0.5 shrink-0 text-muted-foreground" />
                <span>{r}</span>
              </li>
            ))}
          </ul>
          <p className="text-[10px] text-muted-foreground mt-3">Source: {policy.source}</p>
        </GlassCard>
      )}
    </div>
  );
};

const Tile = React.memo(function Tile({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg bg-secondary/40 p-2 text-center">
      <p className="text-[10px] uppercase text-muted-foreground">{label}</p>
      <p className="text-sm font-bold text-foreground">{value}</p>
    </div>
  );
});

export default React.memo(VisaPanel);
