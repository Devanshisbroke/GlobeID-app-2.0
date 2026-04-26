import React, { useMemo, useState, useRef, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
  motion,
  useAnimation,
  type PanInfo,
} from "motion/react";
import {
  ChevronRight,
  TrendingUp,
  Plane,
  QrCode,
  Bell,
  RefreshCw,
  Users,
} from "lucide-react";
import {
  Surface,
  Pill,
  Text,
  spring,
  stagger as v2Stagger,
} from "@/components/ui/v2";
import { useUserStore, selectNextUpcoming, formatTripDate } from "@/store/userStore";
import { useWalletStore } from "@/store/walletStore";
import { useAlertsStore } from "@/store/alertsStore";
import { getAirport } from "@/lib/airports";
import { cn } from "@/lib/utils";
import { haptics } from "@/utils/haptics";
import { uiSound } from "@/cinematic/uiSound";

import ProfileCard from "@/components/dashboard/ProfileCard";
import TravelStats from "@/components/dashboard/TravelStats";
import UpcomingTrips from "@/components/dashboard/UpcomingTrips";
import QuickActions from "@/components/dashboard/QuickActions";
import Suggestions from "@/components/dashboard/Suggestions";
import TravelAlerts from "@/components/dashboard/TravelAlerts";
import TravelAssistant from "@/components/ai/TravelAssistant";

const PULL_THRESHOLD = 80;

const containerVariants = {
  initial: {},
  animate: { transition: { staggerChildren: v2Stagger.list } },
};

const itemVariants = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0, transition: spring.default },
};

/**
 * Home — Phase 7 PR-δ.
 *
 * Visual reset against the v2 design system. Functional surface
 * preserved verbatim:
 *  - Pull-to-refresh gesture + haptics + UI sound (the most loved
 *    micro-interaction in the legacy build) is intact.
 *  - All sub-components (`ProfileCard`, `TravelStats`, `TravelAlerts`,
 *    `UpcomingTrips`, `QuickActions`, `Suggestions`, `TravelAssistant`)
 *    are preserved unchanged.
 *  - All store reads (`useUserStore`, `useWalletStore`,
 *    `useAlertsStore`) preserved.
 *
 * Visual changes:
 *  - Removed the three ad-hoc fixed-position ambient `.orb` divs — the
 *    AppChrome already paints `<AtmosphereLayer>` once globally, and
 *    repeating ambient gradients per-screen was flagged in the Phase 7
 *    audit as part of the "1 brand gradient × 108 surfaces" pattern.
 *  - Boarding pass / portfolio / social link → `Surface variant="elevated"`
 *    (replaces `UltraGlass depth={2} edgeHighlight`).
 *  - Section headings → `Text variant="caption-1" tone="tertiary"`.
 *  - `AnimatedPage` per-section wrapper → motion@12 stagger via the
 *    v2 motion tokens.
 *  - All status chips → `Pill tone="..."`.
 */
const Home: React.FC = () => {
  const navigate = useNavigate();
  const [showAssistant, setShowAssistant] = useState(false);
  const unreadCount = useAlertsStore(
    (s) => s.alerts.filter((a) => !a.read).length,
  );
  const [refreshing, setRefreshing] = useState(false);
  const [pullDistance, setPullDistance] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  const pullControls = useAnimation();
  const contentControls = useAnimation();

  const balances = useWalletStore((s) => s.balances);
  const totalUSD = useMemo(
    () => balances.reduce((acc, b) => acc + b.amount * b.rate, 0),
    [balances],
  );

  const travelHistory = useUserStore((s) => s.travelHistory);
  const nextTrip = useMemo(
    () => selectNextUpcoming(travelHistory),
    [travelHistory],
  );
  const fromAirport = nextTrip ? getAirport(nextTrip.from) : null;
  const toAirport = nextTrip ? getAirport(nextTrip.to) : null;

  const handlePan = useCallback(
    (_: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
      if (refreshing) return;
      const el = containerRef.current;
      if (el && el.scrollTop > 5) return;
      const d = Math.max(0, info.offset.y);
      const next = Math.min(d * 0.5, 120);
      setPullDistance(next);
      if (next >= PULL_THRESHOLD) {
        haptics.selection();
      }
    },
    [refreshing],
  );

  const handlePanEnd = useCallback(async () => {
    if (pullDistance >= PULL_THRESHOLD && !refreshing) {
      setRefreshing(true);
      haptics.medium();
      uiSound.confirm();
      // The refresh action is instant (no real fetch). The 400ms beat
      // gives the spinner enough time to register as feedback without
      // sitting on a stale screen.
      await new Promise((r) => setTimeout(r, 400));
      haptics.success();
      setRefreshing(false);
    }
    setPullDistance(0);
  }, [pullDistance, refreshing]);

  // Drive the pull-to-refresh indicator + content offset off pullDistance.
  React.useEffect(() => {
    pullControls.start({
      height: refreshing ? 60 : pullDistance > 0 ? pullDistance : 0,
      opacity: pullDistance > 10 || refreshing ? 1 : 0,
      transition: spring.snap,
    });
    contentControls.start({
      y: refreshing ? 50 : pullDistance > 0 ? pullDistance * 0.4 : 0,
      transition: spring.snap,
    });
  }, [pullDistance, refreshing, pullControls, contentControls]);

  const pullProgress = Math.min(pullDistance / PULL_THRESHOLD, 1);
  const pullActive = pullProgress >= 1 || refreshing;

  const handleNavigate = (path: string) => {
    uiSound.navigate();
    navigate(path);
  };

  return (
    <motion.div
      ref={containerRef}
      className="px-4 py-6 space-y-5 min-h-[100dvh] relative"
      onPan={handlePan}
      onPanEnd={handlePanEnd}
      style={{ touchAction: "pan-y" }}
    >
      {/* Pull-to-refresh indicator */}
      <motion.div
        className="absolute top-0 left-0 right-0 flex items-center justify-center z-20 pointer-events-none"
        animate={pullControls}
        initial={{ height: 0, opacity: 0 }}
      >
        <div className="flex items-center gap-2">
          <motion.div
            animate={{
              rotate: refreshing ? 360 : pullProgress * 270,
            }}
            transition={
              refreshing
                ? { repeat: Infinity, duration: 0.8, ease: "linear" }
                : spring.default
            }
          >
            <RefreshCw
              className={cn(
                "w-5 h-5",
                pullActive ? "text-brand" : "text-ink-tertiary",
              )}
              strokeWidth={2}
            />
          </motion.div>
          <Text
            variant="caption-1"
            tone={pullActive ? "brand" : "tertiary"}
          >
            {refreshing
              ? "Refreshing..."
              : pullProgress >= 1
                ? "Release to refresh"
                : "Pull to refresh"}
          </Text>
        </div>
      </motion.div>

      <motion.div
        className="space-y-5"
        animate={contentControls}
        initial={{ y: 0 }}
      >
        <TravelAssistant
          open={showAssistant}
          onClose={() => setShowAssistant(false)}
        />

        <motion.div
          variants={containerVariants}
          initial="initial"
          animate="animate"
          className="space-y-5"
        >
          {/* 1. Profile Summary */}
          <motion.div variants={itemVariants}>
            <ProfileCard />
          </motion.div>

          {/* 2. Travel Statistics */}
          <motion.section variants={itemVariants} className="space-y-3">
            <SectionHeading>Travel Stats</SectionHeading>
            <TravelStats />
          </motion.section>

          {/* 3. Alerts */}
          {unreadCount > 0 ? (
            <motion.section variants={itemVariants} className="space-y-3">
              <div className="flex items-center justify-between px-1">
                <Text
                  as="h3"
                  variant="caption-1"
                  tone="tertiary"
                  className="uppercase tracking-[0.18em] flex items-center gap-1.5"
                >
                  <Bell
                    className="w-3.5 h-3.5 text-[hsl(var(--p7-warning))]"
                    strokeWidth={2}
                  />
                  Alerts
                </Text>
                <Pill tone="critical" weight="solid">
                  {unreadCount}
                </Pill>
              </div>
              <TravelAlerts />
            </motion.section>
          ) : null}

          {/* 4. Boarding Pass / Next Flight */}
          {nextTrip ? (
            <motion.div variants={itemVariants}>
              <Surface
                variant="elevated"
                radius="sheet"
                onClick={() => handleNavigate("/travel")}
                className="cursor-pointer p-5 space-y-4"
              >
                <div className="flex items-center gap-3">
                  <span
                    aria-hidden
                    className="flex h-10 w-10 items-center justify-center rounded-p7-input bg-brand-soft"
                  >
                    <Plane
                      className="w-4 h-4 text-brand"
                      strokeWidth={2}
                    />
                  </span>
                  <div className="flex-1 min-w-0">
                    <Text
                      variant="caption-2"
                      tone="tertiary"
                      className="uppercase tracking-[0.18em]"
                    >
                      Boarding Pass
                    </Text>
                    <Text variant="body-em" tone="primary" truncate>
                      {nextTrip.airline}
                      {nextTrip.flightNumber
                        ? ` · ${nextTrip.flightNumber}`
                        : ""}
                    </Text>
                  </div>
                  <Pill tone="accent" weight="tinted">
                    {nextTrip.type}
                  </Pill>
                </div>

                <div className="flex items-center justify-between">
                  <div className="text-center">
                    <Text variant="title-2" tone="primary" className="tabular-nums">
                      {nextTrip.from}
                    </Text>
                    <Text variant="caption-2" tone="tertiary">
                      {fromAirport?.city ?? nextTrip.from}
                    </Text>
                  </div>
                  <div className="flex-1 mx-4 flex flex-col items-center">
                    <span className="relative h-px w-full bg-surface-hairline">
                      <span className="absolute left-0 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-brand" />
                      <span className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 inline-flex">
                        <Plane className="w-3.5 h-3.5 text-brand" strokeWidth={2} />
                      </span>
                      <span className="absolute right-0 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-state-accent" />
                    </span>
                    <Text variant="caption-2" tone="tertiary" className="mt-2">
                      {nextTrip.duration} · {formatTripDate(nextTrip.date)}
                    </Text>
                  </div>
                  <div className="text-center">
                    <Text variant="title-2" tone="primary" className="tabular-nums">
                      {nextTrip.to}
                    </Text>
                    <Text variant="caption-2" tone="tertiary">
                      {toAirport?.city ?? nextTrip.to}
                    </Text>
                  </div>
                </div>

                <div className="grid grid-cols-4 gap-2 pt-3 border-t border-surface-hairline">
                  <BoardingDetail
                    label="Date"
                    value={formatTripDate(nextTrip.date)}
                  />
                  <BoardingDetail
                    label="Flight"
                    value={nextTrip.flightNumber ?? "—"}
                  />
                  <BoardingDetail label="Duration" value={nextTrip.duration} />
                  <BoardingDetail
                    label="Source"
                    value={nextTrip.source}
                    capitalize
                  />
                </div>

                <div className="flex items-center justify-between pt-3 border-t border-dashed border-surface-hairline">
                  <Text variant="mono" tone="tertiary">
                    {nextTrip.flightNumber ?? nextTrip.id}
                  </Text>
                  <span className="inline-flex items-center gap-1.5 text-brand">
                    <QrCode className="w-3.5 h-3.5" strokeWidth={2} />
                    <Text variant="callout" tone="brand" className="font-semibold">
                      View Pass
                    </Text>
                  </span>
                </div>
              </Surface>
            </motion.div>
          ) : null}

          {/* 5. Upcoming Trips */}
          <motion.section variants={itemVariants} className="space-y-3">
            <SectionHeading>Upcoming Trips</SectionHeading>
            <UpcomingTrips />
          </motion.section>

          {/* 6. Portfolio Value */}
          <motion.div variants={itemVariants}>
            <Surface
              variant="elevated"
              radius="surface"
              onClick={() => handleNavigate("/wallet")}
              className="cursor-pointer flex items-center gap-4 px-5 py-4"
            >
              <span
                aria-hidden
                className="flex h-10 w-10 items-center justify-center rounded-p7-input bg-brand-soft shrink-0"
              >
                <TrendingUp className="w-4 h-4 text-brand" strokeWidth={2} />
              </span>
              <div className="flex-1 min-w-0">
                <Text
                  variant="caption-2"
                  tone="tertiary"
                  className="uppercase tracking-[0.18em]"
                >
                  Total Balance
                </Text>
                <Text variant="title-2" tone="primary" className="tabular-nums">
                  ${totalUSD.toLocaleString("en-US", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}
                </Text>
              </div>
              <div className="flex -space-x-1.5">
                {balances.slice(0, 4).map((b) => (
                  <span
                    key={b.currency}
                    className="text-[11px] w-7 h-7 rounded-full bg-surface-overlay border border-surface-hairline flex items-center justify-center"
                  >
                    {b.flag}
                  </span>
                ))}
              </div>
            </Surface>
          </motion.div>

          {/* 7. Quick Actions */}
          <motion.section variants={itemVariants} className="space-y-3">
            <SectionHeading>Quick Actions</SectionHeading>
            <QuickActions />
          </motion.section>

          {/* 8. Travel Feed Link */}
          <motion.div variants={itemVariants}>
            <Surface
              variant="plain"
              radius="surface"
              onClick={() => handleNavigate("/social")}
              className="cursor-pointer flex items-center gap-3 px-5 py-4"
            >
              <span
                aria-hidden
                className="flex h-10 w-10 items-center justify-center rounded-p7-input bg-state-accent-soft shrink-0"
              >
                <Users
                  className="w-4 h-4 text-state-accent"
                  strokeWidth={2}
                />
              </span>
              <div className="flex-1 min-w-0">
                <Text variant="body-em" tone="primary">
                  Travel Feed
                </Text>
                <Text variant="caption-1" tone="tertiary">
                  See what travelers are sharing
                </Text>
              </div>
              <ChevronRight className="w-4 h-4 text-ink-tertiary" />
            </Surface>
          </motion.div>

          {/* 9. Travel Suggestions */}
          <motion.section variants={itemVariants} className="space-y-3">
            <SectionHeading>Travel Suggestions</SectionHeading>
            <Suggestions />
          </motion.section>
        </motion.div>
      </motion.div>
    </motion.div>
  );
};

export default Home;

/* ──────────────────── Local sub-components ──────────────────── */

const SectionHeading: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => (
  <Text
    as="h3"
    variant="caption-1"
    tone="tertiary"
    className="px-1 uppercase tracking-[0.18em]"
  >
    {children}
  </Text>
);

const BoardingDetail: React.FC<{
  label: string;
  value: string;
  capitalize?: boolean;
}> = ({ label, value, capitalize }) => (
  <div>
    <Text variant="caption-2" tone="tertiary" className="capitalize">
      {label}
    </Text>
    <Text
      variant="callout"
      tone="primary"
      className={cn("font-semibold", capitalize && "capitalize")}
    >
      {value}
    </Text>
  </div>
);
