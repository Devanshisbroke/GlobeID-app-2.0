import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowDownUp } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";

interface QuoteState {
  from: string;
  to: string;
  amount: number;
  rate: number;
  converted: number;
  asOf: string;
}

const ExchangePanel: React.FC = () => {
  const [from, setFrom] = useState("USD");
  const [to, setTo] = useState("EUR");
  const [amount, setAmount] = useState(100);
  const [quote, setQuote] = useState<QuoteState | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const convert = async () => {
    if (!(amount > 0)) return;
    setLoading(true);
    setError(null);
    try {
      const r = await api.exchange.quote(from, to, amount);
      setQuote(r);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "FX failed");
      setQuote(null);
    } finally {
      setLoading(false);
    }
  };

  const swap = () => {
    setFrom(to);
    setTo(from);
    if (quote) setQuote({ ...quote, from: to, to: from });
  };

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Currency converter (live)</p>
        <div className="grid grid-cols-3 gap-2">
          <Input
            value={from}
            onChange={(e) => setFrom(e.target.value.toUpperCase().slice(0, 3))}
            placeholder="from"
            className="text-xs font-mono uppercase"
          />
          <Input
            value={to}
            onChange={(e) => setTo(e.target.value.toUpperCase().slice(0, 3))}
            placeholder="to"
            className="text-xs font-mono uppercase"
          />
          <Input
            type="number"
            min={0.01}
            step={0.01}
            value={amount}
            onChange={(e) => setAmount(Number(e.target.value))}
            placeholder="amount"
            className="text-xs"
          />
        </div>
        <div className="flex gap-2">
          <Button size="sm" onClick={convert} disabled={loading} className="flex-1">
            {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null}
            Convert
          </Button>
          <Button size="sm" variant="outline" onClick={swap} aria-label="Swap currencies">
            <ArrowDownUp className="w-3 h-3" />
          </Button>
        </div>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {quote && (
        <GlassCard className="p-4">
          <p className="text-xs text-muted-foreground">
            {quote.amount} {quote.from} =
          </p>
          <p className="text-2xl font-bold text-foreground">
            {quote.converted.toLocaleString()} {quote.to}
          </p>
          <p className="text-[10px] text-muted-foreground mt-1">
            Rate {quote.rate.toFixed(6)} · as of {quote.asOf} · source exchangerate.host
          </p>
        </GlassCard>
      )}
    </div>
  );
};

export default React.memo(ExchangePanel);
