import React, { useMemo, useEffect, useRef } from "react";
import { generateQRSvg } from "@/lib/qrEncoder";
import { useVisibleClock } from "@/hooks/useVisibleClock";
import { cn } from "@/lib/utils";
import { haptics } from "@/utils/haptics";

interface QRDisplayProps {
  data: string;
  shortCode: string;
  ttlSeconds: number;
  expiresAt: number;
  status: "idle" | "waiting" | "processing" | "verified" | "expired" | "failed";
  onRefresh?: () => void;
  className?: string;
}

const QRDisplay: React.FC<QRDisplayProps> = ({
  data,
  shortCode,
  ttlSeconds,
  expiresAt,
  status,
  onRefresh,
  className,
}) => {
  // rAF-driven, visibility-aware clock; pauses when the screen is off so
  // we don't waste a 1Hz timer on a backgrounded WebView.
  const now = useVisibleClock(1000);
  const remaining = Math.max(0, Math.ceil((expiresAt - now) / 1000));
  // ttlSeconds is the original budget; not currently surfaced in render
  // but we keep it in the prop signature for callers that may show
  // "x / ttl" progress later. Reference it once to silence noUnusedLocals.
  void ttlSeconds;

  const svgString = useMemo(() => generateQRSvg(data, 200, 25), [data]);

  const isActive = status === "waiting" || status === "idle";
  const isExpired = status === "expired" || remaining <= 0;

  // C 32 — subtle haptic pulse when the QR is being scanned. We treat
  // the transition idle/waiting → processing as "the scanner just
  // grabbed the code"; selection-strength haptic gives the user a
  // tactile confirmation that their card was read.
  const lastStatusRef = useRef(status);
  useEffect(() => {
    const prev = lastStatusRef.current;
    if (prev !== status) {
      if (status === "processing") {
        haptics.selection();
      } else if (status === "verified") {
        haptics.success();
      } else if (status === "failed") {
        haptics.error();
      }
      lastStatusRef.current = status;
    }
  }, [status]);

  return (
    <div className={cn("flex flex-col items-center gap-4", className)}>
      {/* QR Code */}
      <div className="relative">
        <div
          className={cn(
            "rounded-2xl p-3 bg-white transition-all duration-300",
            isActive && "animate-qr-pulse",
            status === "processing" && "scale-95 opacity-70",
            status === "verified" && "scale-90 opacity-0",
            isExpired && "opacity-40 grayscale"
          )}
          dangerouslySetInnerHTML={{ __html: svgString }}
        />

        {/* Status overlay */}
        {status === "processing" && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-8 h-8 rounded-full border-2 border-accent border-t-transparent animate-spin" />
          </div>
        )}

        {status === "verified" && (
          <div className="absolute inset-0 flex items-center justify-center animate-scale-in">
            <div className="w-12 h-12 rounded-full bg-accent/20 flex items-center justify-center">
              <span className="text-2xl">✓</span>
            </div>
          </div>
        )}
      </div>

      {/* Countdown */}
      {isActive && !isExpired && (
        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <div
            className="h-1 rounded-full bg-accent/30 overflow-hidden"
            style={{ width: 80 }}
          >
            <div
              className="h-full bg-accent rounded-full transition-all duration-1000 ease-linear"
              style={{ width: `${(remaining / ttlSeconds) * 100}%` }}
            />
          </div>
          <span className="tabular-nums w-6 text-right">{remaining}s</span>
        </div>
      )}

      {/* Short code fallback */}
      {isActive && !isExpired && (
        <div className="text-center">
          <p className="text-[10px] text-muted-foreground uppercase tracking-wider mb-1">
            or enter code manually
          </p>
          <p className="text-lg font-mono font-bold tracking-[0.3em] text-foreground">
            {shortCode}
          </p>
        </div>
      )}

      {/* Expired CTA */}
      {isExpired && status !== "verified" && (
        <button
          onClick={onRefresh}
          className="px-4 py-2 rounded-xl bg-accent text-accent-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]"
        >
          Regenerate QR
        </button>
      )}
    </div>
  );
};

export default QRDisplay;
