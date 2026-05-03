import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "motion/react";
import { Shield, Link2, BookOpen } from "lucide-react";
import { Surface, Button, Tabs, Text, spring, duration, ease } from "@/components/ui/v2";
import { useUserStore } from "@/store/userStore";
import { useVerificationSession } from "@/hooks/useVerificationSession";

import DigitalPassport from "@/components/identity/DigitalPassport";
import QRDisplay from "@/components/identity/QRDisplay";
import SessionStatus from "@/components/identity/SessionStatus";
import WelcomeOverlay from "@/components/identity/WelcomeOverlay";
import CredentialCard from "@/components/identity/CredentialCard";
import SecurityStatus from "@/components/identity/SecurityStatus";
import IdentityScoreCard from "@/components/identity/IdentityScoreCard";
import DocExpiryChip from "@/components/identity/DocExpiryChip";
import IdentityTimeline from "@/components/identity/IdentityTimeline";
import IdentityMapLayer from "@/components/map/IdentityMapLayer";
import PassDetail from "@/components/wallet/PassDetail";
import type { TravelDocument } from "@/store/userStore";

type IdentityTab = "documents" | "timeline" | "security";

/**
 * Identity — Phase 7 PR-δ.
 *
 * Visual reset against the v2 design system. Functional surface
 * preserved verbatim:
 *  - Verification session hook (`useVerificationSession`) drives the
 *    inline kiosk-link sheet exactly as before.
 *  - 3 tabs (Documents / Timeline / Security) — same state machine.
 *  - Sub-components (`DigitalPassport`, `IdentityScoreCard`,
 *    `IdentityTimeline`, `IdentityMapLayer`, `CredentialCard`,
 *    `SecurityStatus`, `WelcomeOverlay`) preserved unchanged.
 *
 * Visual changes:
 *  - Header CTAs (Link / Stamps) → `Button variant="secondary|primary"`.
 *  - Tab toggle → `Tabs.Root` segmented (shared-layout indicator).
 *  - Inline kiosk sheet → `Surface variant="elevated"` (replaces
 *    `glass rounded-xl`).
 *  - Tab transitions → motion@12 `AnimatePresence` with the v2 motion
 *    tokens (default spring + standard ease).
 */
const Identity: React.FC = () => {
  const navigate = useNavigate();
  const { documents } = useUserStore();
  const [showLinkSection, setShowLinkSection] = useState(false);
  const [showWelcome, setShowWelcome] = useState(false);
  const [activeTab, setActiveTab] = useState<IdentityTab>("documents");
  const [activeDocument, setActiveDocument] = useState<TravelDocument | null>(null);

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
    if (status === "verified" && countryCode) setShowWelcome(true);
  }, [status, countryCode]);

  const handleWelcomeComplete = () => {
    setShowWelcome(false);
    setShowLinkSection(false);
    if (receipt) navigate("/receipt", { state: { receipt } });
    reset();
  };

  return (
    <div className="px-4 py-6 space-y-5 pb-24">
      {showWelcome && countryCode ? (
        <WelcomeOverlay
          countryCode={countryCode}
          onComplete={handleWelcomeComplete}
        />
      ) : null}
      <AnimatePresence>
        {activeDocument ? (
          <PassDetail
            key={activeDocument.id}
            doc={activeDocument}
            onClose={() => setActiveDocument(null)}
          />
        ) : null}
      </AnimatePresence>

      {/* Header */}
      <header className="flex items-center justify-between">
        <div>
          <Text
            as="h1"
            variant="title-2"
            tone="primary"
            className="flex items-center gap-2"
          >
            <Shield className="w-5 h-5 text-state-accent" strokeWidth={1.8} />
            Identity Vault
          </Text>
          <Text variant="caption-1" tone="tertiary" className="mt-1">
            {documents.length} credential{documents.length === 1 ? "" : "s"} secured
          </Text>
        </div>
        <div className="flex gap-2">
          <Button
            variant="secondary"
            size="sm"
            leading={<Link2 />}
            onClick={handleStartLink}
          >
            Link
          </Button>
          <Button
            variant="primary"
            size="sm"
            leading={<BookOpen />}
            onClick={() => navigate("/passport-book")}
          >
            Stamps
          </Button>
        </div>
      </header>

      {/* Digital Passport Card */}
      <DigitalPassport />

      {/* Doc expiry chip (E 60) — only renders when an active doc
          will expire within the next year. */}
      <DocExpiryChip />

      {/* Identity Score */}
      <IdentityScoreCard />

      {/* Link at Kiosk inline sheet */}
      <AnimatePresence initial={false}>
        {showLinkSection ? (
          <motion.div
            key="kiosk-link"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: duration.page, ease: ease.standard }}
          >
            <Surface
              variant="elevated"
              radius="surface"
              className="flex flex-col items-center gap-4 px-6 py-7"
            >
              <Text as="h3" variant="title-3" tone="primary">
                Link at Kiosk
              </Text>
              <Text
                variant="caption-1"
                tone="tertiary"
                align="center"
                className="px-4"
              >
                Show this QR at any GlobeID kiosk
              </Text>
              <SessionStatus
                status={status}
                sessionId={sessionId ?? undefined}
              />
              <QRDisplay
                data={qrData || "placeholder"}
                shortCode={shortCode || "------"}
                ttlSeconds={30}
                expiresAt={expiresAt}
                status={status}
                onRefresh={generateQR}
              />
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setShowLinkSection(false);
                  reset();
                }}
              >
                Cancel
              </Button>
            </Surface>
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Tabs */}
      <Tabs
        value={activeTab}
        onValueChange={(next) => setActiveTab(next as IdentityTab)}
      >
        <Tabs.List variant="segmented" className="w-full">
          <Tabs.Trigger value="documents" className="flex-1">
            Documents
          </Tabs.Trigger>
          <Tabs.Trigger value="timeline" className="flex-1">
            Timeline
          </Tabs.Trigger>
          <Tabs.Trigger value="security" className="flex-1">
            Security
          </Tabs.Trigger>
        </Tabs.List>

        <Tabs.Content value="documents" className="mt-5">
          <motion.div
            key="docs"
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring.default}
            className="space-y-2"
          >
            {documents.map((doc, i) => (
              <CredentialCard
                key={doc.id}
                doc={doc}
                index={i}
                onTap={() => setActiveDocument(doc)}
              />
            ))}
          </motion.div>
        </Tabs.Content>

        <Tabs.Content value="timeline" className="mt-5">
          <motion.div
            key="timeline"
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring.default}
            className="space-y-5"
          >
            <IdentityTimeline />
            <IdentityMapLayer />
          </motion.div>
        </Tabs.Content>

        <Tabs.Content value="security" className="mt-5">
          <motion.div
            key="security"
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring.default}
          >
            <SecurityStatus />
          </motion.div>
        </Tabs.Content>
      </Tabs>
    </div>
  );
};

export default Identity;
