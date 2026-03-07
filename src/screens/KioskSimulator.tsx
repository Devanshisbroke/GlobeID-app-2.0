import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { kioskVerifyPassport, kioskScanApp, getAllSessions, type VerificationSession } from "@/lib/verificationSession";
import { getAuditLog } from "@/lib/auditLog";
import { countryThemes } from "@/lib/countryThemes";
import { cn } from "@/lib/utils";
import { Monitor, ScanLine, Wifi, AlertTriangle, CheckCircle2, XCircle, Clock } from "lucide-react";

const KIOSK_ID = "kiosk-sim-001";

const statusColors: Record<string, string> = {
  pending: "text-yellow-400",
  app_scanned: "text-accent",
  verified: "text-accent",
  expired: "text-muted-foreground",
  failed: "text-destructive",
};

const KioskSimulator: React.FC = () => {
  const [countryCode, setCountryCode] = useState("IN");
  const [passportHash, setPassportHash] = useState("sha256:demo_passport_0af4c3d");
  const [biometricPass, setBiometricPass] = useState(true);
  const [currentSession, setCurrentSession] = useState<VerificationSession | null>(null);
  const [appToken, setAppToken] = useState("");
  const [scanResult, setScanResult] = useState<{ success: boolean; error?: string } | null>(null);
  const [tab, setTab] = useState<"scan" | "sessions" | "audit">("scan");

  const handlePassportScan = () => {
    const { session } = kioskVerifyPassport({
      kioskId: KIOSK_ID,
      passportHash,
      countryCode,
      biometricHash: biometricPass ? "sha256:bio_ok" : undefined,
    });
    setCurrentSession(session);
    setScanResult(null);
    setAppToken("");
  };

  const handleAppQRScan = () => {
    if (!currentSession) return;
    const result = kioskScanApp({
      sessionId: currentSession.id,
      appToken: appToken.trim(),
    });
    setScanResult(result);
    if (result.success) {
      setCurrentSession({ ...currentSession, status: "verified" });
    }
  };

  const sessions = getAllSessions();
  const auditEvents = getAuditLog();

  return (
    <div className="px-4 py-6 space-y-6 max-w-lg mx-auto">
      <AnimatedPage>
        <div className="flex items-center gap-2 mb-1">
          <Monitor className="w-5 h-5 text-accent" />
          <h1 className="text-xl font-bold text-foreground">Kiosk Simulator</h1>
        </div>
        <p className="text-xs text-muted-foreground">
          Dev tool — simulates GlobeID kiosk hardware for QA testing
        </p>
      </AnimatedPage>

      {/* Tabs */}
      <div className="flex gap-1 p-1 rounded-xl glass">
        {(["scan", "sessions", "audit"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              "flex-1 py-2 rounded-lg text-xs font-medium transition-colors min-h-[44px]",
              tab === t ? "bg-accent text-accent-foreground" : "text-muted-foreground"
            )}
          >
            {t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      {tab === "scan" && (
        <div className="space-y-4">
          {/* Step 1: Passport Scan */}
          <AnimatedPage staggerIndex={0}>
            <GlassCard>
              <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                <ScanLine className="w-4 h-4 text-accent" />
                1. Scan Passport
              </h3>

              <div className="space-y-3">
                <div>
                  <label className="text-xs text-muted-foreground block mb-1">Country</label>
                  <div className="flex flex-wrap gap-1.5">
                    {Object.values(countryThemes).map((c) => (
                      <button
                        key={c.code}
                        onClick={() => setCountryCode(c.code)}
                        className={cn(
                          "px-2.5 py-1.5 rounded-lg text-xs font-medium transition-colors min-h-[36px]",
                          countryCode === c.code
                            ? "bg-accent text-accent-foreground"
                            : "glass text-muted-foreground"
                        )}
                      >
                        {c.flag} {c.code}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-xs text-muted-foreground block mb-1">Passport Hash</label>
                  <input
                    type="text"
                    value={passportHash}
                    onChange={(e) => setPassportHash(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg glass text-xs text-foreground font-mono bg-transparent border border-border focus:border-accent outline-none"
                  />
                </div>

                <label className="flex items-center gap-2 text-xs text-muted-foreground">
                  <input
                    type="checkbox"
                    checked={biometricPass}
                    onChange={(e) => setBiometricPass(e.target.checked)}
                    className="rounded"
                  />
                  Biometric verification passes
                </label>

                <button
                  onClick={handlePassportScan}
                  className="w-full py-2.5 rounded-xl bg-gradient-to-r from-neon-indigo to-neon-cyan text-primary-foreground text-sm font-medium active:scale-95 transition-transform min-h-[44px]"
                >
                  Scan Passport
                </button>
              </div>
            </GlassCard>
          </AnimatedPage>

          {/* Session Info */}
          {currentSession && (
            <AnimatedPage staggerIndex={1}>
              <GlassCard>
                <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                  <Wifi className="w-4 h-4 text-accent" />
                  Session Active
                </h3>
                <div className="space-y-1.5 text-xs">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">ID</span>
                    <span className="font-mono text-foreground">{currentSession.id.slice(0, 12)}…</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Status</span>
                    <span className={statusColors[currentSession.status]}>{currentSession.status}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Country</span>
                    <span className="text-foreground">{currentSession.countryCode}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Short Code</span>
                    <span className="font-mono text-foreground">{currentSession.shortCode}</span>
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          )}

          {/* Step 2: Scan App QR */}
          {currentSession && currentSession.status === "pending" && (
            <AnimatedPage staggerIndex={2}>
              <GlassCard>
                <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                  <ScanLine className="w-4 h-4 text-accent" />
                  2. Scan App QR
                </h3>
                <p className="text-xs text-muted-foreground mb-3">
                  Paste the app's QR token (JWT string) from the Identity screen
                </p>

                <textarea
                  value={appToken}
                  onChange={(e) => setAppToken(e.target.value)}
                  placeholder="Paste app_qr_token here…"
                  rows={3}
                  className="w-full px-3 py-2 rounded-lg glass text-xs text-foreground font-mono bg-transparent border border-border focus:border-accent outline-none resize-none mb-3"
                />

                <button
                  onClick={handleAppQRScan}
                  disabled={!appToken.trim()}
                  className="w-full py-2.5 rounded-xl bg-accent text-accent-foreground text-sm font-medium active:scale-95 transition-transform disabled:opacity-40 min-h-[44px]"
                >
                  Verify App QR
                </button>

                {scanResult && (
                  <div className={cn(
                    "mt-3 p-3 rounded-lg flex items-center gap-2 text-xs",
                    scanResult.success ? "bg-accent/10 text-accent" : "bg-destructive/10 text-destructive"
                  )}>
                    {scanResult.success ? <CheckCircle2 className="w-4 h-4" /> : <XCircle className="w-4 h-4" />}
                    {scanResult.success ? "Identity verified successfully!" : scanResult.error}
                  </div>
                )}
              </GlassCard>
            </AnimatedPage>
          )}
        </div>
      )}

      {tab === "sessions" && (
        <div className="space-y-2">
          {sessions.length === 0 && (
            <p className="text-xs text-muted-foreground text-center py-8">No sessions yet</p>
          )}
          {sessions.map((s) => (
            <GlassCard key={s.id} className="text-xs">
              <div className="flex items-center justify-between mb-1">
                <span className="font-mono text-foreground">{s.id.slice(0, 8)}</span>
                <span className={statusColors[s.status] ?? "text-muted-foreground"}>{s.status}</span>
              </div>
              <div className="flex gap-3 text-muted-foreground">
                <span>{s.countryCode}</span>
                <span>{new Date(s.createdAt).toLocaleTimeString()}</span>
              </div>
            </GlassCard>
          ))}
        </div>
      )}

      {tab === "audit" && (
        <div className="space-y-2">
          {auditEvents.length === 0 && (
            <p className="text-xs text-muted-foreground text-center py-8">No events yet</p>
          )}
          {[...auditEvents].reverse().slice(0, 50).map((evt) => (
            <GlassCard key={evt.id} className="text-xs">
              <div className="flex items-center justify-between mb-1">
                <span className="text-foreground font-medium">{evt.type}</span>
                <span className="text-muted-foreground">{evt.source}</span>
              </div>
              <p className="text-muted-foreground font-mono text-[10px] truncate">
                {JSON.stringify(evt.payload)}
              </p>
            </GlassCard>
          ))}
        </div>
      )}
    </div>
  );
};

export default KioskSimulator;
