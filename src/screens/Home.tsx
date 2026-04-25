import React, { useMemo, useState, useRef, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion, useMotionValue, useTransform, useAnimation, PanInfo } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { UltraGlass } from "@/components/ui/UltraGlass";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import IconMotion from "@/cinematic/IconMotion";
import { uiSound } from "@/cinematic/uiSound";
import { demoActivity } from "@/lib/demoData";
import { useUserStore, selectNextUpcoming, formatTripDate } from "@/store/userStore";
import { useWalletStore } from "@/store/walletStore";
import { getAirport } from "@/lib/airports";
import { getIcon } from "@/lib/iconMap";
import { springs } from "@/hooks/useMotion";
import { ChevronRight, TrendingUp, Plane, QrCode, Bell, RefreshCw, Users } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAlertsStore } from "@/store/alertsStore";
import { spring as motionSpring } from "@/motion/motionConfig";
import { cinematicEase, cinematicDuration, cinematicStagger, cinematicStaggerItem } from "@/cinematic/motionEngine";
import { haptics } from "@/utils/haptics";

import ProfileCard from "@/components/dashboard/ProfileCard";
import TravelStats from "@/components/dashboard/TravelStats";
import UpcomingTrips from "@/components/dashboard/UpcomingTrips";
import QuickActions from "@/components/dashboard/QuickActions";
import Suggestions from "@/components/dashboard/Suggestions";
import TravelAlerts from "@/components/dashboard/TravelAlerts";
import TravelAssistant from "@/components/ai/TravelAssistant";

const container = {
  animate: { transition: { staggerChildren: 0.06 } },
};
const item = {
  initial: { opacity: 0, y: 12, scale: 0.98 },
  animate: { opacity: 1, y: 0, scale: 1 },
};

const PULL_THRESHOLD = 80;

const Home: React.FC = () => {
  const navigate = useNavigate();
  const [showAssistant, setShowAssistant] = useState(false);
  const unreadCount = useAlertsStore((s) => s.alerts.filter((a) => !a.read).length);
  const [refreshing, setRefreshing] = useState(false);
  const [pullDistance, setPullDistance] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);

  const balances = useWalletStore((s) => s.balances);
  const totalUSD = useMemo(
    () => balances.reduce((acc, b) => acc + b.amount * b.rate, 0),
    [balances]
  );

  const travelHistory = useUserStore((s) => s.travelHistory);
  const nextTrip = useMemo(() => selectNextUpcoming(travelHistory), [travelHistory]);
  const fromAirport = nextTrip ? getAirport(nextTrip.from) : null;
  const toAirport = nextTrip ? getAirport(nextTrip.to) : null;

  const handlePanEnd = useCallback(async () => {
    if (pullDistance >= PULL_THRESHOLD && !refreshing) {
      setRefreshing(true);
      haptics.medium();
      uiSound.confirm();
      /* The refresh action itself is instant (no real fetch yet). The
         400ms beat gives the spinner enough time to register as
         feedback without sitting on a stale screen. */
      await new Promise((r) => setTimeout(r, 400));
      haptics.success();
      setRefreshing(false);
    }
    setPullDistance(0);
  }, [pullDistance, refreshing]);

  const handlePan = useCallback((_: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    if (refreshing) return;
    const el = containerRef.current;
    if (el && el.scrollTop > 5) return;
    const d = Math.max(0, info.offset.y);
    setPullDistance(Math.min(d * 0.5, 120));
    if (d * 0.5 >= PULL_THRESHOLD) {
      haptics.selection();
    }
  }, [refreshing]);

  const pullProgress = Math.min(pullDistance / PULL_THRESHOLD, 1);
  const showPullIndicator = pullDistance > 10 || refreshing;

  const handleNavigate = (path: string) => {
    uiSound.navigate();
    navigate(path);
  };

  return (
    <motion.div
      ref={containerRef}
      className="px-4 py-6 space-y-5 bg-gradient-radial min-h-[100dvh] relative"
      variants={container}
      initial="initial"
      animate="animate"
      onPan={handlePan}
      onPanEnd={handlePanEnd}
      style={{ touchAction: "pan-y" }}
    >
      {/* Pull-to-refresh indicator */}
      <motion.div
        className="absolute top-0 left-0 right-0 flex items-center justify-center z-20 pointer-events-none"
        animate={{
          height: refreshing ? 60 : pullDistance > 0 ? pullDistance : 0,
          opacity: showPullIndicator ? 1 : 0,
        }}
        transition={motionSpring.snappy}
      >
        <motion.div
          className="flex items-center gap-2"
          animate={{ opacity: showPullIndicator ? 1 : 0 }}
        >
          <motion.div
            animate={{ rotate: refreshing ? 360 : pullProgress * 270 }}
            transition={refreshing ? { repeat: Infinity, duration: 0.8, ease: "linear" } : { type: "spring", stiffness: 200 }}
          >
            <RefreshCw className={cn("w-5 h-5", pullProgress >= 1 || refreshing ? "text-primary" : "text-muted-foreground")} strokeWidth={2} />
          </motion.div>
          <span className={cn("text-xs font-medium", pullProgress >= 1 || refreshing ? "text-primary" : "text-muted-foreground")}>
            {refreshing ? "Refreshing..." : pullProgress >= 1 ? "Release to refresh" : "Pull to refresh"}
          </span>
        </motion.div>
      </motion.div>

      {/* Content wrapper with pull offset */}
      <motion.div
        className="space-y-5"
        animate={{ y: refreshing ? 50 : pullDistance > 0 ? pullDistance * 0.4 : 0 }}
        transition={motionSpring.snappy}
      >
      {/* Ambient orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="orb w-[320px] h-[320px] top-[-5%] left-[-10%]" style={{ background: "hsl(var(--ocean-aqua) / 0.18)" }} />
        <div className="orb w-[280px] h-[280px] bottom-[20%] right-[-15%]" style={{ background: "hsl(var(--forest-jade) / 0.12)", animationDelay: "-7s" }} />
        <div className="orb w-[220px] h-[220px] top-[40%] left-[50%]" style={{ background: "hsl(var(--aurora-purple) / 0.1)", animationDelay: "-13s" }} />
      </div>

      {/* Travel Assistant */}
      <TravelAssistant open={showAssistant} onClose={() => setShowAssistant(false)} />

      {/* 1. Profile Summary */}
      <AnimatedPage>
        <ProfileCard />
      </AnimatedPage>

      {/* 2. Travel Statistics */}
      <AnimatedPage staggerIndex={1}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Travel Stats</h3>
        <TravelStats />
      </AnimatedPage>

      {/* 3. Alerts */}
      {unreadCount > 0 && (
        <AnimatedPage staggerIndex={2}>
          <div className="flex items-center justify-between mb-2 px-1">
            <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest flex items-center gap-1.5">
              <IconMotion variant="pulse">
                <Bell className="w-3.5 h-3.5 text-warning" />
              </IconMotion>
              Alerts
              <span className="w-4 h-4 rounded-full bg-destructive text-destructive-foreground text-[9px] flex items-center justify-center font-bold">{unreadCount}</span>
            </h3>
          </div>
          <TravelAlerts />
        </AnimatedPage>
      )}

      {/* 4. Boarding Pass / Next Flight */}
      {nextTrip && (
        <AnimatedPage staggerIndex={3}>
          <UltraGlass depth={2} edgeHighlight className="cursor-pointer" onClick={() => handleNavigate("/travel")}>
            <div className="absolute inset-0 bg-gradient-to-br from-primary/8 via-transparent to-accent/5 pointer-events-none rounded-2xl" />
            <div className="relative">
              <div className="flex items-center gap-2 mb-3">
                <IconMotion variant="float">
                  <motion.div
                    className="w-9 h-9 rounded-xl bg-gradient-brand flex items-center justify-center shadow-glow-sm"
                    whileTap={{ scale: 0.9 }}
                  >
                    <Plane className="w-4.5 h-4.5 text-primary-foreground" />
                  </motion.div>
                </IconMotion>
                <div>
                  <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-medium">Boarding Pass</p>
                  <p className="text-xs text-foreground font-semibold">
                    {nextTrip.airline}{nextTrip.flightNumber ? ` · ${nextTrip.flightNumber}` : ""}
                  </p>
                </div>
                <span className="ml-auto text-[10px] px-2.5 py-1 rounded-full bg-accent/15 text-accent font-semibold">{nextTrip.type}</span>
              </div>

              <div className="flex items-center justify-between mb-3">
                <div className="text-center">
                  <p className="text-2xl font-bold text-foreground tracking-tight">{nextTrip.from}</p>
                  <p className="text-[10px] text-muted-foreground">{fromAirport?.city ?? nextTrip.from}</p>
                </div>
                <div className="flex-1 mx-4 flex flex-col items-center">
                  <div className="w-full h-px bg-gradient-to-r from-primary/40 via-primary to-accent/40 relative">
                    <div className="absolute left-0 top-1/2 -translate-y-1/2 w-2.5 h-2.5 rounded-full bg-primary shadow-glow-sm" />
                    <IconMotion variant="float">
                      <Plane className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 text-primary" />
                    </IconMotion>
                    <div className="absolute right-0 top-1/2 -translate-y-1/2 w-2.5 h-2.5 rounded-full bg-accent shadow-glow-sm" />
                  </div>
                  <p className="text-[10px] text-muted-foreground mt-2">{nextTrip.duration} · {formatTripDate(nextTrip.date)}</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-foreground tracking-tight">{nextTrip.to}</p>
                  <p className="text-[10px] text-muted-foreground">{toAirport?.city ?? nextTrip.to}</p>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-2 pt-3 border-t border-border/30">
                <div>
                  <p className="text-[10px] text-muted-foreground capitalize">date</p>
                  <p className="text-xs font-semibold text-foreground">{formatTripDate(nextTrip.date)}</p>
                </div>
                <div>
                  <p className="text-[10px] text-muted-foreground capitalize">flight</p>
                  <p className="text-xs font-semibold text-foreground">{nextTrip.flightNumber ?? "—"}</p>
                </div>
                <div>
                  <p className="text-[10px] text-muted-foreground capitalize">duration</p>
                  <p className="text-xs font-semibold text-foreground">{nextTrip.duration}</p>
                </div>
                <div>
                  <p className="text-[10px] text-muted-foreground capitalize">source</p>
                  <p className="text-xs font-semibold text-foreground capitalize">{nextTrip.source}</p>
                </div>
              </div>
            </div>
            <div className="border-t border-dashed border-border/40 -mx-4 mt-3" />
            <div className="flex items-center justify-between pt-3 -mx-0">
              <span className="text-[10px] text-muted-foreground font-mono tracking-wider">{nextTrip.flightNumber ?? nextTrip.id}</span>
              <div className="flex items-center gap-1.5 text-primary text-xs font-semibold">
                <QrCode className="w-3.5 h-3.5" /> View Pass
              </div>
            </div>
          </UltraGlass>
        </AnimatedPage>
      )}

      {/* 5. Upcoming Trips */}
      <AnimatedPage staggerIndex={4}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Upcoming Trips</h3>
        <UpcomingTrips />
      </AnimatedPage>

      {/* 6. Portfolio Value */}
      <AnimatedPage staggerIndex={5}>
        <UltraGlass depth={1} edgeHighlight onClick={() => handleNavigate("/wallet")}>
          <div className="flex items-center gap-4">
            <IconMotion variant="breathe">
              <div className="w-11 h-11 rounded-xl bg-gradient-brand flex items-center justify-center shrink-0 shadow-glow-sm">
                <TrendingUp className="w-5 h-5 text-primary-foreground" />
              </div>
            </IconMotion>
            <div className="flex-1">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-medium">Total Balance</p>
              <p className="text-2xl font-bold text-foreground tabular-nums tracking-tight">
                ${totalUSD.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </p>
            </div>
            <div className="flex -space-x-1.5">
              {balances.slice(0, 4).map((b) => (
                <span key={b.currency} className="text-sm w-8 h-8 rounded-full glass flex items-center justify-center text-[11px] shadow-depth-sm border border-border/20">
                  {b.flag}
                </span>
              ))}
            </div>
          </div>
        </UltraGlass>
      </AnimatedPage>

      {/* 7. Quick Actions */}
      <AnimatedPage staggerIndex={6}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Quick Actions</h3>
        <QuickActions />
      </AnimatedPage>

      {/* Social Feed Link */}
      <AnimatedPage staggerIndex={7}>
        <UltraGlass depth={1} onClick={() => handleNavigate("/social")}>
          <div className="flex items-center gap-3">
            <IconMotion variant="glow">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shrink-0 shadow-glow-sm">
                <Users className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
            </IconMotion>
            <div className="flex-1">
              <p className="text-sm font-bold text-foreground">Travel Feed</p>
              <p className="text-xs text-muted-foreground">See what travelers are sharing</p>
            </div>
            <ChevronRight className="w-4 h-4 text-muted-foreground" />
          </div>
        </UltraGlass>
      </AnimatedPage>

      {/* 8. Travel Suggestions */}
      <AnimatedPage staggerIndex={8}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Travel Suggestions</h3>
        <Suggestions />
      </AnimatedPage>

      {/* 9. Activity Feed */}
      <AnimatedPage staggerIndex={9}>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Activity</h3>
          <button className="text-xs text-primary font-medium hover:text-primary/80 transition-colors">View all</button>
        </div>
        <motion.div className="space-y-2" variants={container} initial="initial" animate="animate">
          {demoActivity.slice(0, 5).map((actItem) => {
            const ItemIcon = getIcon(actItem.icon);
            return (
              <motion.div
                key={actItem.id}
                variants={item}
                transition={{ duration: cinematicDuration.cinematic, ease: cinematicEase }}
              >
                <GlassCard className="flex items-center gap-3 py-3 px-4 cursor-pointer">
                  <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                    <ItemIcon className="w-4 h-4 text-muted-foreground" strokeWidth={1.8} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground truncate">{actItem.title}</p>
                    <p className="text-xs text-muted-foreground truncate">{actItem.description}</p>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <span className="text-[10px] text-muted-foreground">{actItem.timestamp}</span>
                    <ChevronRight className="w-3.5 h-3.5 text-muted-foreground/60" />
                  </div>
                </GlassCard>
              </motion.div>
            );
          })}
        </motion.div>
      </AnimatedPage>
      </motion.div>
    </motion.div>
  );
};

export default Home;
