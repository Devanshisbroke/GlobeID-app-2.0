import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoDocuments } from "@/lib/demoData";
import { Shield, ShieldCheck, Clock, AlertTriangle, ChevronDown, ScanLine, Link2 } from "lucide-react";
import { cn } from "@/lib/utils";
import QRDisplay from "@/components/identity/QRDisplay";
import SessionStatus from "@/components/identity/SessionStatus";
import WelcomeOverlay from "@/components/identity/WelcomeOverlay";
import { useVerificationSession } from "@/hooks/useVerificationSession";

const statusConfig = {
  verified: { icon: ShieldCheck, color: "text-accent", label: "Verified" },
  pending: { icon: Clock, color: "text-yellow-400", label: "Pending" },
  expired: { icon: AlertTriangle, color: "text-destructive", label: "Expired" },
};

const Identity: React.FC = () => {
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
    generateQR,
    reset,
  } = useVerificationSession();

  const handleStartLink = () => {
    setShowLinkSection(true);
    generateQR();
  };

  // Watch for verified status to trigger welcome animation
  React.useEffect(() => {
    if (status === "verified" && countryCode) {
      setShowWelcome(true);
    }
  }, [status, countryCode]);

  const handleWelcomeComplete = () => {
    setShowWelcome(false);
    setShowLinkSection(false);
    reset();
  };

  return (
    <div className="px-4 py-6 space-y-6">
      {/* Welcome overlay */}
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
              {demoDocuments.length} documents secured
            </p>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleStartLink}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl glass text-accent text-xs font-medium active:scale-95 transition-transform min-h-[44px]"
              aria-label="Link at kiosk"
            >
              <Link2 className="w-4 h-4" />
              Link
            </button>
            <button
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-gradient-to-r from-neon-indigo to-neon-cyan text-primary-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px]"
              aria-label="Scan new document"
            >
              <ScanLine className="w-4 h-4" />
              Scan
            </button>
          </div>
        </div>
      </AnimatedPage>

      {/* Link at Kiosk section */}
      {showLinkSection && (
        <AnimatedPage>
          <GlassCard neonBorder className="flex flex-col items-center py-6 gap-4">
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
        {demoDocuments.map((doc, i) => {
          const Status = statusConfig[doc.status];
          const StatusIcon = Status.icon;
          const isExpanded = expandedId === doc.id;

          return (
            <AnimatedPage key={doc.id} staggerIndex={i}>
              <GlassCard
                className="cursor-pointer active:scale-[0.98] transition-transform"
                onClick={() => setExpandedId(isExpanded ? null : doc.id)}
              >
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{doc.countryFlag}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-foreground">{doc.label}</p>
                    <p className="text-xs text-muted-foreground">{doc.number}</p>
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
                  <div className="mt-3 pt-3 border-t border-border space-y-2 animate-fade-in">
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
