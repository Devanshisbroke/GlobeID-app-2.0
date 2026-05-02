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
  Save,
  Lock,
} from "lucide-react";
import { Surface, Button, Text, Pill } from "@/components/ui/v2";
import {
  BrowserMultiFormatReader,
  type IScannerControls,
} from "@zxing/browser";
import { capturePhoto } from "@/lib/cameraCapture";
import { preprocessForOcr } from "@/lib/ocrPreprocess";
import { ocrImage } from "@/lib/ocrService";
import { classifyDocument, parseMrz, type DocumentKind, type MrzFields } from "@/lib/mrzParser";
import { saveDocument } from "@/lib/documentVault";
import { mrzFieldsToTravelDocument } from "@/lib/mrzToDocument";
import { useUserStore } from "@/store/userStore";
import { usePermissions } from "@/hooks/usePermissions";
import { haptics } from "@/utils/haptics";
import { audioCues } from "@/lib/audioFeedback";
import { toast } from "sonner";
import LottieView from "@/components/animations/LottieView";
import successCheckLottie from "@/assets/lottie/success-check.json";
import { AnimatePresence, motion } from "framer-motion";

type Mode = "picker" | "qr" | "doc";

const LAST_MODE_KEY = "globeid:scanner:last-mode";

function loadLastMode(): Mode {
  try {
    const raw = localStorage.getItem(LAST_MODE_KEY);
    if (raw === "qr" || raw === "doc") return raw;
  } catch {
    /* localStorage may be unavailable */
  }
  return "picker";
}

function persistMode(mode: Mode): void {
  try {
    if (mode === "picker") localStorage.removeItem(LAST_MODE_KEY);
    else localStorage.setItem(LAST_MODE_KEY, mode);
  } catch {
    /* ignore */
  }
}

interface OcrSummary {
  kind: DocumentKind;
  excerpt: string;
  text: string;
  confidence: number;
  elapsedMs: number;
  edgeDensity: number;
  mrzOk: boolean;
  fields: MrzFields | null;
}

const KIND_LABEL: Record<DocumentKind, string> = {
  passport: "Passport",
  visa: "Visa",
  id_card: "ID card",
  unknown: "Document",
};

const HybridScanner: React.FC = () => {
  const navigate = useNavigate();
  const addDocument = useUserStore((s) => s.addDocument);
  const documents = useUserStore((s) => s.documents);
  const [mode, setMode] = useState<Mode>("picker");
  const [qrResult, setQrResult] = useState<string | null>(null);
  const [scanning, setScanning] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [ocrSummary, setOcrSummary] = useState<OcrSummary | null>(null);
  const [capturedDoc, setCapturedDoc] = useState<Blob | null>(null);
  const [passphrase, setPassphrase] = useState("");
  const [savedDocumentId, setSavedDocumentId] = useState<number | null>(null);
  const [walletDocId, setWalletDocId] = useState<string | null>(null);
  const [showSuccessBurst, setShowSuccessBurst] = useState(false);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const controlsRef = useRef<IScannerControls | null>(null);
  const permissions = usePermissions();

  useEffect(() => {
    return () => {
      controlsRef.current?.stop();
      controlsRef.current = null;
    };
  }, []);

  // Restore last-used mode on mount so a power user that always scans
  // documents skips the picker. Camera permission is still requested
  // explicitly inside `startQr` / `startDoc` so this never opens the
  // camera unsolicited.
  useEffect(() => {
    const last = loadLastMode();
    if (last !== "picker") setMode(last);
  }, []);

  useEffect(() => {
    persistMode(mode);
  }, [mode]);

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
    setCapturedDoc(null);
    setSavedDocumentId(null);
    setProcessing(true);
    try {
      const photo = await capturePhoto();
      if (!photo) {
        setProcessing(false);
        return;
      }
      let ocrInput = photo;
      let preprocessMs = 0;
      let edgeDensity = 0;
      try {
        const pre = await preprocessForOcr(photo);
        ocrInput = pre.blob;
        preprocessMs = pre.elapsedMs;
        edgeDensity = pre.edgeDensity;
      } catch {
        // Keep the scan usable on older mobile WebViews without OffscreenCanvas.
      }
      const ocr = await ocrImage(ocrInput);
      const kind = classifyDocument(ocr.text);
      const mrz = parseMrz(ocr.text);
      setCapturedDoc(photo);
      setOcrSummary({
        kind,
        excerpt: ocr.text.slice(0, 120),
        text: ocr.text,
        confidence: ocr.confidence,
        elapsedMs: ocr.elapsedMs + preprocessMs,
        edgeDensity,
        mrzOk: mrz.ok,
        fields: mrz.fields,
      });
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Failed to scan document");
    } finally {
      setProcessing(false);
    }
  };

  const handleSaveDocument = async () => {
    if (!capturedDoc || !ocrSummary) return;
    if (passphrase.trim().length < 4) {
      toast.error("Enter a 4+ character vault passphrase");
      return;
    }
    setSaving(true);
    try {
      const id = await saveDocument(passphrase, {
        kind: ocrSummary.kind,
        label: KIND_LABEL[ocrSummary.kind],
        imageBlob: capturedDoc,
        ocrText: ocrSummary.text,
      });
      setSavedDocumentId(id);
      audioCues.success();
      toast.success("Document saved to vault");
    } catch (e) {
      audioCues.error();
      toast.error(e instanceof Error ? e.message : "Failed to save document");
    } finally {
      setSaving(false);
    }
  };

  /**
   * Promote a successful MRZ scan to a wallet `TravelDocument` so it
   * shows up in `Wallet → Documents → PassStack`. The encrypted
   * vault entry (if the user also entered a passphrase) is the
   * source of truth for the raw image; this is the surfaced
   * metadata + QR target. Idempotent on `id`.
   */
  const handleAddToWallet = () => {
    if (!ocrSummary || !ocrSummary.fields) return;
    const doc = mrzFieldsToTravelDocument({
      kind: ocrSummary.kind,
      fields: ocrSummary.fields,
    });
    if (!doc) {
      toast.error("Document type not supported in Wallet yet");
      return;
    }
    haptics.success();
    addDocument(doc);
    setWalletDocId(doc.id);
    setShowSuccessBurst(true);
    // Auto-dismiss the burst after the Lottie completes (60 frames @ 60fps).
    window.setTimeout(() => setShowSuccessBurst(false), 1100);
    toast.success(`Added ${doc.label} to your Wallet`);
  };

  const alreadyInWallet =
    walletDocId !== null && documents.some((d) => d.id === walletDocId);

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Lottie success burst — overlays the scanner briefly when a
          document is added to the wallet. AnimatePresence mounts the
          backdrop only while showSuccessBurst is true so the Lottie
          chunk is also kept off the cold-start path. */}
      <AnimatePresence>
        {showSuccessBurst && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.18 }}
            className="fixed inset-0 z-[var(--z-toast)] flex items-center justify-center bg-black/40 backdrop-blur-sm pointer-events-none"
            aria-hidden
          >
            <LottieView
              data={successCheckLottie}
              width={220}
              height={220}
              loop={false}
              ariaLabel="Document added to wallet"
              fallback={
                <div className="w-[220px] h-[220px] rounded-full border-4 border-emerald-400/70 flex items-center justify-center text-emerald-300 text-6xl">
                  ✓
                </div>
              }
            />
          </motion.div>
        )}
      </AnimatePresence>

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
              <Text variant="body-em" tone="primary">
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
              <Text variant="body-em" tone="primary">
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
                  <Text variant="body-em" tone="primary">
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
                  variant="primary"
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
              <div className="space-y-3">
                <Text variant="body-em" tone="primary">
                  {KIND_LABEL[ocrSummary.kind]}
                </Text>
                <Text variant="caption-1" tone="secondary">
                  Confidence {Math.round(ocrSummary.confidence)}%, edge density{" "}
                  {(ocrSummary.edgeDensity * 100).toFixed(1)}%,{" "}
                  {Math.round(ocrSummary.elapsedMs)}ms
                </Text>
                <Text variant="caption-1" tone={ocrSummary.mrzOk ? "accent" : "warning"}>
                  MRZ checksum: {ocrSummary.mrzOk ? "passed" : "not available / needs review"}
                </Text>
                {ocrSummary.fields ? (
                  <>
                    <div className="grid grid-cols-2 gap-2">
                      <ExtractedField label="Name" value={`${ocrSummary.fields.givenNames} ${ocrSummary.fields.surname}`.trim()} />
                      <ExtractedField label="Document" value={ocrSummary.fields.documentNumber} />
                      <ExtractedField label="Nationality" value={ocrSummary.fields.nationality} />
                      <ExtractedField label="Expires" value={ocrSummary.fields.dateOfExpiry} />
                    </div>
                    <Button
                      variant={alreadyInWallet ? "secondary" : "primary"}
                      onClick={handleAddToWallet}
                      disabled={alreadyInWallet}
                      leading={alreadyInWallet ? <Check /> : <Save />}
                      className="w-full"
                      aria-label={
                        alreadyInWallet
                          ? "Document already in wallet"
                          : "Add scanned document to wallet"
                      }
                    >
                      {alreadyInWallet ? "Added to Wallet" : "Add to Wallet"}
                    </Button>
                  </>
                ) : (
                  <Text variant="caption-1" tone="secondary">
                    No MRZ fields found. The raw OCR text is still available below.
                  </Text>
                )}
                <Surface
                  variant="plain"
                  radius="surface"
                  className="p-2 bg-surface-overlay"
                >
                  <Text
                    variant="caption-2"
                    tone="secondary"
                    className="font-mono whitespace-pre-wrap break-all"
                  >
                    {ocrSummary.excerpt}
                    {ocrSummary.excerpt.length >= 120 ? "..." : ""}
                  </Text>
                </Surface>
                <Surface
                  variant="plain"
                  radius="surface"
                  className="p-3 space-y-2 bg-surface-overlay"
                >
                  <div className="flex items-center gap-2">
                    <Lock className="w-4 h-4 text-ink-tertiary" />
                    <Text variant="caption-1" tone="secondary">
                      Save encrypted copy to document vault
                    </Text>
                  </div>
                  <input
                    type="password"
                    value={passphrase}
                    onChange={(e) => setPassphrase(e.target.value)}
                    placeholder="Vault passphrase"
                    className="w-full rounded-p7-input border border-surface-hairline bg-surface-base px-3 py-2 text-p7-callout text-ink-primary outline-none focus:ring-2 focus:ring-[hsl(var(--p7-ring))]"
                    autoComplete="new-password"
                  />
                  <div className="flex flex-wrap gap-2">
                    <Button
                      onClick={() => void handleSaveDocument()}
                      disabled={saving || savedDocumentId !== null}
                      loading={saving}
                      leading={<Save />}
                    >
                      {savedDocumentId ? "Saved" : "Save document"}
                    </Button>
                    {savedDocumentId ? (
                      <Button variant="secondary" onClick={() => navigate("/vault")}>
                        Open vault
                      </Button>
                    ) : null}
                  </div>
                </Surface>
              </div>
            )}
            <div className="flex gap-2">
              <Button
                variant="ghost"
                onClick={() => {
                  setMode("picker");
                  setOcrSummary(null);
                  setCapturedDoc(null);
                  setSavedDocumentId(null);
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

const ExtractedField: React.FC<{ label: string; value: string }> = ({ label, value }) => (
  <Surface variant="plain" radius="input" className="p-2 bg-surface-overlay">
    <Text variant="caption-2" tone="tertiary" className="uppercase">
      {label}
    </Text>
    <Text variant="caption-1" tone="primary" className="break-words">
      {value || "Not found"}
    </Text>
  </Surface>
);

export default HybridScanner;
