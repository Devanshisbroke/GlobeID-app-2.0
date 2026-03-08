import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { useWalletStore } from "@/store/walletStore";
import { processPayment, decodeQRPayload } from "@/services/paymentGateway";
import { ScanLine, Check, AlertTriangle, Camera } from "lucide-react";
import { cn } from "@/lib/utils";

const demoPayloads = [
  { amount: 12, currency: "SGD", merchant: "Marina Bay Cafe" },
  { amount: 8.5, currency: "SGD", merchant: "SMRT Metro" },
  { amount: 25, currency: "USD", merchant: "Airport Duty Free" },
  { amount: 1500, currency: "JPY", merchant: "Tokyo Ramen Shop" },
];

const QRScanner: React.FC<{ onClose?: () => void }> = ({ onClose }) => {
  const { deductBalance, addTransaction } = useWalletStore();
  const [scanning, setScanning] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const simulateScan = async () => {
    setScanning(true);
    setResult(null);

    await new Promise((r) => setTimeout(r, 1200));

    const payload = demoPayloads[Math.floor(Math.random() * demoPayloads.length)];
    const response = await processPayment({ amount: payload.amount, currency: payload.currency, merchant: payload.merchant });

    if (response.success) {
      deductBalance(payload.currency, payload.amount);
      addTransaction({
        id: response.transactionId,
        type: "payment",
        description: payload.merchant,
        merchant: payload.merchant,
        amount: -payload.amount,
        currency: payload.currency,
        date: new Date().toISOString().split("T")[0],
        category: "shopping",
        icon: "QrCode",
      });
      setResult({ success: true, message: `Paid ${payload.currency} ${payload.amount} to ${payload.merchant}` });
    } else {
      setResult({ success: false, message: "Payment failed. Try again." });
    }
    setScanning(false);
  };

  return (
    <GlassCard variant="premium" depth="lg" className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold text-foreground flex items-center gap-2">
          <ScanLine className="w-4 h-4 text-primary" /> Scan & Pay
        </h3>
        {onClose && <button onClick={onClose} className="text-xs text-muted-foreground">✕</button>}
      </div>

      {/* Simulated scanner viewport */}
      <div className="relative aspect-square max-w-[240px] mx-auto rounded-2xl overflow-hidden border-2 border-dashed border-border/50 bg-secondary/20 flex items-center justify-center">
        {scanning ? (
          <div className="text-center space-y-2 animate-pulse">
            <ScanLine className="w-10 h-10 text-primary mx-auto" />
            <p className="text-xs text-muted-foreground">Scanning...</p>
          </div>
        ) : result ? (
          <div className={cn("text-center space-y-2 animate-fade-in p-4", result.success ? "text-accent" : "text-destructive")}>
            {result.success ? <Check className="w-10 h-10 mx-auto" /> : <AlertTriangle className="w-10 h-10 mx-auto" />}
            <p className="text-xs font-medium">{result.message}</p>
          </div>
        ) : (
          <div className="text-center space-y-2">
            <Camera className="w-10 h-10 text-muted-foreground mx-auto" />
            <p className="text-xs text-muted-foreground">Point at QR code</p>
          </div>
        )}

        {/* Scanner frame corners */}
        <div className="absolute top-2 left-2 w-6 h-6 border-t-2 border-l-2 border-primary rounded-tl-lg" />
        <div className="absolute top-2 right-2 w-6 h-6 border-t-2 border-r-2 border-primary rounded-tr-lg" />
        <div className="absolute bottom-2 left-2 w-6 h-6 border-b-2 border-l-2 border-primary rounded-bl-lg" />
        <div className="absolute bottom-2 right-2 w-6 h-6 border-b-2 border-r-2 border-primary rounded-br-lg" />
      </div>

      <button
        onClick={result ? () => setResult(null) : simulateScan}
        disabled={scanning}
        className={cn(
          "w-full py-3 rounded-xl text-sm font-semibold min-h-[48px] flex items-center justify-center gap-2 transition-all",
          "bg-gradient-cosmic text-primary-foreground shadow-glow-md disabled:opacity-40"
        )}
      >
        <ScanLine className="w-4 h-4" />
        {scanning ? "Processing..." : result ? "Scan Another" : "Simulate Scan"}
      </button>
    </GlassCard>
  );
};

export default QRScanner;
