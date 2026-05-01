import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { useTranslation } from "react-i18next";
import {
  ShieldCheck,
  Landmark,
  Settings,
  Code2,
  ChevronRight,
  Globe,
  Bell,
  Languages,
  Monitor,
  ScrollText,
  RotateCcw,
  Camera,
  Mic,
  MapPin,
  FileText,
  BarChart3,
  MessageSquare,
} from "lucide-react";
import {
  Surface,
  Text,
  Toggle,
  spring,
  stagger as v2Stagger,
} from "@/components/ui/v2";
import { Button } from "@/components/ui/button";
import { demoUser } from "@/lib/demoData";
import { cn } from "@/lib/utils";
import { usePermissions, type PermissionState } from "@/hooks/usePermissions";
import { LANG_LABELS, SUPPORTED_LANGS, setLanguage, type SupportedLang } from "@/i18n";
import { resetOnboarding } from "@/lib/onboarding";
import { haptics } from "@/utils/haptics";
import { toast } from "sonner";

type SettingAction = "reset-onboarding" | "reset-demo-data";

interface SettingItem {
  icon: React.ElementType;
  label: string;
  description: string;
  tone?: "neutral" | "brand" | "accent" | "critical";
  route?: string;
  action?: SettingAction;
}

const settingSections: { title: string; items: SettingItem[] }[] = [
  {
    title: "Security",
    items: [
      {
        icon: ShieldCheck,
        label: "Security Center",
        description: "Biometrics, 2FA, recovery keys",
        tone: "accent",
      },
      {
        icon: Landmark,
        label: "Bank & KYC",
        description: "Connected accounts & verification",
        tone: "accent",
      },
    ],
  },
  {
    title: "Preferences",
    items: [
      {
        icon: Globe,
        label: "Currency & Region",
        description: "USD — United States",
        tone: "brand",
      },
      {
        icon: Languages,
        label: "Language",
        description: "English",
        tone: "brand",
      },
      {
        icon: Bell,
        label: "Notifications",
        description: "Push, email, in-app",
        tone: "accent",
      },
    ],
  },
  {
    title: "Developer",
    items: [
      {
        icon: Monitor,
        label: "Kiosk Simulator",
        description: "Test identity verification flow",
        tone: "brand",
        route: "/kiosk-sim",
      },
      {
        icon: ScrollText,
        label: "Audit Logs",
        description: "View session & verification events",
        tone: "neutral",
        route: "/kiosk-sim",
      },
      {
        icon: Code2,
        label: "Developer Tools",
        description: "Demo mode, debug overlays",
        tone: "neutral",
      },
      {
        icon: RotateCcw,
        label: "Reset Demo Data",
        description: "Clear all sessions & receipts",
        tone: "critical",
        action: "reset-demo-data",
      },
      {
        icon: RotateCcw,
        label: "Replay onboarding",
        description: "Walk through first-run again",
        tone: "neutral",
        action: "reset-onboarding",
      },
    ],
  },
];

const containerVariants = {
  initial: {},
  animate: { transition: { staggerChildren: v2Stagger.default } },
};

const itemVariants = {
  initial: { opacity: 0, y: 6 },
  animate: { opacity: 1, y: 0, transition: spring.default },
};

const TONE_HALO_CLASS: Record<
  NonNullable<SettingItem["tone"]>,
  string
> = {
  neutral: "bg-surface-overlay text-ink-tertiary",
  brand: "bg-brand-soft text-brand",
  accent: "bg-state-accent-soft text-state-accent",
  critical: "bg-state-critical-soft text-state-critical",
};

/**
 * Profile — Phase 7 PR-ε.
 *
 * Visual reset against the v2 design system. Functional surface
 * preserved verbatim:
 *  - Same `settingSections` data with the same routes.
 *  - Same demo-mode toggle state (still local).
 *
 * Visual changes:
 *  - GlassCard hero → `Surface variant="elevated" radius="sheet"` with a
 *    soft brand-soft icon halo (replaces the gradient-brand square).
 *  - Section headings → `Text variant="caption-1"` uppercase eyebrow.
 *  - Setting rows → `Surface variant="plain"` row with tone-aware halo.
 *  - Demo-mode switch → v2 `Toggle` primitive (Radix Switch under the
 *    hood).
 *  - `AnimatedPage` per-row stagger → motion@12 stagger via v2 tokens.
 */
const PERM_TONE: Record<PermissionState, string> = {
  granted: "text-emerald-400",
  denied: "text-rose-400",
  prompt: "text-amber-300",
  unsupported: "text-ink-tertiary",
};

const Profile: React.FC = () => {
  const navigate = useNavigate();
  const { i18n, t } = useTranslation();
  const [demoMode, setDemoMode] = useState(true);
  const { permissions, request } = usePermissions();
  const currentLang = (i18n.language?.slice(0, 2) as SupportedLang) ?? "en";

  const handleItemClick = (item: SettingItem) => {
    if (item.action === "reset-onboarding") {
      haptics.medium();
      resetOnboarding();
      toast.success("Onboarding reset");
      navigate("/onboarding");
      return;
    }
    if (item.action === "reset-demo-data") {
      haptics.medium();
      try {
        // Best-effort: drop persisted Zustand stores so the next boot
        // re-seeds. Keys are namespaced by store name.
        for (const key of Object.keys(localStorage)) {
          if (key.startsWith("globeid:")) localStorage.removeItem(key);
        }
        toast.success("Demo data cleared — relaunching");
        setTimeout(() => window.location.assign("/"), 400);
      } catch {
        toast.error("Could not reset demo data");
      }
      return;
    }
    if (item.route) navigate(item.route);
  };

  return (
    <motion.div
      variants={containerVariants}
      initial="initial"
      animate="animate"
      className="px-4 py-6 space-y-6"
    >
      {/* Identity hero */}
      <motion.div variants={itemVariants}>
        <Surface
          variant="elevated"
          radius="sheet"
          className="flex items-center gap-4 px-5 py-5"
        >
          <span
            aria-hidden
            className="flex h-12 w-12 shrink-0 items-center justify-center rounded-p7-input bg-brand-soft"
          >
            <ShieldCheck className="w-5 h-5 text-brand" strokeWidth={2} />
          </span>
          <div className="flex-1 min-w-0">
            <Text as="h2" variant="title-3" tone="primary" truncate>
              {demoUser.name}
            </Text>
            <Text variant="caption-1" tone="tertiary" truncate>
              {demoUser.email}
            </Text>
            <Text variant="caption-1" tone="brand" className="mt-0.5 font-semibold">
              {demoUser.identityLevel} · Member since {demoUser.memberSince}
            </Text>
          </div>
          <Settings
            className="w-5 h-5 text-ink-tertiary shrink-0"
            strokeWidth={1.8}
          />
        </Surface>
      </motion.div>

      {/* Settings sections */}
      {settingSections.map((section) => (
        <motion.section
          key={section.title}
          variants={itemVariants}
          className="space-y-2"
        >
          <Text
            as="h3"
            variant="caption-1"
            tone="tertiary"
            className="px-1 uppercase tracking-[0.18em]"
          >
            {section.title}
          </Text>
          <motion.div
            variants={containerVariants}
            initial="initial"
            animate="animate"
            className="space-y-2"
          >
            {section.items.map((item) => {
              const Icon = item.icon;
              const tone = item.tone ?? "neutral";
              return (
                <motion.div key={item.label} variants={itemVariants}>
                  <Surface
                    variant="plain"
                    radius="surface"
                    onClick={() => handleItemClick(item)}
                    className={cn(
                      "flex items-center gap-3 px-4 py-3.5",
                      (item.route || item.action) && "cursor-pointer",
                    )}
                  >
                    <span
                      aria-hidden
                      className={cn(
                        "flex h-9 w-9 shrink-0 items-center justify-center rounded-p7-input",
                        TONE_HALO_CLASS[tone],
                      )}
                    >
                      <Icon className="w-4 h-4" strokeWidth={1.8} />
                    </span>
                    <div className="flex-1 min-w-0">
                      <Text variant="body-em" tone="primary">
                        {item.label}
                      </Text>
                      <Text variant="caption-1" tone="tertiary">
                        {item.description}
                      </Text>
                    </div>
                    {item.route ? (
                      <ChevronRight
                        className="w-4 h-4 text-ink-tertiary shrink-0"
                        strokeWidth={1.8}
                      />
                    ) : null}
                  </Surface>
                </motion.div>
              );
            })}
          </motion.div>
        </motion.section>
      ))}

      {/* Slice-C — language toggle */}
      <motion.section variants={itemVariants} className="space-y-2">
        <Text
          as="h3"
          variant="caption-1"
          tone="tertiary"
          className="px-1 uppercase tracking-[0.18em]"
        >
          {t("profile.languageLabel")}
        </Text>
        <Surface variant="plain" radius="surface" className="px-4 py-3 flex gap-2 flex-wrap">
          {SUPPORTED_LANGS.map((lng) => (
            <Button
              key={lng}
              size="sm"
              variant={currentLang === lng ? "default" : "ghost"}
              onClick={() => setLanguage(lng)}
              className="text-xs"
            >
              {LANG_LABELS[lng]}
            </Button>
          ))}
        </Surface>
      </motion.section>

      {/* Slice-CDE — permissions surface */}
      <motion.section variants={itemVariants} className="space-y-2">
        <Text
          as="h3"
          variant="caption-1"
          tone="tertiary"
          className="px-1 uppercase tracking-[0.18em]"
        >
          {t("profile.permissionsHeading")}
        </Text>
        <div className="space-y-2">
          {(
            [
              { kind: "camera", icon: Camera, label: t("profile.cameraNeeded") },
              { kind: "microphone", icon: Mic, label: t("profile.micNeeded") },
              { kind: "geolocation", icon: MapPin, label: "Location for smart recommendations" },
              { kind: "notifications", icon: Bell, label: "Boarding & delay alerts" },
            ] as const
          ).map(({ kind, icon: Icon, label }) => {
            const state = permissions[kind];
            return (
              <Surface
                key={kind}
                variant="plain"
                radius="surface"
                className="flex items-center gap-3 px-4 py-3"
              >
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-p7-input bg-surface-overlay">
                  <Icon className="w-4 h-4 text-ink-primary" strokeWidth={1.8} />
                </span>
                <div className="flex-1 min-w-0">
                  <Text variant="body-em" tone="primary" className="capitalize">
                    {kind}
                  </Text>
                  <Text variant="caption-1" tone="tertiary">
                    {label}
                  </Text>
                </div>
                <div className="shrink-0 flex items-center gap-2">
                  <span className={cn("text-[10px] uppercase tracking-wider", PERM_TONE[state])}>
                    {state}
                  </span>
                  {state !== "granted" && state !== "unsupported" && (
                    <Button size="sm" variant="ghost" onClick={() => request(kind)}>
                      Grant
                    </Button>
                  )}
                </div>
              </Surface>
            );
          })}
        </div>
      </motion.section>

      {/* Slice-CDE — quick links */}
      <motion.section variants={itemVariants} className="space-y-2">
        <Text
          as="h3"
          variant="caption-1"
          tone="tertiary"
          className="px-1 uppercase tracking-[0.18em]"
        >
          Explore
        </Text>
        <div className="grid grid-cols-3 gap-2">
          {[
            { icon: FileText, label: t("vault.title"), route: "/vault" },
            { icon: BarChart3, label: "Analytics", route: "/analytics" },
            { icon: MessageSquare, label: t("nav.social"), route: "/feed" },
          ].map(({ icon: Icon, label, route }) => (
            <Surface
              key={route}
              variant="plain"
              radius="surface"
              onClick={() => navigate(route)}
              className="flex flex-col items-center gap-2 px-3 py-4 cursor-pointer"
            >
              <Icon className="w-5 h-5 text-brand" strokeWidth={1.8} />
              <Text variant="caption-1" tone="primary" className="text-center">
                {label}
              </Text>
            </Surface>
          ))}
        </div>
      </motion.section>

      {/* Demo-mode toggle */}
      <motion.div variants={itemVariants}>
        <Surface
          variant="plain"
          radius="surface"
          className="flex items-center justify-between px-4 py-3.5"
        >
          <div>
            <Text variant="body-em" tone="primary">
              Demo Mode
            </Text>
            <Text variant="caption-1" tone="tertiary">
              Uses sample data for all flows
            </Text>
          </div>
          <Toggle
            checked={demoMode}
            onCheckedChange={setDemoMode}
            aria-label="Toggle demo mode"
          />
        </Surface>
      </motion.div>

      <Text
        variant="caption-2"
        tone="tertiary"
        className="text-center pb-4 tracking-[0.12em] opacity-70"
      >
        GlobeID v4.0.0 · Premium · Phase 4
      </Text>
    </motion.div>
  );
};

export default Profile;
