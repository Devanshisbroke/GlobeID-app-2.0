import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Shield, ScanLine, Link2, BookOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useUserStore } from "@/store/userStore";
import { useVerificationSession } from "@/hooks/useVerificationSession";
import { cinematicEase } from "@/cinematic/motionEngine";

import DigitalPassport from "@/components/identity/DigitalPassport";
import QRDisplay from "@/components/identity/QRDisplay";
import SessionStatus from "@/components/identity/SessionStatus";
import WelcomeOverlay from "@/components/identity/WelcomeOverlay";
import CredentialCard from "@/components/identity/CredentialCard";
import SecurityStatus from "@/components/identity/SecurityStatus";
import IdentityScoreCard from "@/components/identity/IdentityScoreCard";
import IdentityTimeline from "@/components/identity/IdentityTimeline";
import IdentityMapLayer from "@/components/map/IdentityMapLayer";

const Identity: React.FC = () => {
  const navigate = useNavigate();
  const { profile, documents } = useUserStore();
  const [showLinkSection, setShowLinkSection] = useState(false);
  const [showWelcome, setShowWelcome] = useState(false);
  const [activeTab, setActiveTab] = useState<"documents" | "timeline" | "security">("documents");

  const { status, qrData, shortCode, expiresAt, sessionId, countryCode, receipt, generateQR, reset } = useVerificationSession();

  const handleStartLink = () => {
    setShowLinkSection(true);
    generateQR();
  };

  React.useEffect(() => {
    if (status === "verified" && countryCode) setShowWelcome(true);
  }, [status, countryCode]);

  const handleWelcomeComplete = () => {
    setShowWelcome(false);
    setShowLinkSection(false);
    if (receipt) navigate("/receipt", { state: { receipt } });
    reset();
  };

  const tabs = [
    { id: "documents" as const, label: "Documents" },
    { id: "timeline" as const, label: "Timeline" },
    { id: "security" as const, label: "Security" },
  ];

  return (
    <div className="px-4 py-6 space-y-5 pb-24">
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
            <p className="text-xs text-muted-foreground mt-1">{documents.length} credentials secured</p>
          </div>
          <div className="flex gap-2">
            <button onClick={handleStartLink} className="flex items-center gap-1.5 px-3 py-2 rounded-xl glass text-accent text-xs font-medium active:scale-95 transition-transform min-h-[44px]">
              <Link2 className="w-4 h-4" /> Link
            </button>
            <button onClick={() => navigate("/passport-book")} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-gradient-to-r from-[hsl(var(--primary))] to-[hsl(var(--ocean-aqua))] text-primary-foreground text-xs font-medium active:scale-95 transition-transform min-h-[44px] shadow-glow-sm">
              <BookOpen className="w-4 h-4" /> Stamps
            </button>
          </div>
        </div>
      </AnimatedPage>

      {/* Digital Passport Card */}
      <AnimatedPage staggerIndex={0}>
        <DigitalPassport />
      </AnimatedPage>

      {/* Identity Score */}
      <AnimatedPage staggerIndex={1}>
        <IdentityScoreCard />
      </AnimatedPage>

      {/* Link at Kiosk */}
      <AnimatePresence>
        {showLinkSection && (
          <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} exit={{ opacity: 0, height: 0 }} transition={{ duration: 0.4, ease: cinematicEase }}>
            <div className="glass rounded-xl flex flex-col items-center py-6 gap-4">
              <h3 className="text-sm font-semibold text-foreground">Link at Kiosk</h3>
              <p className="text-xs text-muted-foreground text-center px-4">Show this QR at any GlobeID kiosk</p>
              <SessionStatus status={status} sessionId={sessionId ?? undefined} />
              <QRDisplay data={qrData || "placeholder"} shortCode={shortCode || "------"} ttlSeconds={30} expiresAt={expiresAt} status={status} onRefresh={generateQR} />
              <button onClick={() => { setShowLinkSection(false); reset(); }} className="text-xs text-muted-foreground underline mt-2">Cancel</button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Tab navigation */}
      <div className="flex gap-1 p-1 rounded-xl bg-secondary/50">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              "flex-1 text-xs font-medium py-2 rounded-lg transition-all",
              activeTab === tab.id ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      <AnimatePresence mode="wait">
        {activeTab === "documents" && (
          <motion.div key="docs" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3, ease: cinematicEase }} className="space-y-2">
            {documents.map((doc, i) => (
              <CredentialCard key={doc.id} doc={doc} index={i} />
            ))}
          </motion.div>
        )}
        {activeTab === "timeline" && (
          <motion.div key="timeline" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3, ease: cinematicEase }} className="space-y-5">
            <IdentityTimeline />
            <IdentityMapLayer />
          </motion.div>
        )}
        {activeTab === "security" && (
          <motion.div key="security" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3, ease: cinematicEase }}>
            <SecurityStatus />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Identity;
