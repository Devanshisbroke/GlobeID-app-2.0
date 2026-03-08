import React, { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoUser, quickActions, demoActivity, demoBalances, demoBookings } from "@/lib/demoData";
import { getIcon } from "@/lib/iconMap";
import { springs } from "@/hooks/useMotion";
import { ChevronRight, MapPin, ShieldCheck, Globe, TrendingUp, Plane, QrCode, Car, ArrowRightLeft, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";

const actionGradients = [
  "bg-gradient-ocean",
  "bg-gradient-forest",
  "bg-gradient-cosmic",
  "bg-gradient-sunset",
  "bg-gradient-aurora",
  "bg-gradient-blue",
  "bg-gradient-purple",
  "bg-gradient-tropical",
];

const container = {
  animate: { transition: { staggerChildren: 0.05 } },
};
const item = {
  initial: { opacity: 0, y: 12, scale: 0.97 },
  animate: { opacity: 1, y: 0, scale: 1 },
};

const Home: React.FC = () => {
  const navigate = useNavigate();

  const totalUSD = useMemo(() => demoBalances.reduce((acc, b) => {
    if (b.currency === "USD") return acc + b.amount;
    if (b.currency === "INR") return acc + b.amount * 0.012;
    if (b.currency === "CNY") return acc + b.amount * 0.14;
    if (b.currency === "AED") return acc + b.amount * 0.27;
    if (b.currency === "SGD") return acc + b.amount * 0.74;
    if (b.currency === "EUR") return acc + b.amount * 1.08;
    return acc;
  }, 0), []);

  const nextFlight = demoBookings.find((b) => b.type === "flight" && b.status === "upcoming");
  const greeting = new Date().getHours() < 12 ? "Good morning" : new Date().getHours() < 18 ? "Good afternoon" : "Good evening";

  return (
    <motion.div
      className="px-4 py-6 space-y-5 bg-gradient-radial min-h-screen"
      variants={container}
      initial="initial"
      animate="animate"
    >
      {/* Ambient orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="orb w-[320px] h-[320px] top-[-5%] left-[-10%]" style={{ background: "hsl(var(--ocean-aqua) / 0.18)" }} />
        <div className="orb w-[280px] h-[280px] bottom-[20%] right-[-15%]" style={{ background: "hsl(var(--forest-jade) / 0.12)", animationDelay: "-7s" }} />
        <div className="orb w-[220px] h-[220px] top-[40%] left-[50%]" style={{ background: "hsl(var(--aurora-purple) / 0.1)", animationDelay: "-13s" }} />
      </div>

      {/* Greeting + Identity Hero */}
      <AnimatedPage>
        <GlassCard className="relative overflow-hidden p-5" variant="premium" glow depth="lg" onClick={() => navigate("/profile")}>
          <div className="absolute inset-0 overflow-hidden rounded-2xl pointer-events-none">
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/[0.03] to-transparent animate-shimmer" />
          </div>

          <div className="relative">
            <div className="flex items-center gap-2 mb-2">
              <Sparkles className="w-3.5 h-3.5 text-neon-amber" strokeWidth={1.8} />
              <p className="text-xs text-muted-foreground font-medium">{greeting},</p>
            </div>
            <h2 className="text-2xl font-bold text-foreground mb-1 tracking-tight">{demoUser.name}</h2>

            {nextFlight && (
              <div className="flex items-center gap-1.5 text-xs text-muted-foreground mb-4">
                <Plane className="w-3.5 h-3.5 text-primary" />
                <span>Flying to <span className="text-foreground font-semibold">Singapore</span> today</span>
              </div>
            )}

            <div className="flex items-center gap-4">
              <motion.div
                className="w-13 h-13 rounded-2xl bg-gradient-cosmic flex items-center justify-center shrink-0 shadow-glow-sm cursor-pointer"
                whileTap={{ scale: 0.9 }}
                transition={springs.bounce}
              >
                <ShieldCheck className="w-5.5 h-5.5 text-primary-foreground" />
              </motion.div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-primary/15 text-primary font-semibold tracking-wide">
                    {demoUser.identityLevel}
                  </span>
                  <span className="text-[10px] text-muted-foreground">·</span>
                  <span className="text-[10px] text-muted-foreground">Passport Linked</span>
                </div>
                <div className="flex gap-1.5 mt-2">
                  {demoUser.countryFlags.map((flag, i) => (
                    <span key={i} className="text-sm w-7 h-7 rounded-lg bg-secondary/40 flex items-center justify-center border border-border/20">{flag}</span>
                  ))}
                </div>
              </div>
              <IdentityScore score={demoUser.identityScore} size={64} strokeWidth={5} />
            </div>

            <div className="mt-4 flex items-center gap-2 px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/30">
              <MapPin className="w-3.5 h-3.5 text-accent" />
              <span className="text-xs text-foreground font-medium">{demoUser.currentFlag} Currently in {demoUser.currentCountry}</span>
              <span className="ml-auto text-[10px] text-accent font-semibold animate-pulse-subtle flex items-center gap-1">
                <ShieldCheck className="w-3 h-3" /> Verified
              </span>
            </div>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Boarding Pass */}
      {nextFlight && (
        <AnimatedPage staggerIndex={1}>
          <GlassCard className="relative overflow-hidden cursor-pointer p-0" variant="premium" depth="lg" onClick={() => navigate("/travel")}>
            <div className="absolute inset-0 bg-gradient-to-br from-primary/8 via-transparent to-accent/5 pointer-events-none" />
            <div className="p-5 relative">
              <div className="flex items-center gap-2 mb-3">
                <motion.div
                  className="w-9 h-9 rounded-xl bg-gradient-ocean flex items-center justify-center shadow-glow-sm"
                  whileTap={{ scale: 0.9 }}
                  transition={springs.bounce}
                >
                  <Plane className="w-4.5 h-4.5 text-primary-foreground" />
                </motion.div>
                <div>
                  <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-medium">Boarding Pass</p>
                  <p className="text-xs text-foreground font-semibold">{nextFlight.subtitle}</p>
                </div>
                <span className="ml-auto text-[10px] px-2.5 py-1 rounded-full bg-accent/15 text-accent font-semibold">{nextFlight.status}</span>
              </div>

              <div className="flex items-center justify-between mb-3">
                <div className="text-center">
                  <p className="text-2xl font-bold text-foreground tracking-tight">SFO</p>
                  <p className="text-[10px] text-muted-foreground">San Francisco</p>
                </div>
                <div className="flex-1 mx-4 flex flex-col items-center">
                  <div className="w-full h-px bg-gradient-to-r from-primary/40 via-primary to-accent/40 relative">
                    <div className="absolute left-0 top-1/2 -translate-y-1/2 w-2.5 h-2.5 rounded-full bg-primary shadow-glow-sm" />
                    <Plane className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 text-primary" />
                    <div className="absolute right-0 top-1/2 -translate-y-1/2 w-2.5 h-2.5 rounded-full bg-accent shadow-glow-sm" />
                  </div>
                  <p className="text-[10px] text-muted-foreground mt-2">18h 15m · Direct</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-foreground tracking-tight">SIN</p>
                  <p className="text-[10px] text-muted-foreground">Singapore</p>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-2 pt-3 border-t border-border/30">
                {Object.entries(nextFlight.details).map(([k, v]) => (
                  <div key={k}>
                    <p className="text-[10px] text-muted-foreground capitalize">{k}</p>
                    <p className="text-xs font-semibold text-foreground">{v}</p>
                  </div>
                ))}
              </div>
            </div>
            <div className="border-t border-dashed border-border/40" />
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-[10px] text-muted-foreground font-mono tracking-wider">{nextFlight.code}</span>
              <div className="flex items-center gap-1.5 text-primary text-xs font-semibold">
                <QrCode className="w-3.5 h-3.5" /> View Pass
              </div>
            </div>
          </GlassCard>
        </AnimatedPage>
      )}

      {/* Portfolio Value */}
      <AnimatedPage staggerIndex={2}>
        <GlassCard className="flex items-center gap-4 py-4" depth="md" onClick={() => navigate("/wallet")}>
          <div className="w-11 h-11 rounded-xl bg-gradient-forest flex items-center justify-center shrink-0 shadow-glow-sm">
            <TrendingUp className="w-5 h-5 text-primary-foreground" />
          </div>
          <div className="flex-1">
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-medium">Total Balance</p>
            <p className="text-2xl font-bold text-foreground tabular-nums tracking-tight">
              ${totalUSD.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </p>
          </div>
          <div className="flex -space-x-1.5">
            {demoBalances.slice(0, 4).map((b) => (
              <span key={b.currency} className="text-sm w-8 h-8 rounded-full glass flex items-center justify-center text-[11px] shadow-depth-sm border border-border/20">
                {b.flag}
              </span>
            ))}
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Quick Actions */}
      <AnimatedPage staggerIndex={3}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Quick Actions</h3>
        <motion.div
          className="grid grid-cols-4 gap-2.5"
          variants={container}
          initial="initial"
          animate="animate"
        >
          {quickActions.map((action, i) => {
            const ActionIcon = getIcon(action.icon);
            return (
              <motion.button
                key={action.id}
                variants={item}
                transition={springs.snappy}
                whileTap={{ scale: 0.92 }}
                onClick={() => action.route && navigate(action.route)}
                className={cn(
                  "relative flex flex-col items-center gap-2 p-3 rounded-2xl min-h-[84px]",
                  "glass border border-border/30",
                  "hover:border-primary/20 hover:shadow-glow-sm",
                  "btn-ripple"
                )}
                aria-label={action.label}
              >
                <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shadow-depth-sm", actionGradients[i % actionGradients.length])}>
                  <ActionIcon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                </div>
                <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                  {action.label}
                </span>
              </motion.button>
            );
          })}
        </motion.div>
      </AnimatedPage>

      {/* Travel Status */}
      <AnimatedPage staggerIndex={4}>
        <GlassCard className="border-gradient" variant="premium" depth="md" interactive={false}>
          <div className="flex items-center gap-2 mb-3">
            <Globe className="w-4 h-4 text-accent" />
            <h3 className="text-sm font-semibold text-foreground">Travel Status</h3>
          </div>
          <div className="grid grid-cols-2 gap-2.5">
            {([
              { Icon: Globe, label: "Current Country", value: "United States", accent: false, gradient: "from-primary/10 to-primary/5" },
              { Icon: ShieldCheck, label: "Entry Status", value: "Verified", accent: true, gradient: "from-accent/10 to-accent/5" },
              { Icon: ArrowRightLeft, label: "Local Currency", value: "USD Active", accent: false, gradient: "from-neon-amber/10 to-neon-amber/5" },
              { Icon: MapPin, label: "Nearby Services", value: "12 available", accent: false, gradient: "from-neon-magenta/10 to-neon-magenta/5" },
            ] as const).map((statusItem, i) => (
              <motion.div
                key={i}
                variants={item}
                transition={springs.card}
                className={cn("flex items-center gap-2.5 p-2.5 rounded-xl border border-border/20", `bg-gradient-to-br ${statusItem.gradient}`)}
              >
                <div className="w-7 h-7 rounded-lg bg-secondary/50 flex items-center justify-center">
                  <statusItem.Icon className={cn("w-3.5 h-3.5", statusItem.accent ? "text-accent" : "text-muted-foreground")} strokeWidth={1.8} />
                </div>
                <div>
                  <p className="text-[10px] text-muted-foreground">{statusItem.label}</p>
                  <p className={cn("text-xs font-semibold", statusItem.accent ? "text-accent" : "text-foreground")}>{statusItem.value}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Suggestions */}
      <AnimatedPage staggerIndex={5}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Suggestions</h3>
        <div className="space-y-2.5">
          <GlassCard className="cursor-pointer" onClick={() => navigate("/services")}>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-sunset flex items-center justify-center shrink-0 shadow-depth-sm">
                <Car className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-foreground">Need a ride from the airport?</p>
                <p className="text-xs text-muted-foreground">Book a ride in seconds</p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground/60" />
            </div>
          </GlassCard>
          <GlassCard className="cursor-pointer" onClick={() => navigate("/wallet")}>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-aurora flex items-center justify-center shrink-0 shadow-depth-sm">
                <ArrowRightLeft className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-foreground">Convert your currency</p>
                <p className="text-xs text-muted-foreground">Tap to convert instantly</p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground/60" />
            </div>
          </GlassCard>
        </div>
      </AnimatedPage>

      {/* Activity Feed */}
      <AnimatedPage staggerIndex={6}>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Activity</h3>
          <button className="text-xs text-primary font-medium hover:text-primary/80 transition-colors">View all</button>
        </div>
        <motion.div className="space-y-2" variants={container} initial="initial" animate="animate">
          {demoActivity.slice(0, 5).map((actItem) => {
            const ItemIcon = getIcon(actItem.icon);
            return (
              <motion.div key={actItem.id} variants={item} transition={springs.card}>
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
  );
};

export default Home;
