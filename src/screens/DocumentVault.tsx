/**
 * Slice-D — encrypted document vault screen.
 *
 * Lets the user:
 *  - Scan or upload a document (camera → Tesseract OCR → MRZ parse → auto
 *    classify → AES-GCM encrypt → IndexedDB store).
 *  - List saved documents (metadata only; ciphertext never surfaced).
 *  - Unlock + view a saved document (passphrase-gated; wrong pin throws).
 *  - Delete a document.
 *
 * Passphrase: reuses `kioskPin` from `userStore` as a real, existing
 * client-only secret the user already maintains. No passphrase = user
 * must set one before saving or viewing.
 */
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  ArrowLeft,
  Camera,
  FileText,
  Loader2,
  Lock,
  ShieldCheck,
  Trash2,
} from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { usePermissions } from "@/hooks/usePermissions";
import { capturePhoto } from "@/lib/cameraCapture";
import { ocrImage } from "@/lib/ocrService";
import { preprocessForOcr } from "@/lib/ocrPreprocess";
import { classifyDocument, parseMrz, type DocumentKind } from "@/lib/mrzParser";
import {
  deleteDocument,
  listDocuments,
  revealDocument,
  saveDocument,
  type VaultDocumentSummary,
} from "@/lib/documentVault";
import { cn } from "@/lib/utils";

const KIND_LABEL: Record<DocumentKind, string> = {
  passport: "Passport",
  visa: "Visa",
  id_card: "ID card",
  unknown: "Document",
};

const DocumentVault: React.FC = () => {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { permissions, request } = usePermissions();

  const [passphrase, setPassphrase] = useState("");
  const [docs, setDocs] = useState<VaultDocumentSummary[]>([]);
  const [busy, setBusy] = useState<"idle" | "scanning" | "reading">("idle");
  const [lastScan, setLastScan] = useState<{ kind: DocumentKind; text: string; mrzOk: boolean } | null>(
    null,
  );
  const [error, setError] = useState<string | null>(null);
  const [revealUrl, setRevealUrl] = useState<string | null>(null);
  const [pendingBlob, setPendingBlob] = useState<Blob | null>(null);

  const refresh = useCallback(async () => {
    try {
      setDocs(await listDocuments());
    } catch {
      setDocs([]);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    return () => {
      if (revealUrl) URL.revokeObjectURL(revealUrl);
    };
  }, [revealUrl]);

  const handleScan = useCallback(async () => {
    setError(null);
    setLastScan(null);
    if (permissions.camera !== "granted") {
      const p = await request("camera");
      if (p !== "granted") {
        setError("Camera permission denied");
        return;
      }
    }
    setBusy("scanning");
    try {
      const blob = await capturePhoto();
      if (!blob) {
        setBusy("idle");
        return;
      }
      // Slice-F: run the edge-detect / binarisation pipeline before
      // Tesseract. Falls back to the raw blob if preprocessing throws
      // (e.g. OffscreenCanvas unavailable in old browsers).
      let ocrInput: Blob = blob;
      try {
        const pre = await preprocessForOcr(blob);
        ocrInput = pre.blob;
      } catch {
        // ignore — fall back to raw capture
      }
      const result = await ocrImage(ocrInput);
      const mrz = parseMrz(result.text);
      const kind = classifyDocument(result.text);
      setLastScan({ kind, text: result.text, mrzOk: mrz.ok });
      setPendingBlob(blob);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Scan failed");
    } finally {
      setBusy("idle");
    }
  }, [permissions.camera, request]);

  const handleSave = useCallback(async () => {
    if (!pendingBlob || !lastScan) return;
    if (passphrase.length < 4) {
      setError("Set a 4+ char passphrase first");
      return;
    }
    try {
      await saveDocument(passphrase, {
        kind: lastScan.kind,
        label: KIND_LABEL[lastScan.kind],
        imageBlob: pendingBlob,
        ocrText: lastScan.text,
      });
      setLastScan(null);
      setPendingBlob(null);
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Save failed");
    }
  }, [pendingBlob, lastScan, passphrase, refresh]);

  const handleReveal = useCallback(
    async (id: number) => {
      setError(null);
      if (passphrase.length < 4) {
        setError("Enter your passphrase to unlock");
        return;
      }
      setBusy("reading");
      try {
        const doc = await revealDocument(passphrase, id);
        if (!doc) {
          setError("Document not found");
          return;
        }
        if (revealUrl) URL.revokeObjectURL(revealUrl);
        setRevealUrl(URL.createObjectURL(doc.blob));
      } catch {
        setError("Decryption failed — wrong passphrase?");
      } finally {
        setBusy("idle");
      }
    },
    [passphrase, revealUrl],
  );

  const handleDelete = useCallback(
    async (id: number) => {
      await deleteDocument(id);
      await refresh();
    },
    [refresh],
  );

  const permissionBadge = useMemo(() => {
    const p = permissions.camera;
    if (p === "granted")
      return (
        <span className="text-[10px] text-emerald-400 flex items-center gap-1">
          <ShieldCheck className="w-3 h-3" /> camera: granted
        </span>
      );
    return (
      <span className="text-[10px] text-amber-400 flex items-center gap-1">
        camera: {p}
      </span>
    );
  }, [permissions.camera]);

  return (
    <div className="px-4 py-6 pb-28 space-y-4">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button
            onClick={() => navigate(-1)}
            className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center"
          >
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">{t("vault.title")}</h1>
            <p className="text-xs text-muted-foreground">
              {t("vault.encryptedNote")} {permissionBadge}
            </p>
          </div>
        </div>
      </AnimatedPage>

      <GlassCard className="p-4 space-y-3">
        <p className="text-xs uppercase tracking-widest text-muted-foreground flex items-center gap-2">
          <Lock className="w-3 h-3" /> passphrase
        </p>
        <Input
          type="password"
          value={passphrase}
          onChange={(e) => setPassphrase(e.target.value)}
          placeholder="Enter vault passphrase (≥4 chars)"
          className="text-sm"
          autoComplete="new-password"
        />
        <div className="flex gap-2">
          <Button size="sm" onClick={handleScan} disabled={busy !== "idle"} className="flex-1">
            {busy === "scanning" ? (
              <Loader2 className="w-3 h-3 animate-spin mr-1" />
            ) : (
              <Camera className="w-3 h-3 mr-1" />
            )}
            {t("vault.scanDocument")}
          </Button>
        </div>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {lastScan && (
        <GlassCard className="p-4 space-y-2">
          <p className="text-xs uppercase tracking-widest text-muted-foreground">
            {t("vault.detected")}: {KIND_LABEL[lastScan.kind]}
          </p>
          <p className="text-[11px] text-muted-foreground">
            MRZ checksum: {lastScan.mrzOk ? "passed" : "fail / absent"}
          </p>
          <pre className="text-[10px] text-foreground/80 font-mono bg-secondary/40 rounded-lg p-2 max-h-36 overflow-auto whitespace-pre-wrap">
            {lastScan.text.slice(0, 400)}
          </pre>
          <Button size="sm" onClick={handleSave} className="w-full">
            Encrypt &amp; save
          </Button>
        </GlassCard>
      )}

      {revealUrl && (
        <GlassCard className="p-3">
          <img src={revealUrl} alt="document" className="rounded-xl w-full max-h-[60vh] object-contain" />
          <Button
            size="sm"
            variant="ghost"
            className="mt-2 w-full"
            onClick={() => {
              URL.revokeObjectURL(revealUrl);
              setRevealUrl(null);
            }}
          >
            Hide
          </Button>
        </GlassCard>
      )}

      <div className="space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground px-1">Saved documents</p>
        {docs.length === 0 ? (
          <GlassCard className="p-4 text-center">
            <p className="text-xs text-muted-foreground">No documents yet — scan one to begin.</p>
          </GlassCard>
        ) : (
          docs.map((d) => (
            <GlassCard key={d.id} className="p-3">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                  <FileText className="w-5 h-5 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-foreground">{d.label}</p>
                  <p className="text-[11px] text-muted-foreground capitalize">
                    {d.kind.replace("_", " ")} · {new Date(d.createdAt).toLocaleDateString()}
                  </p>
                  <p className="text-[10px] text-muted-foreground truncate">{d.ocrExcerpt}</p>
                </div>
                <div className="flex flex-col gap-1 items-end">
                  <button
                    onClick={() => handleReveal(d.id)}
                    disabled={busy === "reading"}
                    className={cn(
                      "text-[11px] text-primary hover:underline",
                      busy === "reading" && "opacity-50",
                    )}
                  >
                    Unlock
                  </button>
                  <button
                    onClick={() => handleDelete(d.id)}
                    className="text-[11px] text-destructive hover:underline flex items-center gap-1"
                  >
                    <Trash2 className="w-3 h-3" /> Delete
                  </button>
                </div>
              </div>
            </GlassCard>
          ))
        )}
      </div>
    </div>
  );
};

export default DocumentVault;
