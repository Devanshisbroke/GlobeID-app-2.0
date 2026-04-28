import React, { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Wifi } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";
import type { ESimPlan } from "@shared/data/esimCatalog";

const EsimPanel: React.FC = () => {
  const [country, setCountry] = useState("");
  const [plans, setPlans] = useState<ESimPlan[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.esim.plans(country || undefined);
      setPlans(r.plans);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Failed");
      setPlans(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">eSIM data plans</p>
        <div className="flex gap-2">
          <Input
            value={country}
            onChange={(e) => setCountry(e.target.value.toUpperCase().slice(0, 2))}
            placeholder="ISO-2 (e.g. JP) or empty for all"
            className="text-xs font-mono uppercase"
          />
          <Button size="sm" onClick={load} disabled={loading}>
            {loading ? <Loader2 className="w-3 h-3 animate-spin" /> : "Search"}
          </Button>
        </div>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {plans && (
        <div className="grid grid-cols-2 gap-2">
          {plans.map((p) => (
            <GlassCard key={p.id} className="p-3">
              <div className="flex items-center gap-2">
                <Wifi className="w-4 h-4 text-primary" />
                <p className="text-xs font-bold text-foreground">{p.carrier}</p>
                <span className="ml-auto text-[10px] text-muted-foreground font-mono">{p.countryIso2}</span>
              </div>
              <p className="text-[11px] text-muted-foreground mt-1">{p.countryName}</p>
              <div className="mt-2 grid grid-cols-2 gap-1 text-[10px]">
                <div>
                  <span className="uppercase text-muted-foreground">Data</span>
                  <p className="font-bold text-foreground">{p.dataGB} GB</p>
                </div>
                <div>
                  <span className="uppercase text-muted-foreground">Validity</span>
                  <p className="font-bold text-foreground">{p.validityDays}d</p>
                </div>
                <div>
                  <span className="uppercase text-muted-foreground">Net</span>
                  <p className="font-bold text-foreground">{p.network}</p>
                </div>
                <div>
                  <span className="uppercase text-muted-foreground">Price</span>
                  <p className="font-bold text-foreground">${p.priceUsd}</p>
                </div>
              </div>
            </GlassCard>
          ))}
        </div>
      )}
    </div>
  );
};

export default React.memo(EsimPanel);
