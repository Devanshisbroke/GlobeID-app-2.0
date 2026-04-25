import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { generateQRSvg } from "@/lib/qrEncoder";
import { encodeQRPayload } from "@/services/paymentGateway";
import { useWalletStore } from "@/store/walletStore";
import { QrCode, Check } from "lucide-react";
import { cn } from "@/lib/utils";

const QRPayment: React.FC<{ onClose?: () => void }> = ({ onClose }) => {
  const { balances, defaultCurrency } = useWalletStore();
  const [amount, setAmount] = useState("");
  const [currency, setCurrency] = useState(defaultCurrency);
  const [merchant, setMerchant] = useState("");
  const [generated, setGenerated] = useState(false);

  const qrData = encodeQRPayload({ amount: parseFloat(amount) || 0, currency, merchant: merchant || "GlobeID User" });
  const qrSvg = generateQRSvg(qrData, 200, 25);

  const handleGenerate = () => {
    if (!amount || parseFloat(amount) <= 0) return;
    setGenerated(true);
  };

  return (
    <GlassCard variant="premium" depth="lg" className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold text-foreground flex items-center gap-2">
          <QrCode className="w-4 h-4 text-primary" /> Generate Payment QR
        </h3>
        {onClose && <button onClick={onClose} className="text-xs text-muted-foreground">✕</button>}
      </div>

      {!generated ? (
        <div className="space-y-3">
          <div>
            <label className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 block">Amount</label>
            <input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0.00"
              className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-sm text-foreground bg-transparent outline-none min-h-[44px] tabular-nums" />
          </div>
          <div>
            <label className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 block">Currency</label>
            <select value={currency} onChange={(e) => setCurrency(e.target.value)}
              className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-sm text-foreground bg-transparent outline-none min-h-[44px]">
              {balances.map((b) => <option key={b.currency} value={b.currency}>{b.flag} {b.currency}</option>)}
            </select>
          </div>
          <div>
            <label className="text-[10px] text-muted-foreground uppercase tracking-widest mb-1 block">Merchant (optional)</label>
            <input type="text" value={merchant} onChange={(e) => setMerchant(e.target.value)} placeholder="Cafe, Shop, etc."
              className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-sm text-foreground bg-transparent outline-none min-h-[44px]" />
          </div>
          <button onClick={handleGenerate}
            className="w-full py-3 rounded-xl text-sm font-semibold bg-gradient-brand text-primary-foreground shadow-glow-md min-h-[48px] disabled:opacity-40"
            disabled={!amount || parseFloat(amount) <= 0}>
            Generate QR Code
          </button>
        </div>
      ) : (
        <div className="text-center space-y-4 animate-fade-in">
          <div className="mx-auto w-[200px] h-[200px] rounded-2xl overflow-hidden shadow-depth-md border border-border/20" dangerouslySetInnerHTML={{ __html: qrSvg }} />
          <div>
            <p className="text-xl font-bold text-foreground tabular-nums">
              {balances.find(b => b.currency === currency)?.symbol}{parseFloat(amount).toLocaleString()}
            </p>
            <p className="text-xs text-muted-foreground">{merchant || "GlobeID Payment"}</p>
          </div>
          <button onClick={() => setGenerated(false)} className="text-xs text-primary font-medium">Create New</button>
        </div>
      )}
    </GlassCard>
  );
};

export default QRPayment;
