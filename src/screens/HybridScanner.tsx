/**
 * Slice-F — hybrid QR + document scanner.
 *
 * Previously QR scanning lived in `QRScanner.tsx` (opens a camera via
 * `@zxing/browser`) and document scanning lived in `DocumentVault.tsx`
 * (takes a still photo via `cameraCapture.ts`). This screen lets the
 * user pick either mode from one entry point, with the same camera
 * permission prompt, and then hands off to the existing scanners.
 *
 * Real device I/O. Real permissions. No fakes.
 */
import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  ArrowLeft,
  Camera as CameraIcon,
  FileText,
  QrCode,
  Loader2,
  ImageOff,
  Check,
} from "lucide-react";
import { Surface, Button, Text, Pill } from "@/components/ui/v2";
import {
  BrowserMultiFormatReader,
  type IScannerControls,
} from "@zxing/browser";
import { capturePhoto } from "@/lib/cameraCapture";
import { preprocessForOcr } from "@/lib/ocrPreprocess";
import { ocrImage } from "@/lib/ocrService";
import { classifyDocument } from "@/lib/mrzParser";
import { usePermissions } from "@/hooks/usePermissions";
import { toast } from "sonner";

type Mode = "picker" | "qr" | "doc";

interface OcrSummary {
  kind: string;
  excerpt: string;
  confidence: number;
  elapsedMs: number;
  edgeDensity: number;
}

const HybridScanner: React.FC = () => {
  const navigate = useNavigate();
  const [mode, setMode] = useState<Mode>("picker");
  const [qrResult, setQrResult] = useState<string | null>(null);
  const [scanning, setScanning] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [ocrSummary, setOcrSummary] = useState<OcrSummary | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const controlsRef = useRef<IScannerControls | null>(null);
  const permissions = usePermissions();

  useEffect(() => {
    return () => {
      controlsRef.current?.stop();
      controlsRef.current = null;
    };
  }, []);

  const startQr = async () => {
    if (permissions.permissions.camera !== "granted") {
      const state = await permissions.request("camera");
      if (state !== "granted") {
        toast.error("Camera permission denied");
        return;
      }
    }
    setMode("qr");
    setQrResult(null);
    setScanning(true);
    // The <video> element is rendered right below the state change; wait a
    // frame so the ref is populated before we try to attach the stream.
    await new Promise((r) => requestAnimationFrame(r));
    if (!videoRef.current) return;
    try {
      const reader = new BrowserMultiFormatReader();
      const controls = await reader.decodeFromVideoDevice(
        undefined,
        videoRef.current,
        (result, _err, ctrl) => {
          if (!result) return;
          ctrl.stop();
          controlsRef.current = null;
          setScanning(false);
          setQrResult(result.getText());
        },
      );
      controlsRef.current = controls;
    } catch (e) {
      setScanning(false);
      toast.error(
        e instanceof Error ? e.message : "Failed to start camera",
      );
    }
  };

  const stopQr = () => {
    controlsRef.current?.stop();
    controlsRef.current = null;
    setScanning(false);
  };

  const startDoc = async () => {
    if (permissions.permissions.camera !== "granted") {
      const state = await permissions.request("camera");
      if (state !== "granted") {
        toast.error("Camera permission denied");
        return;
      }
    }
    setMode("doc");
    setOcrSummary(null);
    setProcessing(true);
    try {
      const photo = await capturePhoto();
      if (!photo) {
        setProcessing(false);
        return;
      }
      const pre = await preprocessForOcr(photo);
      const ocr = await ocrImage(pre.blob);
      const kind = classifyDocument(ocr.text);
      setOcrSummary({
        kind,
        excerpt: ocr.text.slice(0, 120),
        confidence: ocr.confidence,
        elapsedMs: ocr.elapsedMs + pre.elapsedMs,
        edgeDensity: pre.edgeDensity,
      });
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Failed to scan document");
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="flex items-center gap-3 px-4 pt-6 pb-4">
        <button
          aria-label="Go back"
          onClick={() => {
            stopQr();
            navigate(-1);
          }}
          className="w-9 h-9 rounded-xl border border-border/30 flex items-center justify-center"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <Text variant="title-2" tone="primary">
            Hybrid scanner
          </Text>
          <Text variant="caption-1" tone="secondary">
            One camera, QR or documents
          </Text>
        </div>
      </div>

      <div className="px-4 space-y-4">
        <Surface variant="plain" radius="surface" className="p-4">
          <Text variant="caption-1" tone="secondary" className="mb-2">
            Camera permission
          </Text>
          <div className="flex items-center gap-2">
            <Pill
              variant={
                permissions.permissions.camera === "granted"
                  ? "success"
                  : "muted"
              }
            >
              {permissions.permissions.camera}
            </Pill>
            {permissions.permissions.camera !== "granted" && (
              <Button size="sm" onClick={() => permissions.request("camera")}>
                Grant
              </Button>
            )}
          </div>
        </Surface>

        {mode === "picker" && (
          <div className="grid grid-cols-2 gap-3">
            <Surface
              variant="elevated"
              radius="surface"
              className="flex flex-col items-center gap-3 p-6 cursor-pointer"
              onClick={() => void startQr()}
            >
              <QrCode className="w-8 h-8 text-brand" />
              <Text variant="body-strong" tone="primary">
                QR code
              </Text>
              <Text variant="caption-2" tone="secondary" align="center">
                Scan payment or boarding-pass QRs
              </Text>
            </Surface>

            <Surface
              variant="elevated"
              radius="surface"
              className="flex flex-col items-center gap-3 p-6 cursor-pointer"
              onClick={() => void startDoc()}
            >
              <FileText className="w-8 h-8 text-brand" />
              <Text variant="body-strong" tone="primary">
                Document
              </Text>
              <Text variant="caption-2" tone="secondary" align="center">
                Scan passport / visa / ID
              </Text>
            </Surface>
          </div>
        )}

        {mode === "qr" && (
          <Surface variant="plain" radius="surface" className="p-4 space-y-3">
            <div className="relative w-full aspect-[4/3] bg-black/80 rounded-xl overflow-hidden">
              <video
                ref={videoRef}
                muted
                playsInline
                className="w-full h-full object-cover"
              />
              {scanning && (
                <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                  <Loader2 className="w-6 h-6 animate-spin text-white" />
                </div>
              )}
            </div>
            {qrResult && (
              <Surface
                variant="plain"
                radius="surface"
                className="p-3 border border-green-500/30"
              >
                <div className="flex items-center gap-2 mb-1">
                  <Check className="w-4 h-4 text-green-500" />
                  <Text variant="body-strong" tone="primary">
                    Decoded
                  </Text>
                </div>
                <Text
                  variant="caption-1"
                  tone="secondary"
                  className="break-all font-mono"
                >
                  {qrResult}
                </Text>
              </Surface>
            )}
            <div className="flex gap-2">
              <Button
                variant="ghost"
                onClick={() => {
                  stopQr();
                  setMode("picker");
                  setQrResult(null);
                }}
              >
                Back to picker
              </Button>
              {qrResult && (
                <Button
                  variant="default"
                  onClick={() => {
                    setQrResult(null);
                    void startQr();
                  }}
                >
                  Scan another
                </Button>
              )}
            </div>
          </Surface>
        )}

        {mode === "doc" && (
          <Surface variant="plain" radius="surface" className="p-4 space-y-3">
            {processing && (
              <div className="flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin" />
                <Text variant="caption-1" tone="secondary">
                  Preprocessing + OCR in progress…
                </Text>
              </div>
            )}
            {!processing && !ocrSummary && (
              <div className="flex items-center gap-2">
                <ImageOff className="w-4 h-4 text-muted-foreground" />
                <Text variant="caption-1" tone="secondary">
                  No capture yet.
                </Text>
              </div>
            )}
            {ocrSummary && (
              <div className="space-y-2">
                <Text variant="body-strong" tone="primary">
                  {ocrSummary.kind.toUpperCase()}
                </Text>
                <Text variant="caption-1" tone="secondary">
                  Confidence {Math.round(ocrSummary.confidence)}%, edge density{" "}
                  {(ocrSummary.edgeDensity * 100).toFixed(1)}%,{" "}
                  {Math.round(ocrSummary.elapsedMs)}ms
                </Text>
                <Surface
                  variant="plain"
                  radius="surface"
                  className="p-2 mt-2 bg-surface-overlay"
                >
                  <Text
                    variant="caption-2"
                    tone="secondary"
                    className="font-mono whitespace-pre-wrap break-all"
                  >
                    {ocrSummary.excerpt}
                    {ocrSummary.excerpt.length >= 120 ? "…" : ""}
                  </Text>
                </Surface>
              </div>
            )}
            <div className="flex gap-2">
              <Button
                variant="ghost"
                onClick={() => {
                  setMode("picker");
                  setOcrSummary(null);
                }}
              >
                Back to picker
              </Button>
              <Button
                onClick={() => void startDoc()}
                disabled={processing}
              >
                <CameraIcon className="w-4 h-4 mr-1" />
                Capture
              </Button>
            </div>
          </Surface>
        )}
      </div>
    </div>
  );
};

export default HybridScanner;
