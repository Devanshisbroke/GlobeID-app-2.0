import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoUser } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
import { ShieldCheck, Landmark, Settings, Code2, ChevronRight, Globe, Bell, Languages, Monitor, ScrollText, RotateCcw } from "lucide-react";
import { cn } from "@/lib/utils";

interface SettingItem { icon: React.ElementType; label: string; description: string; color?: string; route?: string; }

const settingSections: { title: string; items: SettingItem[] }[] = [
  {
    title: "Security",
    items: [
      { icon: ShieldCheck, label: "Security Center", description: "Biometrics, 2FA, recovery keys", color: "text-accent" },
      { icon: Landmark, label: "Bank & KYC", description: "Connected accounts & verification", color: "text-neon-teal" },
    ],
  },
  {
    title: "Preferences",
    items: [
      { icon: Globe, label: "Currency & Region", description: "USD — United States", color: "text-primary" },
      { icon: Languages, label: "Language", description: "English", color: "text-neon-cyan" },
      { icon: Bell, label: "Notifications", description: "Push, email, in-app", color: "text-accent" },
    ],
  },
  {
    title: "Developer",
    items: [
      { icon: Monitor, label: "Kiosk Simulator", description: "Test identity verification flow", color: "text-primary", route: "/kiosk-sim" },
      { icon: ScrollText, label: "Audit Logs", description: "View session & verification events", color: "text-muted-foreground", route: "/kiosk-sim" },
      { icon: Code2, label: "Developer Tools", description: "Demo mode, debug overlays", color: "text-muted-foreground" },
      { icon: RotateCcw, label: "Reset Demo Data", description: "Clear all sessions & receipts", color: "text-destructive" },
    ],
  },
];

const Profile: React.FC = () => {
  const navigate = useNavigate();
  const [demoMode, setDemoMode] = useState(true);

  return (
    <div className="px-4 py-6 space-y-5">
      <AnimatedPage>
        <GlassCard className="flex items-center gap-4 relative overflow-hidden light-sweep" variant="premium" glow depth="lg">
          <div className="w-14 h-14 rounded-2xl bg-gradient-cosmic flex items-center justify-center shrink-0 shadow-glow-sm">
            <ShieldCheck className="w-6 h-6 text-primary-foreground" />
          </div>
          <div className="flex-1 min-w-0 relative">
            <h2 className="text-lg font-bold text-foreground">{demoUser.name}</h2>
            <p className="text-xs text-muted-foreground">{demoUser.email}</p>
            <p className="text-xs text-primary mt-0.5 font-semibold">{demoUser.identityLevel} · Member since {demoUser.memberSince}</p>
          </div>
          <Settings className="w-5 h-5 text-muted-foreground/60 relative" />
        </GlassCard>
      </AnimatedPage>

      {settingSections.map((section, si) => (
        <AnimatedPage key={section.title} staggerIndex={si + 1}>
          <h3 className="text-xs font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-widest">{section.title}</h3>
          <div className="space-y-2">
            {section.items.map((item, ii) => {
              const Icon = item.icon;
              return (
                <GlassCard key={item.label} className="flex items-center gap-3 py-3 cursor-pointer animate-fade-in touch-bounce" style={{ animationDelay: staggerDelay(ii, 50) }} onClick={() => item.route && navigate(item.route)}>
                  <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 border border-border/20">
                    <Icon className={cn("w-4 h-4", item.color)} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground">{item.label}</p>
                    <p className="text-xs text-muted-foreground">{item.description}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground/50 shrink-0" />
                </GlassCard>
              );
            })}
          </div>
        </AnimatedPage>
      ))}

      <AnimatedPage staggerIndex={4}>
        <GlassCard className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-foreground">Demo Mode</p>
            <p className="text-xs text-muted-foreground">Uses sample data for all flows</p>
          </div>
          <button
            onClick={() => setDemoMode(!demoMode)}
            className={cn("w-12 h-7 rounded-full transition-all duration-[var(--motion-small)] relative", demoMode ? "bg-primary shadow-glow-sm" : "bg-secondary")}
            role="switch" aria-checked={demoMode} aria-label="Toggle demo mode"
          >
            <span className={cn("absolute top-0.5 w-6 h-6 rounded-full bg-primary-foreground shadow-depth-sm transition-transform duration-[var(--motion-small)]", demoMode ? "translate-x-5" : "translate-x-0.5")} />
          </button>
        </GlassCard>
      </AnimatedPage>

      <p className="text-center text-[10px] text-muted-foreground/60 pb-4 tracking-wide">GlobeID v4.0.0 · Premium · Phase 4</p>
    </div>
  );
};

export default Profile;
