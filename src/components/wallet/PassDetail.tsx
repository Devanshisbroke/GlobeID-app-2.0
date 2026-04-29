/**
 * Slice-G – full-screen pass view.
 *
 * Mounted from `PassStack` when a pass is tapped. Uses framer-motion's
 * `layoutId` so the pass card morphs from the stack into this sheet
 * instead of a hard cross-fade. Contains a QR code generated from the
 * doc's number (deterministic — same doc always produces the same QR)
 * and structured key/value rows.
 */
import React, { useEffect, useRef } from "react";
import { motion } from "framer-motion";
import { X, Calendar, Hash, Flag } from "lucide-react";
import QRCode from "qrcode";
import { PassCard } from "./PassStack";
import type { TravelDocument } from "@/store/userStore";

export interface PassDetailProps {
  doc: TravelDocument;
  onClose: () => void;
}

const PassDetail: React.FC<PassDetailProps> = ({ doc, onClose }) => {
  const qrRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    if (!qrRef.current) return;
    const payload = JSON.stringify({
      t: "globeid-doc",
      id: doc.id,
      type: doc.type,
      n: doc.number,
      c: doc.country,
      exp: doc.expiryDate,
    });
    void QRCode.toCanvas(qrRef.current, payload, {
      width: 220,
      margin: 1,
      color: { dark: "#0f172a", light: "#ffffff" },
      errorCorrectionLevel: "M",
    });
  }, [doc]);

  return (
    <motion.div
      className="fixed inset-0 z-50 flex flex-col bg-background/95 backdrop-blur-xl"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.24 }}
      role="dialog"
      aria-modal="true"
      aria-label={`${doc.label} pass`}
    >
      {/* Header — close button */}
      <div className="flex items-center justify-between px-5 pt-[env(safe-area-inset-top)] pb-3 pt-3">
        <button
          type="button"
          onClick={onClose}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-muted text-muted-foreground active:scale-95"
          aria-label="Close pass"
        >
          <X className="h-4 w-4" />
        </button>
        <p className="text-xs uppercase tracking-[0.22em] text-muted-foreground">
          {doc.label}
        </p>
        <span className="h-9 w-9" />
      </div>

      <div className="flex-1 overflow-y-auto px-5 pb-8">
        {/* Hero pass, morphed from the stack via layoutId. */}
        <motion.div
          layoutId={`pass-${doc.id}`}
          className="mx-auto max-w-md"
          transition={{ type: "spring", stiffness: 300, damping: 30 }}
        >
          <PassCard doc={doc} active />
        </motion.div>

        {/* QR */}
        <div className="mx-auto mt-6 flex max-w-md flex-col items-center rounded-[22px] bg-white p-5 shadow-[0_14px_32px_-16px_rgba(0,0,0,0.3)]">
          <canvas ref={qrRef} className="rounded-md" />
          <p className="mt-2 text-[11px] uppercase tracking-widest text-slate-500">
            Scan to verify
          </p>
        </div>

        {/* Details */}
        <div className="mx-auto mt-6 max-w-md space-y-2">
          <DetailRow icon={<Hash className="h-4 w-4" />} label="Number" value={doc.number} />
          <DetailRow
            icon={<Flag className="h-4 w-4" />}
            label="Country"
            value={`${doc.countryFlag} ${doc.country}`}
          />
          <DetailRow
            icon={<Calendar className="h-4 w-4" />}
            label="Issued"
            value={doc.issueDate}
          />
          <DetailRow
            icon={<Calendar className="h-4 w-4" />}
            label="Expires"
            value={doc.expiryDate}
          />
          <DetailRow
            icon={<StatusDot status={doc.status} />}
            label="Status"
            value={doc.status}
          />
        </div>
      </div>
    </motion.div>
  );
};

interface RowProps {
  icon: React.ReactNode;
  label: string;
  value: string;
}

const DetailRow: React.FC<RowProps> = ({ icon, label, value }) => (
  <div className="flex items-center justify-between rounded-2xl bg-muted/60 px-4 py-3">
    <div className="flex items-center gap-2 text-xs uppercase tracking-widest text-muted-foreground">
      {icon}
      {label}
    </div>
    <div className="text-sm font-medium text-foreground">{value}</div>
  </div>
);

const StatusDot: React.FC<{ status: TravelDocument["status"] }> = ({ status }) => {
  const color =
    status === "active"
      ? "bg-emerald-500"
      : status === "expired"
        ? "bg-rose-500"
        : "bg-amber-500";
  return <span className={`inline-block h-2.5 w-2.5 rounded-full ${color}`} />;
};

export default PassDetail;
