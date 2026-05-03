/**
 * Live camera scanner with Sobel edge overlay + auto-capture-when-steady
 * (BACKLOG F 70 + F 71).
 *
 * Opens the device's rear camera via getUserMedia, renders the live feed
 * to a canvas at native resolution, computes a Sobel edge map every
 * other frame, and overlays it as a translucent layer on top so the
 * user gets visible feedback that the document framing is working.
 *
 * Auto-capture: a 32×32 luminance signature is taken every frame, the
 * frame-to-frame variance is tracked, and when it stays below a
 * threshold for ~8 frames in a row the captured frame is grabbed and
 * `onCapture(blob)` fires. The user can also tap a manual shutter.
 *
 * All processing runs on the main thread for now (mid-range phones can
 * comfortably hit 30 FPS at 320×240); a worker fast-path is doable
 * later if the budget tightens.
 *
 * Permission UX: if `getUserMedia` rejects we keep the surface visible
 * and surface a retry button, matching the rest of the app's patterns.
 */
import React, { useCallback, useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Camera, RefreshCw, ZapOff, Zap, Check } from "lucide-react";
import { detectEdges } from "@/lib/imageEdge";
import {
  createVarianceTracker,
  downsampleSignature,
  pushFrame,
  type VarianceTrackerState,
} from "@/lib/imageVariance";
import { haptics } from "@/utils/haptics";
import { uiSound } from "@/cinematic/uiSound";
import { audioCues } from "@/lib/audioCues";
import { spring } from "@/lib/motion-tokens";
import { cn } from "@/lib/utils";

interface Props {
  onCapture: (blob: Blob, dataUrl: string) => void;
  onCancel?: () => void;
  /** Disable auto-capture and only allow manual shutter. */
  manualOnly?: boolean;
  className?: string;
}

const FRAME_WIDTH = 480;
const FRAME_HEIGHT = 320;

const LiveCameraScanner: React.FC<Props> = ({
  onCapture,
  onCancel,
  manualOnly = false,
  className,
}) => {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const overlayRef = useRef<HTMLCanvasElement | null>(null);
  const captureRef = useRef<HTMLCanvasElement | null>(null);
  const trackerRef = useRef<VarianceTrackerState>(createVarianceTracker());
  const streamRef = useRef<MediaStream | null>(null);
  const rafRef = useRef<number | null>(null);
  const frameCountRef = useRef(0);
  const capturedRef = useRef(false);

  const [state, setState] = useState<"requesting" | "ready" | "denied" | "captured" | "error">(
    "requesting",
  );
  const [edgeOpacity, setEdgeOpacity] = useState(0.6);
  const [steady, setSteady] = useState(false);

  /** Stop the stream + cancel rAF; called on unmount + manual close. */
  const stop = useCallback(() => {
    if (rafRef.current !== null) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
  }, []);

  /** rAF loop: render edge overlay + variance tick. */
  const tick = useCallback(() => {
    const video = videoRef.current;
    const overlay = overlayRef.current;
    if (!video || !overlay || video.readyState < 2 || capturedRef.current) {
      rafRef.current = requestAnimationFrame(tick);
      return;
    }
    const ctx = overlay.getContext("2d", { willReadFrequently: true });
    if (!ctx) {
      rafRef.current = requestAnimationFrame(tick);
      return;
    }

    // Draw the current video frame to the overlay canvas, snapshot the
    // pixels, then redraw the overlay as the edge map.
    ctx.clearRect(0, 0, overlay.width, overlay.height);
    ctx.drawImage(video, 0, 0, overlay.width, overlay.height);
    const frame = ctx.getImageData(0, 0, overlay.width, overlay.height);

    frameCountRef.current += 1;

    // Run Sobel every other frame to keep CPU below 50%.
    if (frameCountRef.current % 2 === 0) {
      const edges = detectEdges(frame.data, overlay.width, overlay.height, 70);
      const edgeImageData = new ImageData(edges, overlay.width, overlay.height);
      ctx.clearRect(0, 0, overlay.width, overlay.height);
      ctx.putImageData(edgeImageData, 0, 0);
    } else {
      ctx.clearRect(0, 0, overlay.width, overlay.height);
    }

    // Variance tick — every frame, so steadiness fires within ~8 frames.
    if (!manualOnly) {
      const sig = downsampleSignature(frame.data, overlay.width, overlay.height);
      const result = pushFrame(trackerRef.current, sig);
      setSteady(result.steady);
      if (result.steady && !capturedRef.current) {
        capturedRef.current = true;
        captureNow();
      }
    }

    rafRef.current = requestAnimationFrame(tick);
    // Note: captureNow is stable via useCallback below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [manualOnly]);

  const captureNow = useCallback(() => {
    const video = videoRef.current;
    const target = captureRef.current;
    if (!video || !target) return;
    const ctx = target.getContext("2d");
    if (!ctx) return;
    capturedRef.current = true;
    ctx.drawImage(video, 0, 0, target.width, target.height);
    target.toBlob(
      (blob) => {
        if (!blob) return;
        const dataUrl = target.toDataURL("image/jpeg", 0.92);
        haptics.success();
        uiSound.confirm();
        // Crisp single-tone shutter cue layered alongside uiSound for
        // a fuller "snapped" feel.
        void audioCues.scan();
        setState("captured");
        onCapture(blob, dataUrl);
      },
      "image/jpeg",
      0.92,
    );
  }, [onCapture]);

  /** Restart the stream — used by Retry. */
  const start = useCallback(async () => {
    setState("requesting");
    capturedRef.current = false;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: "environment",
          width: { ideal: FRAME_WIDTH },
          height: { ideal: FRAME_HEIGHT },
        },
        audio: false,
      });
      streamRef.current = stream;
      const video = videoRef.current;
      if (!video) return;
      video.srcObject = stream;
      await video.play();
      setState("ready");
      rafRef.current = requestAnimationFrame(tick);
    } catch (err) {
      console.warn("camera-scanner: getUserMedia rejected", err);
      setState("denied");
    }
  }, [tick]);

  useEffect(() => {
    void start();
    return () => stop();
    // start/stop captured refs are stable.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div
      className={cn(
        "relative aspect-[3/2] rounded-2xl overflow-hidden bg-black border border-border/40",
        className,
      )}
    >
      {/* Live video — under everything. */}
      <video
        ref={videoRef}
        playsInline
        muted
        className="absolute inset-0 w-full h-full object-cover"
      />

      {/* Sobel edge overlay — exposed translucent. */}
      <canvas
        ref={overlayRef}
        width={FRAME_WIDTH}
        height={FRAME_HEIGHT}
        className="absolute inset-0 w-full h-full"
        style={{ opacity: edgeOpacity, mixBlendMode: "screen" }}
      />

      {/* Hidden canvas for the actual captured still. */}
      <canvas
        ref={captureRef}
        width={FRAME_WIDTH * 2}
        height={FRAME_HEIGHT * 2}
        className="hidden"
      />

      {/* Corner brackets (Apple-Wallet identity-scan vibe). */}
      <div aria-hidden className="absolute inset-4 pointer-events-none">
        {(["top-0 left-0", "top-0 right-0 rotate-90", "bottom-0 right-0 rotate-180", "bottom-0 left-0 -rotate-90"] as const).map((pos, i) => (
          <div
            key={i}
            className={cn(
              "absolute w-10 h-10 border-t-2 border-l-2 transition-colors",
              steady ? "border-emerald-300" : "border-white/70",
              pos,
            )}
          />
        ))}
      </div>

      {/* Steady status pill. */}
      <AnimatePresence>
        {state === "ready" && !manualOnly ? (
          <motion.div
            initial={{ y: -16, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -16, opacity: 0 }}
            transition={spring.snap}
            className="absolute top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full text-[11px] font-semibold tracking-wide"
            style={{
              backgroundColor: steady ? "rgba(16,185,129,0.85)" : "rgba(0,0,0,0.5)",
              color: steady ? "white" : "rgba(255,255,255,0.85)",
              backdropFilter: "blur(8px)",
            }}
            role="status"
            aria-live="polite"
          >
            {steady ? "HOLD STEADY — capturing" : "Frame the document, hold steady"}
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Bottom controls. */}
      <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex items-center gap-3">
        <motion.button
          type="button"
          whileTap={{ scale: 0.92 }}
          onClick={() => setEdgeOpacity((o) => (o > 0.1 ? 0 : 0.6))}
          className="w-11 h-11 rounded-full grid place-items-center bg-black/55 text-white border border-white/20 backdrop-blur"
          aria-label={edgeOpacity > 0 ? "Hide edge overlay" : "Show edge overlay"}
        >
          {edgeOpacity > 0 ? <Zap className="w-4 h-4" /> : <ZapOff className="w-4 h-4" />}
        </motion.button>

        <motion.button
          type="button"
          whileTap={{ scale: 0.94 }}
          onClick={() => {
            haptics.medium();
            captureNow();
          }}
          className="w-16 h-16 rounded-full bg-white text-black grid place-items-center border-4 border-white/80 active:scale-95"
          aria-label="Capture document"
          disabled={state !== "ready"}
        >
          <Camera className="w-6 h-6" />
        </motion.button>

        <motion.button
          type="button"
          whileTap={{ scale: 0.92 }}
          onClick={() => {
            stop();
            void start();
          }}
          className="w-11 h-11 rounded-full grid place-items-center bg-black/55 text-white border border-white/20 backdrop-blur"
          aria-label="Restart scanner"
        >
          <RefreshCw className="w-4 h-4" />
        </motion.button>
      </div>

      {/* Permission denied. */}
      {state === "denied" ? (
        <div className="absolute inset-0 grid place-items-center bg-black/85 text-white px-6 text-center">
          <div className="space-y-3">
            <p className="text-sm">Camera permission was denied.</p>
            <button
              type="button"
              onClick={() => void start()}
              className="px-4 py-2 rounded-xl bg-white text-black text-sm font-semibold min-h-[44px]"
            >
              Grant access
            </button>
            {onCancel ? (
              <button
                type="button"
                onClick={onCancel}
                className="block mx-auto text-xs text-white/70 underline underline-offset-2"
              >
                Skip
              </button>
            ) : null}
          </div>
        </div>
      ) : null}

      {/* Captured. */}
      {state === "captured" ? (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="absolute inset-0 grid place-items-center bg-emerald-500/85 text-white"
        >
          <Check className="w-14 h-14" strokeWidth={3} />
        </motion.div>
      ) : null}
    </div>
  );
};

export default LiveCameraScanner;
