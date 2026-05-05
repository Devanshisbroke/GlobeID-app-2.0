/**
 * Slice-G – full-screen pass view.
 *
 * Mounted from `PassStack` when a pass is tapped. Uses framer-motion's
 * `layoutId` so the pass card morphs from the stack into this sheet
 * instead of a hard cross-fade. Contains a QR code generated from the
 * doc's number (deterministic — same doc always produces the same QR)
 * and structured key/value rows.
 *
 * On native (Capacitor) the screen brightness is ramped to maximum
 * while the sheet is open so the QR scans cleanly under bright light,
 * and restored on close. The brightness ramp is best-effort: any
 * import/permission failure is swallowed so web/dev still renders.
 */
import React, { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { AnimatePresence, motion } from "framer-motion";
import { useNavigate } from "react-router-dom";
import {
  X,
  Calendar,
  Hash,
  Flag,
  Copy,
  AlertTriangle,
  ExternalLink,
  Info,
  Phone,
  ShieldCheck,
  ArrowLeft,
  RotateCcw,
} from "lucide-react";
import QRCode from "qrcode";
import { Capacitor } from "@capacitor/core";
import { toast } from "sonner";
import { PassCard } from "./PassStack";
import { haptics } from "@/utils/haptics";
import { describeExpiry } from "@/lib/documentExpiry";
import { brandForBoardingPass } from "@/lib/airlineBrand";
import { secureCopy } from "@/lib/secureClipboard";
import type { TravelDocument } from "@/store/userStore";
import { useDeviceTilt } from "@/hooks/useDeviceTilt";

export interface PassDetailProps {
  doc: TravelDocument;
  onClose: () => void;
}

/**
 * Best-effort screen brightness ramp via the optional plugin
 * `@capacitor-community/screen-brightness`. The plugin is dynamically
 * imported and any failure is silently ignored so the build doesn't
 * require the plugin to be installed.
 */
async function setBrightness(value: number | null): Promise<void> {
  if (!Capacitor.isNativePlatform()) return;
  // Resolve via the Capacitor proxy so we don't import the plugin
  // package directly. Apps that ship with the optional
  // `@capacitor-community/screen-brightness` plugin installed get the
  // real native call; everywhere else this is a silent no-op.
  type BrightnessPlugin = {
    setBrightness?: (opts: { brightness: number }) => Promise<unknown>;
  };
  const Plugin = (
    Capacitor as unknown as {
      Plugins?: Record<string, BrightnessPlugin | undefined>;
    }
  ).Plugins?.["ScreenBrightness"];
  if (!Plugin?.setBrightness) return;
  try {
    if (value === null) {
      await Plugin.setBrightness({ brightness: 0.7 });
    } else {
      await Plugin.setBrightness({ brightness: Math.max(0, Math.min(1, value)) });
    }
  } catch {
    /* plugin unavailable or no permission — silent fallback */
  }
}

const PassDetail: React.FC<PassDetailProps> = ({ doc, onClose }) => {
  const qrRef = useRef<HTMLCanvasElement | null>(null);
  const navigate = useNavigate();
  const [flipped, setFlipped] = useState(false);

  const expiryInfo = useMemo(() => describeExpiry(doc.expiryDate), [doc.expiryDate]);
  const brand = useMemo(() => brandForBoardingPass(doc), [doc]);

  // C 25 — parallax tilt driven by deviceorientation. Caps at ±10°
  // visible rotation so the card never inverts. Reduced-motion users
  // and unsupported browsers get a flat card (zero tilt) automatically.
  const { tilt } = useDeviceTilt(true);
  const tiltStyle = useMemo(() => {
    const rotY = tilt.x * 10;
    const rotX = -tilt.y * 8;
    return {
      transform: `perspective(1200px) rotateX(${rotX.toFixed(2)}deg) rotateY(${rotY.toFixed(2)}deg)`,
      transition: "transform 80ms ease-out",
    };
  }, [tilt.x, tilt.y]);

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

  // Brightness ramp lifecycle — fire-and-forget; the helper itself is
  // resilient to missing plugin / permissions.
  useEffect(() => {
    void setBrightness(1);
    return () => {
      void setBrightness(null);
    };
  }, []);

  const handleCopyCode = async () => {
    // Sensitive value (passport / boarding-pass number) — auto-clear
    // the system clipboard 30 s after copy unless the user copied
    // something else in the meantime. Mirrors 1Password / Bitwarden.
    const ok = await secureCopy(doc.number, { key: `pass-${doc.id}` });
    if (ok) {
      haptics.medium();
      toast.success("Code copied — clears in 30 s");
    } else {
      toast.error("Could not copy code");
    }
  };

  const handleViewTrip = () => {
    const target = doc.tripId ?? doc.legId;
    if (!target) return;
    haptics.selection();
    onClose();
    navigate(`/trip/${target}`);
  };

  const handleFlip = () => {
    haptics.selection();
    setFlipped((f) => !f);
  };

  const overlay = (
    <motion.div
      className="fixed inset-0 z-[100] flex min-h-[100dvh] w-screen flex-col bg-background/95 backdrop-blur-xl"
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.98 }}
      transition={{ duration: 0.36, ease: [0.32, 0.72, 0, 1] }}
      role="dialog"
      aria-modal="true"
      aria-label={`${doc.label} pass`}
    >
      {/* Header — close button */}
      <div
        className="flex items-center justify-between px-5 pb-3"
        style={{ paddingTop: "calc(env(safe-area-inset-top, 0px) + 0.75rem)" }}
      >
        <button
          type="button"
          onClick={onClose}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-muted text-muted-foreground active:scale-95 focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
          aria-label="Close pass"
        >
          <X className="h-4 w-4" />
        </button>
        <p className="text-xs uppercase tracking-[0.22em] text-muted-foreground">
          {doc.label}
        </p>
        <span className="h-9 w-9" />
      </div>

      <div
        className="flex-1 overflow-y-auto px-5 pb-8"
        style={{ paddingBottom: "calc(env(safe-area-inset-bottom, 0px) + 2rem)" }}
      >
        {/* Hero pass, morphed from the stack via layoutId. C 25 wraps
            in a tilt-driven transform so the card responds to the
            phone's accelerometer. The wrapping div is kept outside
            the motion.div so the layout animation isn't interfered
            with by the per-frame transform. */}
        <div className="mx-auto max-w-md" style={tiltStyle}>
          <motion.div
            layoutId={`pass-${doc.id}`}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
          >
            <PassCard doc={doc} active />
          </motion.div>
        </div>

        {/* Expiry chip — only when ≤30 days or already expired. */}
        {expiryInfo.severity !== "none" ? (
          <div
            className={`mx-auto mt-4 flex max-w-md items-center gap-2 rounded-xl px-3.5 py-2.5 text-[12px] ${
              expiryInfo.severity === "critical"
                ? "border border-rose-400/40 bg-rose-500/10 text-rose-200"
                : expiryInfo.severity === "warning"
                  ? "border border-amber-400/40 bg-amber-500/10 text-amber-100"
                  : "border border-border bg-card text-muted-foreground"
            }`}
            aria-label={expiryInfo.label}
          >
            <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
            <span className="font-medium">{expiryInfo.label}</span>
          </div>
        ) : null}

        {/* Flip container — front/back swap with rotateY. perspective on
            parent so the rotation reads as 3D rather than 2D scale. */}
        <div
          className="mx-auto mt-6 max-w-md"
          style={{ perspective: 1200 }}
        >
          <AnimatePresence mode="wait" initial={false}>
            {!flipped ? (
              <motion.div
                key="front"
                initial={{ rotateY: -90, opacity: 0 }}
                animate={{ rotateY: 0, opacity: 1 }}
                exit={{ rotateY: 90, opacity: 0 }}
                transition={{ duration: 0.32, ease: [0.32, 0.72, 0, 1] }}
                style={{ transformStyle: "preserve-3d" }}
              >
                {/* QR */}
                <div className="flex flex-col items-center rounded-[22px] bg-white p-5 shadow-[0_14px_32px_-16px_rgba(0,0,0,0.3)]">
                  <canvas ref={qrRef} className="rounded-md" />
                  <p className="mt-2 text-[11px] uppercase tracking-widest text-slate-500">
                    Scan to verify
                  </p>
                </div>

                {/* Action row */}
                <div className="mt-4 flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={handleCopyCode}
                    className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card px-3.5 py-2 text-[12px] font-medium text-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                    aria-label="Copy document code"
                  >
                    <Copy className="w-3.5 h-3.5" />
                    Copy code
                  </button>
                  {doc.type === "boarding_pass" && (doc.tripId || doc.legId) ? (
                    <button
                      type="button"
                      onClick={handleViewTrip}
                      className="inline-flex items-center gap-1.5 rounded-full bg-primary px-3.5 py-2 text-[12px] font-medium text-primary-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                      aria-label="View linked trip"
                    >
                      <ExternalLink className="w-3.5 h-3.5" />
                      View trip
                    </button>
                  ) : null}
                  <button
                    type="button"
                    onClick={handleFlip}
                    className="ml-auto inline-flex items-center gap-1.5 rounded-full border border-border bg-card px-3.5 py-2 text-[12px] font-medium text-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                    aria-label="Show pass details"
                  >
                    <Info className="w-3.5 h-3.5" />
                    Details
                  </button>
                </div>

                {/* Details */}
                <div className="mt-6 space-y-2">
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
              </motion.div>
            ) : (
              <motion.div
                key="back"
                initial={{ rotateY: 90, opacity: 0 }}
                animate={{ rotateY: 0, opacity: 1 }}
                exit={{ rotateY: -90, opacity: 0 }}
                transition={{ duration: 0.32, ease: [0.32, 0.72, 0, 1] }}
                style={{ transformStyle: "preserve-3d" }}
                className="rounded-[22px] border border-border bg-card/80 p-5 backdrop-blur-md"
              >
                <div className="flex items-center justify-between">
                  <p className="text-[11px] uppercase tracking-[0.22em] text-muted-foreground">
                    Pass back
                  </p>
                  <button
                    type="button"
                    onClick={handleFlip}
                    className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card px-3 py-1.5 text-[11px] text-foreground min-h-[36px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                    aria-label="Flip back to QR"
                  >
                    <ArrowLeft className="w-3 h-3" />
                    Back
                  </button>
                </div>

                <div className="mt-4 space-y-3">
                  <DetailRow
                    icon={<Hash className="h-4 w-4" />}
                    label={doc.type === "boarding_pass" ? "Flight" : "Document"}
                    value={doc.number}
                  />
                  <DetailRow
                    icon={<ShieldCheck className="h-4 w-4" />}
                    label="Carrier"
                    value={brand.name}
                  />
                  <DetailRow
                    icon={<Phone className="h-4 w-4" />}
                    label="Carrier support"
                    value="Open the official airline app or website"
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
                </div>

                <p className="mt-5 text-[11px] leading-snug text-muted-foreground">
                  This pass is for personal travel use only. Always carry the
                  original travel document with you. GlobeID does not issue
                  travel documents and is not affiliated with any carrier.
                </p>

                <div className="mt-4 flex justify-end">
                  <button
                    type="button"
                    onClick={handleFlip}
                    className="inline-flex items-center gap-1.5 rounded-full bg-primary px-3.5 py-2 text-[12px] font-medium text-primary-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                    aria-label="Done — flip back"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    Done
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </motion.div>
  );

  return createPortal(overlay, document.body);
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
