/**
 * EntryReceipt screen — displays verified entry receipt with DID, country, and JWS details.
 * Backend replacement: fetch receipt from GET /api/receipts/:id instead of location state.
 */
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { getCountryTheme } from "@/lib/countryThemes";
import { ShieldCheck, Download, ArrowLeft, Clock, MapPin, Fingerprint } from "lucide-react";
import type { EntryReceipt as ReceiptType } from "@/lib/verificationSession";

const EntryReceipt: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const receipt = location.state?.receipt as ReceiptType | undefined;

  if (!receipt) {
    return (
      <div className="px-4 py-6 flex flex-col items-center justify-center min-h-[60dvh] gap-4">
        <p className="text-sm text-muted-foreground">No receipt found</p>
        <button
          onClick={() => navigate("/identity")}
          className="text-xs text-accent underline"
        >
          Back to Identity
        </button>
      </div>
    );
  }

  const theme = getCountryTheme(receipt.countryCode);

  const handleDownload = () => {
    const blob = new Blob([JSON.stringify(receipt, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `entry-receipt-${receipt.id.slice(0, 8)}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="px-4 py-6 space-y-6">
      <AnimatedPage>
        <button
          onClick={() => navigate("/identity")}
          className="flex items-center gap-1.5 text-xs text-muted-foreground mb-4 min-h-[44px]"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Identity
        </button>

        <GlassCard neonBorder className="text-center py-6">
          <div className="flex flex-col items-center gap-3">
            <div className="w-14 h-14 rounded-full bg-accent/20 flex items-center justify-center">
              <ShieldCheck className="w-7 h-7 text-accent" />
            </div>
            <h2 className="text-lg font-bold text-foreground">Entry Verified</h2>
            <p className="text-sm text-muted-foreground">
              {theme.flag} {theme.name}
            </p>
          </div>
        </GlassCard>
      </AnimatedPage>

      <AnimatedPage staggerIndex={1}>
        <GlassCard>
          <h3 className="text-sm font-semibold text-foreground mb-4">Receipt Details</h3>
          <div className="space-y-3">
            <DetailRow icon={<Fingerprint className="w-4 h-4" />} label="Receipt ID" value={receipt.id.slice(0, 12) + "…"} mono />
            <DetailRow icon={<Fingerprint className="w-4 h-4" />} label="DID" value={receipt.did} mono />
            <DetailRow icon={<MapPin className="w-4 h-4" />} label="Country" value={`${theme.flag} ${theme.name}`} />
            <DetailRow icon={<Clock className="w-4 h-4" />} label="Verified At" value={new Date(receipt.createdAt).toLocaleString()} />
            <DetailRow icon={<ShieldCheck className="w-4 h-4" />} label="Kiosk" value={receipt.kioskId} mono />
            <DetailRow icon={<ShieldCheck className="w-4 h-4" />} label="Session" value={receipt.sessionId.slice(0, 12) + "…"} mono />
          </div>
        </GlassCard>
      </AnimatedPage>

      <AnimatedPage staggerIndex={2}>
        <GlassCard>
          <h3 className="text-sm font-semibold text-foreground mb-3">Receipt JWS</h3>
          <div className="bg-secondary/50 rounded-lg p-3 overflow-x-auto">
            <code className="text-[10px] text-muted-foreground font-mono break-all leading-relaxed">
              {receipt.receiptJws}
            </code>
          </div>
        </GlassCard>
      </AnimatedPage>

      <AnimatedPage staggerIndex={3}>
        <button
          onClick={handleDownload}
          className="w-full py-3 rounded-xl bg-gradient-to-r from-neon-indigo to-neon-cyan text-primary-foreground text-sm font-medium active:scale-95 transition-transform flex items-center justify-center gap-2 min-h-[44px]"
        >
          <Download className="w-4 h-4" />
          Download Receipt
        </button>
      </AnimatedPage>
    </div>
  );
};

const DetailRow: React.FC<{ icon: React.ReactNode; label: string; value: string; mono?: boolean }> = ({ icon, label, value, mono }) => (
  <div className="flex items-start gap-3">
    <span className="text-muted-foreground mt-0.5">{icon}</span>
    <div className="flex-1 min-w-0">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className={`text-sm text-foreground ${mono ? "font-mono" : ""} break-all`}>{value}</p>
    </div>
  </div>
);

export default EntryReceipt;
