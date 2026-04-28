import React, { useState, useMemo } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { useWalletStore } from "@/store/walletStore";
import { RefreshCw, ArrowRightLeft } from "lucide-react";
import { cn } from "@/lib/utils";

const CurrencyConverter: React.FC<{ onClose?: () => void }> = ({ onClose }) => {
  const balances = useWalletStore((s) => s.balances);
  const convert = useWalletStore((s) => s.convert);
  const [from, setFrom] = useState(balances[0]?.currency ?? "USD");
  const [to, setTo] = useState(balances[1]?.currency ?? "EUR");
  const [amount, setAmount] = useState("");
  const [converting, setConverting] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fromBal = balances.find((b) => b.currency === from);
  const toBal = balances.find((b) => b.currency === to);

  const converted = useMemo(() => {
    const val = parseFloat(amount);
    if (!val || !fromBal || !toBal) return null;
    return (val * fromBal.rate) / toBal.rate;
  }, [amount, fromBal, toBal]);

  const handleSwap = () => { setFrom(to); setTo(from); };

  const handleConvert = async () => {
    const val = parseFloat(amount);
    if (!val || !fromBal || val > fromBal.amount || from === to) return;
    setConverting(true);
    setError(null);
    try {
      await convert({ fromCurrency: from, toCurrency: to, amount: val });
      setResult(`Converted ${fromBal.symbol}${val.toLocaleString()} to ${toBal?.symbol}${converted?.toLocaleString(undefined, { maximumFractionDigits: 2 })}`);
      setAmount("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Conversion failed");
    } finally {
      setConverting(false);
    }
  };

  return (
    <GlassCard variant="premium" depth="lg" className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold text-foreground">Convert Currency</h3>
        {onClose && <button onClick={onClose} className="text-xs text-muted-foreground">✕</button>}
      </div>

      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <div className="flex-1">
            <label className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 block">From</label>
            <select
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-sm text-foreground bg-transparent outline-none min-h-[44px]"
            >
              {balances.map((b) => (
                <option key={b.currency} value={b.currency}>{b.flag} {b.currency}</option>
              ))}
            </select>
          </div>
          <button onClick={handleSwap} className="mt-5 w-10 h-10 rounded-xl glass border border-border/40 flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors">
            <ArrowRightLeft className="w-4 h-4" />
          </button>
          <div className="flex-1">
            <label className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 block">To</label>
            <select
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-sm text-foreground bg-transparent outline-none min-h-[44px]"
            >
              {balances.map((b) => (
                <option key={b.currency} value={b.currency}>{b.flag} {b.currency}</option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <label className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 block">Amount</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => { setAmount(e.target.value); setResult(null); }}
            placeholder={`Max ${fromBal?.symbol}${fromBal?.amount.toLocaleString() ?? "0"}`}
            className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-sm text-foreground bg-transparent outline-none min-h-[44px] tabular-nums"
          />
        </div>

        {converted !== null && (
          <div className="text-center py-2">
            <p className="text-xs text-muted-foreground">You'll receive</p>
            <p className="text-2xl font-bold text-foreground tabular-nums">
              {toBal?.symbol}{converted.toLocaleString(undefined, { maximumFractionDigits: 2 })}
            </p>
            <p className="text-[10px] text-muted-foreground">
              1 {from} = {((fromBal?.rate ?? 1) / (toBal?.rate ?? 1)).toFixed(4)} {to}
            </p>
          </div>
        )}

        {result && !error && (
          <div className="text-center py-2 text-xs text-accent font-medium animate-fade-in">{result}</div>
        )}
        {error && (
          <div className="text-center py-2 text-xs text-destructive font-medium animate-fade-in">{error}</div>
        )}

        <button
          onClick={handleConvert}
          disabled={!converted || converting || parseFloat(amount) > (fromBal?.amount ?? 0)}
          className={cn(
            "w-full py-3 rounded-xl text-sm font-semibold transition-all min-h-[48px] flex items-center justify-center gap-2",
            "bg-gradient-brand text-primary-foreground shadow-glow-md disabled:opacity-40 disabled:shadow-none"
          )}
        >
          <RefreshCw className={cn("w-4 h-4", converting && "animate-spin")} />
          {converting ? "Converting..." : "Convert"}
        </button>
      </div>
    </GlassCard>
  );
};

export default CurrencyConverter;
