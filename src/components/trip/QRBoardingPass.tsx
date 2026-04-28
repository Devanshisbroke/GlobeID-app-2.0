import React, { useEffect, useRef, useState } from "react";
import QRCode from "qrcode";
import { Plane, AlertCircle, User, Calendar, Hash } from "lucide-react";
import { issueBoardingPass, type BoardingPassPayload } from "@/lib/boardingPass";
import { cn } from "@/lib/utils";

export interface QRBoardingPassProps {
  passenger: string;
  passportNo: string | null;
  flightNumber: string;
  airline: string;
  fromIata: string;
  toIata: string;
  scheduledDate: string;
  legId: string;
  tripId: string | null;
  className?: string;
}

const QRBoardingPass: React.FC<QRBoardingPassProps> = ({
  passenger,
  passportNo,
  flightNumber,
  airline,
  fromIata,
  toIata,
  scheduledDate,
  legId,
  tripId,
  className,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [payload, setPayload] = useState<BoardingPassPayload | null>(null);

  // `issueBoardingPass` is async (HMAC-SHA256 via Web Crypto) and stamps
  // `iat: Date.now()` into the payload, so we sign once on identity-shaping
  // input changes and let `<canvas>` re-render only when the resulting
  // qrText flips.
  useEffect(() => {
    let cancelled = false;
    setError(null);
    issueBoardingPass({
      passenger,
      passportNo,
      flightNumber,
      airline,
      fromIata,
      toIata,
      scheduledDate,
      legId,
      tripId,
    })
      .then(({ payload: p, qrText }) => {
        if (cancelled) return;
        setPayload(p);
        if (canvasRef.current) {
          return QRCode.toCanvas(canvasRef.current, qrText, {
            width: 200,
            margin: 1,
            color: { dark: "#0f172a", light: "#ffffff" },
            errorCorrectionLevel: "M",
          });
        }
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "QR render failed");
      });
    return () => {
      cancelled = true;
    };
  }, [
    passenger,
    passportNo,
    flightNumber,
    airline,
    fromIata,
    toIata,
    scheduledDate,
    legId,
    tripId,
  ]);

  return (
    <div
      className={cn(
        "rounded-2xl border border-border bg-card overflow-hidden",
        className,
      )}
      data-leg-id={legId}
    >
      <div className="bg-gradient-to-br from-primary/10 via-primary/5 to-transparent px-4 py-3 border-b border-border">
        <div className="flex items-center gap-2">
          <Plane className="w-4 h-4 text-primary" />
          <p className="text-[11px] font-semibold tracking-wider uppercase text-primary">
            Boarding pass
          </p>
        </div>
      </div>

      <div className="p-4 space-y-4">
        {/* Route */}
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
              From
            </p>
            <p className="font-mono text-2xl font-semibold text-foreground">
              {fromIata}
            </p>
          </div>
          <div className="flex-1 flex items-center justify-center">
            <Plane className="w-5 h-5 text-primary rotate-90" />
          </div>
          <div className="text-right">
            <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
              To
            </p>
            <p className="font-mono text-2xl font-semibold text-foreground">
              {toIata}
            </p>
          </div>
        </div>

        {/* QR + meta */}
        <div className="flex items-start gap-4">
          <div className="bg-white p-2 rounded-lg shrink-0">
            {error ? (
              <div className="w-[180px] h-[180px] flex items-center justify-center text-[11px] text-destructive p-2 text-center">
                QR error: {error}
              </div>
            ) : (
              <canvas
                ref={canvasRef}
                className="w-[180px] h-[180px]"
                aria-label={`Demo boarding pass QR for ${flightNumber}`}
              />
            )}
          </div>

          <div className="flex-1 space-y-2 text-[12px]">
            <div className="flex items-start gap-1.5">
              <User className="w-3 h-3 mt-0.5 text-muted-foreground shrink-0" />
              <div className="min-w-0">
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
                  Passenger
                </p>
                <p className="font-semibold text-foreground truncate">
                  {passenger}
                </p>
                {payload?.passportLast4 ? (
                  <p className="text-[10.5px] font-mono text-muted-foreground">
                    Passport ····{payload.passportLast4}
                  </p>
                ) : (
                  <p className="text-[10.5px] text-muted-foreground italic">
                    No passport on file
                  </p>
                )}
              </div>
            </div>

            <div className="flex items-start gap-1.5">
              <Hash className="w-3 h-3 mt-0.5 text-muted-foreground shrink-0" />
              <div>
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
                  Flight
                </p>
                <p className="font-mono font-semibold text-foreground">
                  {flightNumber}
                </p>
                <p className="text-[10.5px] text-muted-foreground">{airline}</p>
              </div>
            </div>

            <div className="flex items-start gap-1.5">
              <Calendar className="w-3 h-3 mt-0.5 text-muted-foreground shrink-0" />
              <div>
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
                  Date
                </p>
                <p className="font-mono font-semibold text-foreground">
                  {scheduledDate}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Required surface marker — non-removable per Phase 9 rules */}
      <div className="bg-amber-500/10 border-t border-amber-500/20 px-4 py-2 flex items-start gap-2">
        <AlertCircle className="w-3.5 h-3.5 text-amber-500 mt-0.5 shrink-0" />
        <p className="text-[10.5px] text-amber-600 dark:text-amber-400 leading-snug">
          <span className="font-semibold">Demo boarding pass.</span> Not airline-issued.
          QR encodes a GlobeID-signed v1 demo payload (kind=
          <span className="font-mono">globeid.bp.v1</span>) verified by HMAC-SHA256
          inside the bundled <span className="font-mono">KioskSimulator</span> only;
          not valid for gate clearance.
        </p>
      </div>
    </div>
  );
};

export default QRBoardingPass;
