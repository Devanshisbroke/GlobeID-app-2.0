import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
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
} from "lucide-react";
import {
  Surface,
  Text,
  Toggle,
  spring,
  stagger as v2Stagger,
} from "@/components/ui/v2";
import { demoUser } from "@/lib/demoData";
import { cn } from "@/lib/utils";

interface SettingItem {
  icon: React.ElementType;
  label: string;
  description: string;
  tone?: "neutral" | "brand" | "accent" | "critical";
  route?: string;
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
const Profile: React.FC = () => {
  const navigate = useNavigate();
  const [demoMode, setDemoMode] = useState(true);

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
                    onClick={() =>
                      item.route ? navigate(item.route) : undefined
                    }
                    className={cn(
                      "flex items-center gap-3 px-4 py-3.5",
                      item.route && "cursor-pointer",
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
