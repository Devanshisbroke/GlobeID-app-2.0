import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Home, Shield, Wallet, Plane, LayoutGrid } from "lucide-react";

const tabs = [
  { path: "/", icon: Home, label: "Home", color: "text-primary" },
  { path: "/identity", icon: Shield, label: "Identity", color: "text-accent" },
  { path: "/wallet", icon: Wallet, label: "Wallet", color: "text-neon-teal" },
  { path: "/travel", icon: Plane, label: "Travel", color: "text-neon-indigo" },
  { path: "/services", icon: LayoutGrid, label: "Services", color: "text-neon-magenta" },
];

const BottomTabBar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  if (location.pathname === "/lock") return null;

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-50 pb-safe border-t border-border/40"
      style={{
        background: "hsl(var(--card) / 0.9)",
        backdropFilter: "blur(24px) saturate(1.5)",
        WebkitBackdropFilter: "blur(24px) saturate(1.5)",
      }}
      role="tablist"
      aria-label="Main navigation"
    >
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto px-2">
        {tabs.map((tab) => {
          const isActive = location.pathname === tab.path;
          const Icon = tab.icon;
          return (
            <button
              key={tab.path}
              role="tab"
              aria-selected={isActive}
              aria-label={tab.label}
              onClick={() => navigate(tab.path)}
              className={cn(
                "relative flex flex-col items-center justify-center gap-1 min-w-[56px] min-h-[44px] rounded-xl",
                "transition-all duration-[var(--motion-small)] ease-[var(--ease-cinematic)]",
                isActive ? tab.color : "text-muted-foreground hover:text-foreground/70 active:scale-90"
              )}
            >
              {isActive && (
                <span className="absolute inset-0 rounded-xl bg-primary/5 animate-scale-in" />
              )}
              <Icon
                className={cn(
                  "w-[22px] h-[22px] relative transition-all duration-[var(--motion-small)]",
                  isActive && "scale-110"
                )}
                style={isActive ? { filter: `drop-shadow(0 0 8px currentColor)` } : undefined}
                strokeWidth={isActive ? 2.2 : 1.8}
              />
              <span className={cn(
                "text-[10px] font-medium leading-none relative transition-colors",
                isActive ? tab.color : "text-muted-foreground"
              )}>
                {tab.label}
              </span>
              {isActive && (
                <span className="absolute -bottom-0 w-10 h-[2.5px] rounded-full bg-gradient-to-r from-primary via-accent to-neon-teal" />
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
};

export { BottomTabBar };
