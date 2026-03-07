import { useState, useEffect, useCallback, useRef } from "react";
import { appGenerateQR } from "@/lib/verificationSession";
import { eventBus } from "@/lib/eventBus";
import { demoUser } from "@/lib/demoData";
import type { VerificationSession, EntryReceipt } from "@/lib/verificationSession";

export type LinkStatus = "idle" | "waiting" | "processing" | "verified" | "expired" | "failed";

interface UseVerificationSessionReturn {
  status: LinkStatus;
  qrData: string;
  shortCode: string;
  expiresAt: number;
  sessionId: string | null;
  countryCode: string | null;
  receipt: EntryReceipt | null;
  error: string | null;
  generateQR: () => void;
  reset: () => void;
}

export function useVerificationSession(): UseVerificationSessionReturn {
  const [status, setStatus] = useState<LinkStatus>("idle");
  const [qrData, setQrData] = useState("");
  const [shortCode, setShortCode] = useState("");
  const [expiresAt, setExpiresAt] = useState(0);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [countryCode, setCountryCode] = useState<string | null>(null);
  const [receipt, setReceipt] = useState<EntryReceipt | null>(null);
  const [error, setError] = useState<string | null>(null);
  const refreshTimer = useRef<ReturnType<typeof setTimeout>>();

  const generateQR = useCallback(() => {
    const result = appGenerateQR({ userId: demoUser.id });
    setQrData(result.appToken);
    setShortCode(result.shortCode);
    setExpiresAt(result.expiresAt);
    setStatus("waiting");
    setError(null);
    setReceipt(null);

    // Auto-refresh before expiry
    clearTimeout(refreshTimer.current);
    refreshTimer.current = setTimeout(() => {
      setStatus("expired");
    }, result.expiresAt - Date.now());
  }, []);

  useEffect(() => {
    // Listen for session events
    const onVerified = (session: VerificationSession, rcpt: EntryReceipt) => {
      setStatus("processing");
      setSessionId(session.id);
      setCountryCode(session.countryCode);
      // Brief processing state then verified
      setTimeout(() => {
        setStatus("verified");
        setReceipt(rcpt);
      }, 600);
    };

    const onFailed = (_session: VerificationSession, err: string) => {
      setStatus("failed");
      setError(err);
    };

    const onExpired = () => {
      setStatus("expired");
    };

    const unsub1 = eventBus.on("session:verified", onVerified);
    const unsub2 = eventBus.on("session:failed", onFailed);
    const unsub3 = eventBus.on("session:expired", onExpired);

    return () => {
      unsub1();
      unsub2();
      unsub3();
      clearTimeout(refreshTimer.current);
    };
  }, []);

  const reset = useCallback(() => {
    setStatus("idle");
    setQrData("");
    setShortCode("");
    setExpiresAt(0);
    setSessionId(null);
    setCountryCode(null);
    setReceipt(null);
    setError(null);
    clearTimeout(refreshTimer.current);
  }, []);

  return {
    status,
    qrData,
    shortCode,
    expiresAt,
    sessionId,
    countryCode,
    receipt,
    error,
    generateQR,
    reset,
  };
}
