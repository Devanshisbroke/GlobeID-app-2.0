import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoUser } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
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
import { cn } from "@/lib/utils";

interface SettingItem {
  icon: React.ElementType;
  label: string;
  description: string;
  color?: string;
  route?: string;
}

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
      { icon: Globe, label: "Currency & Region", description: "INR — India", color: "text-neon-indigo" },
      { icon: Languages, label: "Language", description: "English", color: "text-neon-cyan" },
      { icon: Bell, label: "Notifications", description: "Push, email, in-app", color: "text-accent" },
    ],
  },
  {
    title: "Developer",
    items: [
      { icon: Monitor, label: "Kiosk Simulator", description: "Test identity verification flow", color: "text-accent", route: "/kiosk-sim" },
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
    <div className="px-4 py-6 space-y-6">
      {/* Profile Header */}
      <AnimatedPage>
        <GlassCard className="flex items-center gap-4 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-neon-indigo/5 via-transparent to-neon-cyan/5 pointer-events-none" />
          <div className="relative">
            <img
              src={demoUser.avatar}
              alt={demoUser.name}
              className="w-16 h-16 rounded-2xl object-cover ring-2 ring-accent/30"
            />
            <span className="absolute -bottom-1 -right-1 w-5 h-5 bg-accent rounded-full flex items-center justify-center">
              <ShieldCheck className="w-3 h-3 text-accent-foreground" />
            </span>
          </div>
          <div className="flex-1 min-w-0 relative">
            <h2 className="text-lg font-bold text-foreground">{demoUser.name}</h2>
            <p className="text-xs text-muted-foreground">{demoUser.email}</p>
            <p className="text-xs text-accent mt-0.5">
              {demoUser.identityLevel} · Member since {demoUser.memberSince}
            </p>
          </div>
          <Settings className="w-5 h-5 text-muted-foreground relative" />
        </GlassCard>
      </AnimatedPage>

      {/* Settings Sections */}
      {settingSections.map((section, si) => (
        <AnimatedPage key={section.title} staggerIndex={si + 1}>
          <h3 className="text-sm font-semibold text-muted-foreground mb-3 px-1 uppercase tracking-wider">
            {section.title}
          </h3>
          <div className="space-y-2">
            {section.items.map((item, ii) => {
              const Icon = item.icon;
              return (
                <GlassCard
                  key={item.label}
                  className="flex items-center gap-3 py-3 cursor-pointer active:scale-[0.98] transition-transform animate-fade-in"
                  style={{ animationDelay: staggerDelay(ii, 50) }}
                  onClick={() => item.route && navigate(item.route)}
                >
                  <div className="w-9 h-9 rounded-xl bg-secondary/80 flex items-center justify-center shrink-0">
                    <Icon className={cn("w-4.5 h-4.5", item.color)} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground">{item.label}</p>
                    <p className="text-xs text-muted-foreground">{item.description}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
                </GlassCard>
              );
            })}
          </div>
        </AnimatedPage>
      ))}

      {/* Demo Mode Toggle */}
      <AnimatedPage staggerIndex={4}>
        <GlassCard className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-foreground">Demo Mode</p>
            <p className="text-xs text-muted-foreground">Uses sample data for all flows</p>
          </div>
          <button
            onClick={() => setDemoMode(!demoMode)}
            className={cn(
              "w-12 h-7 rounded-full transition-colors duration-[var(--motion-small)] relative",
              demoMode ? "bg-accent" : "bg-secondary"
            )}
            role="switch"
            aria-checked={demoMode}
            aria-label="Toggle demo mode"
          >
            <span
              className={cn(
                "absolute top-0.5 w-6 h-6 rounded-full bg-primary-foreground shadow transition-transform duration-[var(--motion-small)]",
                demoMode ? "translate-x-5" : "translate-x-0.5"
              )}
            />
          </button>
        </GlassCard>
      </AnimatedPage>

      <p className="text-center text-[10px] text-muted-foreground pb-4">
        GlobeID v2.0.0 · TerraCore · Phase 2
      </p>
    </div>
  );
};

export default Profile;
