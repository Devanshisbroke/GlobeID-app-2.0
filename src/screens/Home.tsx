import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoUser, quickActions, demoActivity, demoBalances, demoBookings } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
import { ChevronRight, MapPin, ShieldCheck, Globe, TrendingUp, Plane, QrCode } from "lucide-react";
import { cn } from "@/lib/utils";

const actionGradients = [
  "bg-gradient-blue",
  "bg-gradient-tropical",
  "bg-gradient-purple",
  "bg-gradient-warm",
  "bg-gradient-magenta",
  "bg-gradient-blue",
  "bg-gradient-purple",
];

const Home: React.FC = () => {
  const navigate = useNavigate();

  const totalUSD = demoBalances.reduce((acc, b) => {
    if (b.currency === "USD") return acc + b.amount;
    if (b.currency === "INR") return acc + b.amount * 0.012;
    if (b.currency === "CNY") return acc + b.amount * 0.14;
    if (b.currency === "AED") return acc + b.amount * 0.27;
    if (b.currency === "SGD") return acc + b.amount * 0.74;
    if (b.currency === "EUR") return acc + b.amount * 1.08;
    return acc;
  }, 0);

  const nextFlight = demoBookings.find((b) => b.type === "flight" && b.status === "upcoming");
  const greeting = new Date().getHours() < 12 ? "Good morning" : new Date().getHours() < 18 ? "Good afternoon" : "Good evening";

  return (
    <div className="px-4 py-6 space-y-6 bg-gradient-radial min-h-screen">
      {/* Ambient orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="orb w-[300px] h-[300px] top-[-5%] left-[-10%]" style={{ background: "hsl(var(--blue-start) / 0.2)" }} />
        <div className="orb w-[250px] h-[250px] bottom-[20%] right-[-15%]" style={{ background: "hsl(var(--tropical-start) / 0.15)", animationDelay: "-7s" }} />
        <div className="orb w-[200px] h-[200px] top-[40%] left-[50%]" style={{ background: "hsl(var(--purple-start) / 0.1)", animationDelay: "-13s" }} />
      </div>

      {/* Greeting + Travel Status Hero */}
      <AnimatedPage>
        <GlassCard className="relative overflow-hidden p-5" glow depth="lg">
          <div className="absolute inset-0 overflow-hidden rounded-2xl pointer-events-none">
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/[0.03] to-transparent animate-shimmer" />
          </div>

          <div className="relative">
            {/* Greeting */}
            <p className="text-sm text-muted-foreground mb-1">{greeting},</p>
            <h2 className="text-2xl font-bold text-foreground mb-1">{demoUser.name}</h2>

            {nextFlight && (
              <p className="text-xs text-muted-foreground mb-4">
                ✈️ You are flying to <span className="text-foreground font-semibold">Singapore</span> today
              </p>
            )}

            {/* Identity row */}
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-2xl bg-gradient-blue flex items-center justify-center shrink-0 shadow-glow-sm cursor-pointer" onClick={() => navigate("/profile")}>
                <ShieldCheck className="w-5 h-5 text-primary-foreground" />
              </div>
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
                    <span key={i} className="text-sm">{flag}</span>
                  ))}
                </div>
              </div>
              <IdentityScore score={demoUser.identityScore} size={64} strokeWidth={5} />
            </div>

            {/* Current location */}
            <div className="mt-4 flex items-center gap-2 px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/30">
              <MapPin className="w-3.5 h-3.5 text-accent" />
              <span className="text-xs text-foreground font-medium">{demoUser.currentFlag} Currently in {demoUser.currentCountry}</span>
              <span className="ml-auto text-[10px] text-accent font-semibold animate-pulse-subtle">Entry Verified ✓</span>
            </div>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Boarding Pass Card */}
      {nextFlight && (
        <AnimatedPage staggerIndex={1}>
          <GlassCard
            className="relative overflow-hidden cursor-pointer p-0"
            depth="lg"
            onClick={() => navigate("/travel")}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-primary/8 via-transparent to-accent/6 pointer-events-none" />
            <div className="p-5 relative">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-lg bg-gradient-blue flex items-center justify-center">
                  <Plane className="w-4 h-4 text-primary-foreground" />
                </div>
                <div>
                  <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-medium">Boarding Pass</p>
                  <p className="text-xs text-foreground font-semibold">{nextFlight.subtitle}</p>
                </div>
                <span className="ml-auto text-[10px] px-2 py-0.5 rounded-full bg-accent/15 text-accent font-semibold">{nextFlight.status}</span>
              </div>

              <div className="flex items-center justify-between mb-3">
                <div className="text-center">
                  <p className="text-2xl font-bold text-foreground">SFO</p>
                  <p className="text-[10px] text-muted-foreground">San Francisco</p>
                </div>
                <div className="flex-1 mx-4 flex flex-col items-center">
                  <div className="w-full h-px bg-gradient-to-r from-primary/50 via-primary to-primary/50 relative">
                    <div className="absolute left-0 top-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-primary shadow-glow-sm" />
                    <Plane className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 text-primary" />
                    <div className="absolute right-0 top-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-accent shadow-glow-sm" />
                  </div>
                  <p className="text-[10px] text-muted-foreground mt-2">18h 15m · Direct</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-foreground">SIN</p>
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

            {/* Dashed separator */}
            <div className="border-t border-dashed border-border/40" />

            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-[10px] text-muted-foreground font-mono tracking-wider">{nextFlight.code}</span>
              <div className="flex items-center gap-1.5 text-primary text-xs font-semibold">
                <QrCode className="w-3.5 h-3.5" />
                View Pass
              </div>
            </div>
          </GlassCard>
        </AnimatedPage>
      )}

      {/* Portfolio Value */}
      <AnimatedPage staggerIndex={2}>
        <GlassCard className="flex items-center gap-4 py-4" depth="md">
          <div className="w-11 h-11 rounded-xl bg-gradient-tropical flex items-center justify-center shrink-0 shadow-glow-sm">
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
              <span key={b.currency} className="text-sm w-8 h-8 rounded-full glass flex items-center justify-center text-[11px] shadow-depth-sm">
                {b.flag}
              </span>
            ))}
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Quick Actions — colorful */}
      <AnimatedPage staggerIndex={3}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Quick Actions</h3>
        <div className="grid grid-cols-4 gap-2.5">
          {quickActions.slice(0, 8).map((action, i) => (
            <button
              key={action.id}
              onClick={() => action.route && navigate(action.route)}
              className={cn(
                "relative flex flex-col items-center gap-2 p-3 rounded-2xl min-h-[84px]",
                "glass border border-border/30",
                "transition-all duration-[var(--motion-small)] ease-[var(--ease-cinematic)]",
                "active:scale-90 hover:border-primary/20 hover:shadow-glow-sm",
                "btn-ripple animate-fade-in"
              )}
              style={{ animationDelay: staggerDelay(i, 50) }}
              aria-label={action.label}
            >
              {/* Color accent dot */}
              <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center", actionGradients[i % actionGradients.length])}>
                <span className="text-lg drop-shadow-sm">{action.icon}</span>
              </div>
              <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                {action.label}
              </span>
            </button>
          ))}
        </div>
      </AnimatedPage>

      {/* Travel Status */}
      <AnimatedPage staggerIndex={4}>
        <GlassCard className="border-gradient" depth="md">
          <div className="flex items-center gap-2 mb-3">
            <Globe className="w-4 h-4 text-accent" />
            <h3 className="text-sm font-semibold text-foreground">Travel Status</h3>
          </div>
          <div className="grid grid-cols-2 gap-2.5">
            {[
              { icon: "🇸🇬", label: "Current Country", value: "Singapore", gradient: "from-primary/10 to-primary/5" },
              { icon: "✅", label: "Entry Status", value: "Verified", accent: true, gradient: "from-accent/10 to-accent/5" },
              { icon: "💱", label: "Local Currency", value: "SGD Enabled", gradient: "from-neon-amber/10 to-neon-amber/5" },
              { icon: "📍", label: "Nearby Services", value: "12 available", gradient: "from-neon-magenta/10 to-neon-magenta/5" },
            ].map((item, i) => (
              <div key={i} className={cn("flex items-center gap-2.5 p-2.5 rounded-xl border border-border/20", `bg-gradient-to-br ${item.gradient}`)}>
                <span className="text-sm">{item.icon}</span>
                <div>
                  <p className="text-[10px] text-muted-foreground">{item.label}</p>
                  <p className={cn("text-xs font-semibold", item.accent ? "text-accent" : "text-foreground")}>{item.value}</p>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Country Adaptive Cards */}
      <AnimatedPage staggerIndex={5}>
        <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">Singapore Suggestions</h3>
        <div className="space-y-2.5">
          <GlassCard className="cursor-pointer" onClick={() => navigate("/services")}>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-warm flex items-center justify-center shrink-0">
                <span className="text-lg">🚗</span>
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-foreground">Need a ride from the airport?</p>
                <p className="text-xs text-muted-foreground">Book Grab in seconds</p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground/60" />
            </div>
          </GlassCard>
          <GlassCard className="cursor-pointer" onClick={() => navigate("/wallet")}>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-purple flex items-center justify-center shrink-0">
                <span className="text-lg">💱</span>
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-foreground">Convert your money to SGD</p>
                <p className="text-xs text-muted-foreground">Tap to convert currency</p>
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
        <div className="space-y-2">
          {demoActivity.slice(0, 5).map((item, i) => (
            <GlassCard
              key={item.id}
              className="flex items-center gap-3 py-3 px-4 animate-fade-in cursor-pointer"
              style={{ animationDelay: staggerDelay(i, 60) }}
            >
              <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                <span className="text-base">{item.icon}</span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{item.title}</p>
                <p className="text-xs text-muted-foreground truncate">{item.description}</p>
              </div>
              <div className="flex items-center gap-1 shrink-0">
                <span className="text-[10px] text-muted-foreground">{item.timestamp}</span>
                <ChevronRight className="w-3.5 h-3.5 text-muted-foreground/60" />
              </div>
            </GlassCard>
          ))}
        </div>
      </AnimatedPage>
    </div>
  );
};

export default Home;
