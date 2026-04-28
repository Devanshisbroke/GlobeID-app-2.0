/**
 * QRScanner — real camera-backed QR decoding (Slice-A).
 *
 * Uses `@zxing/browser` to read frames off the camera and decode QR
 * payloads. On successful decode, calls the real wallet ledger via
 * `useWalletStore.recordTransaction()` with a fresh idempotency key so
 * the scan is retry-safe.
 *
 * Falls back to a manual paste mode (text input + Decode button) when
 * camera access is unavailable (desktop without camera, permission
 * denied, etc.) so the flow is still usable.
 *
 * The "demo gateway" label is shown loudly — the ledger entry is real,
 * but no PSP processed money. This is the honest version of the prior
 * `setTimeout`-based fake.
 */
import React, { useEffect, useRef, useState } from "react";
import { BrowserMultiFormatReader, type IScannerControls } from "@zxing/browser";
import { GlassCard } from "@/components/ui/GlassCard";
import { useWalletStore } from "@/store/walletStore";
import { decodeQRPayload, type QRPayload } from "@/services/paymentGateway";
import { ScanLine, Check, AlertTriangle, Camera, Keyboard, Info } from "lucide-react";
import { cn } from "@/lib/utils";

type ScanState =
  | { kind: "idle" }
  | { kind: "starting" }
  | { kind: "scanning" }
  | { kind: "no-camera"; reason: string }
  | { kind: "decoded"; payload: QRPayload }
  | { kind: "paying" }
  | { kind: "success"; message: string }
  | { kind: "error"; message: string };

const QRScanner: React.FC<{ onClose?: () => void }> = ({ onClose }) => {
  const recordTransaction = useWalletStore((s) => s.recordTransaction);
  const balances = useWalletStore((s) => s.balances);
  const [state, setState] = useState<ScanState>({ kind: "idle" });
  const [manualInput, setManualInput] = useState("");
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const controlsRef = useRef<IScannerControls | null>(null);

  // Stop the camera reliably on unmount or state transition away from scanning.
  useEffect(() => {
    return () => {
      controlsRef.current?.stop();
      controlsRef.current = null;
    };
  }, []);

  const stopCamera = () => {
    controlsRef.current?.stop();
    controlsRef.current = null;
  };

  const startCamera = async () => {
    setState({ kind: "starting" });
    if (!videoRef.current) {
      setState({ kind: "no-camera", reason: "Video element not ready" });
      return;
    }
    try {
      const reader = new BrowserMultiFormatReader();
      // `decodeFromVideoDevice(undefined, ...)` lets the browser pick the
      // back camera on mobile (it prefers `environment` automatically).
      const controls = await reader.decodeFromVideoDevice(
        undefined,
        videoRef.current,
        (result, _err, ctrl) => {
          if (!result) return;
          const payload = decodeQRPayload(result.getText());
          if (!payload) return; // not one of ours; keep scanning
          ctrl.stop();
          controlsRef.current = null;
          setState({ kind: "decoded", payload });
        },
      );
      controlsRef.current = controls;
      setState({ kind: "scanning" });
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Camera unavailable";
      setState({ kind: "no-camera", reason: msg });
    }
  };

  const tryManual = () => {
    const payload = decodeQRPayload(manualInput.trim());
    if (!payload) {
      setState({ kind: "error", message: "Invalid QR payload" });
      return;
    }
    setState({ kind: "decoded", payload });
  };

  const confirmPay = async (payload: QRPayload) => {
    setState({ kind: "paying" });
    try {
      const balance = balances.find((b) => b.currency === payload.currency);
      if (!balance) {
        setState({ kind: "error", message: `No ${payload.currency} balance. Top up first.` });
        return;
      }
      const tx = await recordTransaction({
        type: "payment",
        amount: payload.amount,
        currency: payload.currency,
        description: payload.merchant,
        merchant: payload.merchant,
        category: "shopping",
        icon: "QrCode",
        reference: payload.reference,
      });
      setState({
        kind: "success",
        message: `Paid ${payload.currency} ${payload.amount.toLocaleString()} to ${payload.merchant} (#${tx.id.slice(-6)})`,
      });
    } catch (e) {
      setState({
        kind: "error",
        message: e instanceof Error ? e.message : "Payment failed",
      });
    }
  };

  const reset = () => {
    stopCamera();
    setManualInput("");
    setState({ kind: "idle" });
  };

  return (
    <GlassCard variant="premium" depth="lg" className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-bold text-foreground flex items-center gap-2">
          <ScanLine className="w-4 h-4 text-primary" /> Scan & Pay
        </h3>
        {onClose && <button onClick={onClose} className="text-xs text-muted-foreground" aria-label="Close">✕</button>}
      </div>

      <div className="rounded-xl border border-amber-500/30 bg-amber-500/5 p-2 flex items-start gap-2 text-[11px] text-amber-700 dark:text-amber-400">
        <Info className="w-3.5 h-3.5 mt-0.5 shrink-0" />
        <span>
          <strong>Demo gateway, real ledger.</strong> Your wallet records the transaction with idempotency,
          but no PSP processes money. Wire <code className="px-1 rounded bg-amber-500/10">STRIPE_SECRET_KEY</code>
          {" "}for live charges.
        </span>
      </div>

      <div className="relative aspect-square max-w-[280px] mx-auto rounded-2xl overflow-hidden border-2 border-dashed border-border/50 bg-secondary/20">
        <video
          ref={videoRef}
          className={cn(
            "w-full h-full object-cover",
            state.kind === "scanning" || state.kind === "starting" ? "block" : "hidden",
          )}
          muted
          playsInline
        />

        {state.kind === "idle" && (
          <div className="absolute inset-0 flex items-center justify-center text-center space-y-2 p-4">
            <div>
              <Camera className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
              <p className="text-xs text-muted-foreground">Tap to scan a payment QR</p>
            </div>
          </div>
        )}

        {state.kind === "starting" && (
          <div className="absolute inset-0 flex items-center justify-center text-center animate-pulse">
            <div>
              <ScanLine className="w-10 h-10 text-primary mx-auto" />
              <p className="text-xs text-muted-foreground mt-2">Starting camera…</p>
            </div>
          </div>
        )}

        {state.kind === "no-camera" && (
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center p-3 gap-2">
            <Keyboard className="w-9 h-9 text-muted-foreground" />
            <p className="text-[11px] text-muted-foreground">{state.reason}</p>
            <p className="text-[11px] text-muted-foreground">Paste payload below.</p>
          </div>
        )}

        {state.kind === "decoded" && (
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center p-4 space-y-2 animate-fade-in">
            <Check className="w-9 h-9 text-accent" />
            <p className="text-xs text-muted-foreground">Pay</p>
            <p className="text-2xl font-bold text-foreground tabular-nums">
              {state.payload.currency} {state.payload.amount.toLocaleString()}
            </p>
            <p className="text-xs text-muted-foreground">to {state.payload.merchant}</p>
          </div>
        )}

        {state.kind === "paying" && (
          <div className="absolute inset-0 flex items-center justify-center text-center animate-pulse">
            <div>
              <ScanLine className="w-10 h-10 text-primary mx-auto" />
              <p className="text-xs text-muted-foreground mt-2">Recording on ledger…</p>
            </div>
          </div>
        )}

        {state.kind === "success" && (
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center text-accent p-4 animate-fade-in">
            <Check className="w-10 h-10 mx-auto" />
            <p className="text-xs font-medium mt-2">{state.message}</p>
          </div>
        )}

        {state.kind === "error" && (
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center text-destructive p-4 animate-fade-in">
            <AlertTriangle className="w-10 h-10 mx-auto" />
            <p className="text-xs font-medium mt-2">{state.message}</p>
          </div>
        )}

        {/* Scanner frame corners */}
        <div className="absolute top-2 left-2 w-6 h-6 border-t-2 border-l-2 border-primary rounded-tl-lg pointer-events-none" />
        <div className="absolute top-2 right-2 w-6 h-6 border-t-2 border-r-2 border-primary rounded-tr-lg pointer-events-none" />
        <div className="absolute bottom-2 left-2 w-6 h-6 border-b-2 border-l-2 border-primary rounded-bl-lg pointer-events-none" />
        <div className="absolute bottom-2 right-2 w-6 h-6 border-b-2 border-r-2 border-primary rounded-br-lg pointer-events-none" />
      </div>

      {state.kind === "no-camera" && (
        <div className="space-y-2">
          <label className="text-[10px] text-muted-foreground uppercase tracking-widest block">
            Paste QR payload
          </label>
          <input
            type="text"
            value={manualInput}
            onChange={(e) => setManualInput(e.target.value)}
            placeholder="Base64 payload from QR"
            className="w-full py-2.5 px-3 rounded-xl glass border border-border/40 text-xs text-foreground bg-transparent outline-none min-h-[44px] font-mono"
          />
          <button
            onClick={tryManual}
            disabled={!manualInput.trim()}
            className="w-full py-3 rounded-xl text-sm font-semibold bg-gradient-brand text-primary-foreground shadow-glow-md min-h-[48px] disabled:opacity-40"
          >
            Decode
          </button>
        </div>
      )}

      {state.kind === "idle" && (
        <button
          onClick={startCamera}
          className="w-full py-3 rounded-xl text-sm font-semibold bg-gradient-brand text-primary-foreground shadow-glow-md min-h-[48px] flex items-center justify-center gap-2"
        >
          <Camera className="w-4 h-4" /> Start camera
        </button>
      )}

      {state.kind === "scanning" && (
        <button
          onClick={() => {
            stopCamera();
            setState({ kind: "idle" });
          }}
          className="w-full py-3 rounded-xl text-sm font-medium glass border border-border/40 text-foreground min-h-[48px]"
        >
          Cancel scan
        </button>
      )}

      {state.kind === "decoded" && (
        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={reset}
            className="py-3 rounded-xl text-sm font-medium glass border border-border/40 text-foreground min-h-[48px]"
          >
            Cancel
          </button>
          <button
            onClick={() => confirmPay(state.payload)}
            className="py-3 rounded-xl text-sm font-semibold bg-gradient-brand text-primary-foreground shadow-glow-md min-h-[48px]"
          >
            Confirm pay
          </button>
        </div>
      )}

      {(state.kind === "success" || state.kind === "error") && (
        <button
          onClick={reset}
          className="w-full py-3 rounded-xl text-sm font-semibold bg-gradient-brand text-primary-foreground shadow-glow-md min-h-[48px]"
        >
          Scan another
        </button>
      )}
    </GlassCard>
  );
};

export default QRScanner;
