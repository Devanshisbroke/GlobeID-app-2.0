import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoUser, quickActions, demoActivity } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
import { ChevronRight, MapPin, ShieldCheck, Banknote, Globe, User } from "lucide-react";

const Home: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="px-4 py-6 space-y-6">
      {/* Profile Card */}
      <AnimatedPage>
        <GlassCard className="flex items-center gap-4">
          <div className="relative shrink-0 cursor-pointer" onClick={() => navigate("/profile")}>
            <img
              src={demoUser.avatar}
              alt={demoUser.name}
              className="w-16 h-16 rounded-full object-cover ring-2 ring-accent/30"
            />
            <span className="absolute -bottom-0.5 -right-0.5 text-xs bg-accent text-accent-foreground px-1.5 py-0.5 rounded-full font-medium leading-none">
              ✓
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <h2 className="text-lg font-semibold text-foreground truncate">
              {demoUser.name}
            </h2>
            <p className="text-xs text-muted-foreground">{demoUser.identityLevel} Identity</p>
            <div className="flex gap-1 mt-1">
              {demoUser.countryFlags.map((flag, i) => (
                <span key={i} className="text-sm">{flag}</span>
              ))}
            </div>
          </div>
          <IdentityScore score={demoUser.identityScore} size={64} strokeWidth={5} />
        </GlassCard>
      </AnimatedPage>

      {/* Travel Status */}
      <AnimatedPage staggerIndex={1}>
        <GlassCard className="border border-accent/20">
          <div className="flex items-center gap-2 mb-3">
            <MapPin className="w-4 h-4 text-accent" />
            <h3 className="text-sm font-semibold text-foreground">Travel Status</h3>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex items-center gap-2">
              <Globe className="w-3.5 h-3.5 text-muted-foreground" />
              <div>
                <p className="text-[10px] text-muted-foreground">Current Country</p>
                <p className="text-xs font-medium text-foreground">🇸🇬 Singapore</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-3.5 h-3.5 text-accent" />
              <div>
                <p className="text-[10px] text-muted-foreground">Entry Status</p>
                <p className="text-xs font-medium text-accent">Verified ✓</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Banknote className="w-3.5 h-3.5 text-muted-foreground" />
              <div>
                <p className="text-[10px] text-muted-foreground">Local Currency</p>
                <p className="text-xs font-medium text-foreground">SGD Enabled</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <User className="w-3.5 h-3.5 text-muted-foreground" />
              <div>
                <p className="text-[10px] text-muted-foreground">Nearby Services</p>
                <p className="text-xs font-medium text-foreground">12 available</p>
              </div>
            </div>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Quick Actions */}
      <AnimatedPage staggerIndex={2}>
        <h3 className="text-sm font-medium text-muted-foreground mb-3 px-1">Quick Actions</h3>
        <div className="grid grid-cols-4 gap-2">
          {quickActions.map((action, i) => (
            <button
              key={action.id}
              onClick={() => action.route && navigate(action.route)}
              className="flex flex-col items-center gap-1.5 p-3 rounded-2xl glass border border-border min-h-[76px] transition-transform duration-[var(--motion-micro)] active:scale-90 hover:border-accent/30 animate-fade-in"
              style={{ animationDelay: staggerDelay(i, 40) }}
              aria-label={action.label}
            >
              <span className="text-xl">{action.icon}</span>
              <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">
                {action.label}
              </span>
            </button>
          ))}
        </div>
      </AnimatedPage>

      {/* Activity Feed */}
      <AnimatedPage staggerIndex={3}>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-sm font-medium text-muted-foreground">Recent Activity</h3>
          <button className="text-xs text-accent">View all</button>
        </div>
        <div className="space-y-2">
          {demoActivity.slice(0, 6).map((item, i) => (
            <GlassCard
              key={item.id}
              className="flex items-center gap-3 py-3 px-4 animate-fade-in cursor-pointer active:scale-[0.98] transition-transform"
              style={{ animationDelay: staggerDelay(i, 50) }}
            >
              <span className="text-lg shrink-0">{item.icon}</span>
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
                <ChevronRight className="w-3.5 h-3.5 text-muted-foreground" />
              </div>
            </GlassCard>
          ))}
        </div>
      </AnimatedPage>
    </div>
  );
};

export default Home;
