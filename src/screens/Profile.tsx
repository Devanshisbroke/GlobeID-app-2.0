import React, { useState } from "react";
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
} from "lucide-react";
import { cn } from "@/lib/utils";

interface SettingItem {
  icon: React.ElementType;
  label: string;
  description: string;
  color?: string;
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
      { icon: Globe, label: "Currency & Region", description: "USD — United States", color: "text-neon-indigo" },
      { icon: Languages, label: "Language", description: "English", color: "text-neon-cyan" },
      { icon: Bell, label: "Notifications", description: "Push, email, in-app", color: "text-accent" },
    ],
  },
  {
    title: "Developer",
    items: [
      { icon: Code2, label: "Developer Tools", description: "Demo mode, debug overlays", color: "text-muted-foreground" },
    ],
  },
];

const Profile: React.FC = () => {
  const [demoMode, setDemoMode] = useState(true);

  return (
    <div className="px-4 py-6 space-y-6">
      {/* Profile Header */}
      <AnimatedPage>
        <GlassCard className="flex items-center gap-4">
          <img
            src={demoUser.avatar}
            alt={demoUser.name}
            className="w-16 h-16 rounded-full object-cover ring-2 ring-accent/30"
          />
          <div className="flex-1 min-w-0">
            <h2 className="text-lg font-semibold text-foreground">{demoUser.name}</h2>
            <p className="text-xs text-muted-foreground">{demoUser.email}</p>
            <p className="text-xs text-accent mt-0.5">
              {demoUser.identityLevel} · Member since {demoUser.memberSince}
            </p>
          </div>
          <Settings className="w-5 h-5 text-muted-foreground" />
        </GlassCard>
      </AnimatedPage>

      {/* Settings Sections */}
      {settingSections.map((section, si) => (
        <AnimatedPage key={section.title} staggerIndex={si + 1}>
          <h3 className="text-sm font-medium text-muted-foreground mb-3 px-1">
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
                >
                  <Icon className={cn("w-5 h-5 shrink-0", item.color)} />
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
        GlobeID v1.0.0 — Phase 1
      </p>
    </div>
  );
};

export default Profile;
