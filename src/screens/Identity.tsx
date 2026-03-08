import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useUserStore } from "@/store/userStore";
import { Shield, ShieldCheck, Clock, AlertTriangle, ChevronDown, ScanLine, Link2, Globe, User, Fingerprint } from "lucide-react";
import { cn } from "@/lib/utils";
import QRDisplay from "@/components/identity/QRDisplay";
import SessionStatus from "@/components/identity/SessionStatus";
import WelcomeOverlay from "@/components/identity/WelcomeOverlay";
import { useVerificationSession } from "@/hooks/useVerificationSession";

const Identity: React.FC = () => {
  const navigate = useNavigate();
  const { profile, documents } = useUserStore();
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showLinkSection, setShowLinkSection] = useState(false);
  const [showWelcome, setShowWelcome] = useState(false);

  const {
    status,
    qrData,
    shortCode,
    expiresAt,
    sessionId,
    countryCode,
    receipt,
    generateQR,
    reset,
  } = useVerificationSession();

  const handleStartLink = () => {
    setShowLinkSection(true);
    generateQR();
  };

  React.useEffect(() => {
    if (status === "verified" && countryCode) {
      setShowWelcome(true);
    }
  }, [status, countryCode]);

  const handleWelcomeComplete = () => {
    setShowWelcome(false);
    setShowLinkSection(false);
    if (receipt) {
      navigate("/receipt", { state: { receipt } });
    }
    reset();
  };

  const docGradients = ["bg-gradient-ocean", "bg-gradient-cosmic", "bg-gradient-forest", "bg-gradient-sunset", "bg-gradient-aurora"];

  // Map travel documents to the identity vault display
  const vaultDocuments = documents.filter(d => d.type === "passport" || d.type === "visa");

  return (
    <div className="px-4 py-6 space-y-5">
      {showWelcome && countryCode && (
        <WelcomeOverlay countryCode={countryCode} onComplete={handleWelcomeComplete} />
      )}

      {/* Header */}
      <AnimatedPage>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-foreground flex items-center gap-2">
              <Shield className="w-5 h-5 text-accent" />
              Identity Vault
            </h1>
            <p className="text-xs text-muted-foreground mt-1">
              {vaultDocuments.length} documents secured
            </p>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleStartLink}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl glass text-accent text-xs font-medium active:scale-95 transition-transform min-h-[44px] touch-bounce"
              aria-label="Link at kiosk"
            >
              <Link2 className="w-4 h-4" />
              Link
            </button>
            <button
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-gradient-cosmic text-primary-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px] shadow-glow-sm btn-ripple"
              aria-label="Scan new document"
            >
              <ScanLine className="w-4 h-4" />
              Scan
            </button>
          </div>
        </div>
      </AnimatedPage>

      {/* Digital Passport Card */}
      <AnimatedPage staggerIndex={0}>
        <GlassCard neonBorder variant="premium" className="relative overflow-hidden" depth="lg">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-gradient-ocean blur-3xl opacity-10 pointer-events-none" />
          <div className="flex items-start gap-4">
            {/* Avatar placeholder */}
            <div className="w-20 h-24 rounded-xl bg-secondary/60 border border-border/30 flex items-center justify-center shrink-0 overflow-hidden">
              <User className="w-8 h-8 text-muted-foreground" strokeWidth={1.5} />
            </div>
            <div className="flex-1 min-w-0 space-y-1.5">
              <div className="flex items-center gap-2">
                <p className="text-base font-bold text-foreground">{profile.name}</p>
                {profile.verifiedStatus === "verified" && (
                  <ShieldCheck className="w-4 h-4 text-accent shrink-0" />
                )}
              </div>
              <div className="space-y-1 text-xs">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Nationality</span>
                  <span className="text-foreground font-medium">{profile.nationalityFlag} {profile.nationality}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Passport</span>
                  <span className="text-foreground font-mono font-medium">{profile.passportNumber}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Score</span>
                  <span className="text-accent font-bold">{profile.identityScore}/100</span>
                </div>
              </div>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-border/20 flex items-center justify-between">
            <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
              <Fingerprint className="w-3.5 h-3.5" />
              Biometric Verified · Member since {profile.memberSince}
            </div>
            <span className="text-[10px] px-2 py-0.5 rounded-full font-semibold bg-accent/15 text-accent uppercase tracking-wider">
              {profile.verifiedStatus}
            </span>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Link at Kiosk section */}
      {showLinkSection && (
        <AnimatedPage>
          <GlassCard neonBorder variant="premium" className="flex flex-col items-center py-6 gap-4">
            <h3 className="text-sm font-semibold text-foreground">Link at Kiosk</h3>
            <p className="text-xs text-muted-foreground text-center px-4">
              Show this QR code at any GlobeID kiosk to verify your identity
            </p>
            <SessionStatus status={status} sessionId={sessionId ?? undefined} />
            <QRDisplay
              data={qrData || "placeholder"}
              shortCode={shortCode || "------"}
              ttlSeconds={30}
              expiresAt={expiresAt}
              status={status}
              onRefresh={generateQR}
            />
            <button
              onClick={() => { setShowLinkSection(false); reset(); }}
              className="text-xs text-muted-foreground underline mt-2"
            >
              Cancel
            </button>
          </GlassCard>
        </AnimatedPage>
      )}

      {/* Documents */}
      <div className="space-y-3">
        <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Documents</h3>
        {vaultDocuments.map((doc, i) => {
          const isExpanded = expandedId === doc.id;
          const statusConfig = {
            active: { icon: ShieldCheck, color: "text-accent", label: "Verified" },
            pending: { icon: Clock, color: "text-primary", label: "Pending" },
            expired: { icon: AlertTriangle, color: "text-destructive", label: "Expired" },
          };
          const Status = statusConfig[doc.status];
          const StatusIcon = Status.icon;

          return (
            <AnimatedPage key={doc.id} staggerIndex={i + 1}>
              <GlassCard
                className="cursor-pointer touch-bounce"
                onClick={() => setExpandedId(isExpanded ? null : doc.id)}
              >
                <div className="flex items-center gap-3">
                  <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm", docGradients[i % docGradients.length])}>
                    <Globe className="w-4.5 h-4.5 text-primary-foreground" strokeWidth={1.8} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-foreground">{doc.label}</p>
                    <p className="text-xs text-muted-foreground">{doc.countryFlag} {doc.country} · {doc.number}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusIcon className={cn("w-4 h-4", Status.color)} />
                    <ChevronDown
                      className={cn(
                        "w-4 h-4 text-muted-foreground transition-transform duration-[var(--motion-small)]",
                        isExpanded && "rotate-180"
                      )}
                    />
                  </div>
                </div>

                {isExpanded && (
                  <div className="mt-3 pt-3 border-t border-border/30 space-y-2 animate-fade-in">
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Country</span>
                      <span className="text-foreground">{doc.country}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Issued</span>
                      <span className="text-foreground">{doc.issueDate}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Expires</span>
                      <span className="text-foreground">{doc.expiryDate}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Status</span>
                      <span className={Status.color}>{Status.label}</span>
                    </div>
                  </div>
                )}
              </GlassCard>
            </AnimatedPage>
          );
        })}
      </div>
    </div>
  );
};

export default Identity;
