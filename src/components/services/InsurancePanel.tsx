import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, ShieldCheck, Check } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";
import type { InsurancePlan } from "@shared/data/insuranceCatalog";
import { cn } from "@/lib/utils";

interface QuoteRow {
  plan: InsurancePlan;
  quote: { premiumUsd: number; ageMultiplier: number; regionMultiplier: number };
}

const InsurancePanel: React.FC = () => {
  const [days, setDays] = useState(7);
  const [age, setAge] = useState(30);
  const [destination, setDestination] = useState("FR");
  const [quotes, setQuotes] = useState<QuoteRow[] | null>(null);
  const [region, setRegion] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchQuote = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.insurance.quote(days, age, destination);
      setQuotes(r.quotes);
      setRegion(r.region);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Quote failed");
      setQuotes(null);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Trip insurance quote</p>
        <div className="grid grid-cols-3 gap-2">
          <Input
            type="number"
            min={1}
            max={365}
            value={days}
            onChange={(e) => setDays(Number(e.target.value))}
            placeholder="days"
            className="text-xs"
          />
          <Input
            type="number"
            min={0}
            max={119}
            value={age}
            onChange={(e) => setAge(Number(e.target.value))}
            placeholder="age"
            className="text-xs"
          />
          <Input
            value={destination}
            onChange={(e) => setDestination(e.target.value.toUpperCase().slice(0, 2))}
            placeholder="dest ISO-2"
            className="text-xs font-mono uppercase"
          />
        </div>
        <Button size="sm" onClick={fetchQuote} disabled={loading} className="w-full">
          {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null} Get quotes
        </Button>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
        {region && (
          <p className="text-[10px] text-muted-foreground">
            Region classified as <span className="font-mono">{region}</span>
          </p>
        )}
      </GlassCard>

      {quotes &&
        quotes.map(({ plan, quote }) => (
          <GlassCard key={plan.id} className="p-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                <ShieldCheck className="w-5 h-5 text-primary" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-foreground capitalize">
                  {plan.carrier} {plan.tier.replace("_", " ")}
                </p>
                <p className="text-[11px] text-muted-foreground">
                  Deductible ${plan.deductibleUsd.toLocaleString()} · Medical ${plan.medicalCoverageUsd.toLocaleString()}
                </p>
              </div>
              <div className="text-right">
                <p className="text-lg font-bold text-foreground">${quote.premiumUsd.toFixed(2)}</p>
                <p className="text-[10px] text-muted-foreground">{days}-day premium</p>
              </div>
            </div>
            <div className="mt-3 grid grid-cols-2 gap-1.5 text-[11px]">
              {plan.inclusions.slice(0, 6).map((inc) => (
                <div key={inc} className="flex items-center gap-1.5 text-foreground">
                  <Check className={cn("w-3 h-3 text-emerald-500")} />
                  <span>{inc}</span>
                </div>
              ))}
            </div>
            <p className="text-[10px] text-muted-foreground mt-2">
              age × {quote.ageMultiplier.toFixed(2)} · region × {quote.regionMultiplier.toFixed(2)}
            </p>
          </GlassCard>
        ))}
    </div>
  );
};

export default React.memo(InsurancePanel);
