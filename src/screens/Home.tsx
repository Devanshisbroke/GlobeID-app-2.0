import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoUser, quickActions, demoActivity, demoBalances } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
import { ChevronRight, MapPin, ShieldCheck, Globe, TrendingUp } from "lucide-react";
import { cn } from "@/lib/utils";

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

  return (
    <div className="px-4 py-6 space-y-6 bg-gradient-radial min-h-screen">
      {/* Ambient orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="orb w-[300px] h-[300px] bg-neon-indigo/20 top-[-5%] left-[-10%]" />
        <div className="orb w-[250px] h-[250px] bg-neon-cyan/15 bottom-[20%] right-[-15%]" style={{ animationDelay: "-7s" }} />
        <div className="orb w-[200px] h-[200px] bg-neon-magenta/10 top-[40%] left-[50%]" style={{ animationDelay: "-13s" }} />
      </div>

      {/* Identity Card — Hero */}
      <AnimatedPage>
        <GlassCard className="relative overflow-hidden p-5" glow depth="lg">
          {/* Shimmer overlay */}
          <div className="absolute inset-0 overflow-hidden rounded-2xl pointer-events-none">
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/[0.03] to-transparent animate-shimmer" />
          </div>

          <div className="relative flex items-center gap-4">
            <div className="relative shrink-0 cursor-pointer group" onClick={() => navigate("/profile")}>
              <img
                src={demoUser.avatar}
                alt={demoUser.name}
                className="w-16 h-16 rounded-2xl object-cover ring-2 ring-accent/30 shadow-glow-sm group-hover:ring-accent/50 transition-all"
              />
              <span className="absolute -bottom-1 -right-1 w-5 h-5 bg-accent rounded-full flex items-center justify-center shadow-glow-sm">
                <ShieldCheck className="w-3 h-3 text-accent-foreground" />
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <h2 className="text-xl font-bold text-foreground truncate">
                {demoUser.name}
              </h2>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span className="text-[10px] px-2 py-0.5 rounded-full bg-accent/15 text-accent font-semibold tracking-wide">
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

          {/* Current location strip */}
          <div className="relative mt-4 flex items-center gap-2 px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/30">
            <MapPin className="w-3.5 h-3.5 text-accent" />
            <span className="text-xs text-foreground font-medium">{demoUser.currentFlag} Currently in {demoUser.currentCountry}</span>
            <span className="ml-auto text-[10px] text-accent font-semibold animate-pulse-subtle">Entry Verified ✓</span>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Portfolio Value */}
      <AnimatedPage staggerIndex={1}>
        <GlassCard className="flex items-center gap-4 py-4" depth="md">
          <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-neon-indigo to-neon-cyan flex items-center justify-center shrink-0 shadow-glow-sm">
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

      {/* Quick Actions */}
      <AnimatedPage staggerIndex={2}>
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
                "active:scale-90 hover:border-accent/20 hover:shadow-glow-sm",
                "btn-ripple animate-fade-in"
              )}
              style={{ animationDelay: staggerDelay(i, 50) }}
              aria-label={action.label}
            >
              <span className="text-2xl">{action.icon}</span>
              <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                {action.label}
              </span>
            </button>
          ))}
        </div>
      </AnimatedPage>

      {/* Travel Status */}
      <AnimatedPage staggerIndex={3}>
        <GlassCard className="border-gradient" depth="md">
          <div className="flex items-center gap-2 mb-3">
            <Globe className="w-4 h-4 text-accent" />
            <h3 className="text-sm font-semibold text-foreground">Travel Status</h3>
          </div>
          <div className="grid grid-cols-2 gap-2.5">
            {[
              { icon: "🇸🇬", label: "Current Country", value: "Singapore" },
              { icon: "✅", label: "Entry Status", value: "Verified", accent: true },
              { icon: "💱", label: "Local Currency", value: "SGD Enabled" },
              { icon: "📍", label: "Nearby Services", value: "12 available" },
            ].map((item, i) => (
              <div key={i} className="flex items-center gap-2.5 p-2.5 rounded-xl bg-secondary/30 border border-border/20">
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

      {/* Activity Feed */}
      <AnimatedPage staggerIndex={4}>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Activity</h3>
          <button className="text-xs text-accent font-medium hover:text-accent/80 transition-colors">View all</button>
        </div>
        <div className="space-y-2">
          {demoActivity.slice(0, 6).map((item, i) => (
            <GlassCard
              key={item.id}
              className="flex items-center gap-3 py-3 px-4 animate-fade-in cursor-pointer"
              style={{ animationDelay: staggerDelay(i, 60) }}
            >
              <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                <span className="text-base">{item.icon}</span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">
                  {item.title}
                </p>
                <p className="text-xs text-muted-foreground truncate">
                  {item.description}
                </p>
              </div>
              <div className="flex items-center gap-1 shrink-0">
                <span className="text-[10px] text-muted-foreground">
                  {item.timestamp}
                </span>
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
