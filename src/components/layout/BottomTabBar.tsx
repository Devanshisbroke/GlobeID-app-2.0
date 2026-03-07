import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Home, Shield, Wallet, Plane, LayoutGrid, Navigation } from "lucide-react";

const tabs = [
  { path: "/", icon: Home, label: "Home", gradient: "from-primary to-neon-cyan" },
  { path: "/identity", icon: Shield, label: "Identity", gradient: "from-accent to-forest-mint" },
  { path: "/wallet", icon: Wallet, label: "Wallet", gradient: "from-neon-teal to-forest-emerald" },
  { path: "/travel", icon: Plane, label: "Travel", gradient: "from-neon-indigo to-cosmic-electric" },
  { path: "/map", icon: Navigation, label: "Map", gradient: "from-neon-amber to-sunset-gold" },
  { path: "/services", icon: LayoutGrid, label: "Services", gradient: "from-neon-magenta to-aurora-pink" },
];

const BottomTabBar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  if (location.pathname === "/lock") return null;

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-50 pb-safe border-t border-border/30"
      style={{
        background: "hsl(var(--card) / 0.88)",
        backdropFilter: "blur(28px) saturate(1.6)",
        WebkitBackdropFilter: "blur(28px) saturate(1.6)",
      }}
      role="tablist"
      aria-label="Main navigation"
    >
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto px-1">
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
                "relative flex flex-col items-center justify-center gap-0.5 min-w-[48px] min-h-[48px] rounded-xl",
                "transition-all duration-[var(--motion-small)] ease-[var(--ease-cinematic)]",
                isActive ? "text-primary" : "text-muted-foreground hover:text-foreground/70 active:scale-90"
              )}
            >
              {isActive && (
                <span className="absolute inset-0 rounded-xl bg-primary/6 animate-scale-in" />
              )}
              <Icon
                className={cn("w-[20px] h-[20px] relative transition-all duration-[var(--motion-small)]", isActive && "scale-110")}
                style={isActive ? { filter: `drop-shadow(0 0 6px currentColor)` } : undefined}
                strokeWidth={isActive ? 2.2 : 1.8}
              />
              <span className={cn("text-[9px] font-medium leading-none relative transition-colors", isActive ? "text-primary" : "text-muted-foreground")}>
                {tab.label}
              </span>
              {isActive && (
                <span className={cn("absolute -bottom-0 w-8 h-[2px] rounded-full bg-gradient-to-r", tab.gradient)} />
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
};

export { BottomTabBar };
