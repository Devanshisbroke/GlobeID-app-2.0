import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Home, Shield, Wallet, Plane, User } from "lucide-react";

const tabs = [
  { path: "/", icon: Home, label: "Home" },
  { path: "/identity", icon: Shield, label: "Identity" },
  { path: "/wallet", icon: Wallet, label: "Wallet" },
  { path: "/travel", icon: Plane, label: "Travel" },
  { path: "/profile", icon: User, label: "Profile" },
];

const BottomTabBar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  // Hide on lock screen
  if (location.pathname === "/lock") return null;

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-50 glass border-t border-border pb-safe"
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
                "flex flex-col items-center justify-center gap-0.5 min-w-[56px] min-h-[44px] rounded-xl",
                "transition-all duration-[var(--motion-small)] ease-[var(--ease-out-expo)]",
                isActive
                  ? "text-accent scale-105"
                  : "text-muted-foreground hover:text-foreground active:scale-95"
              )}
            >
              <Icon
                className={cn(
                  "w-5 h-5 transition-transform duration-[var(--motion-micro)]",
                  isActive && "drop-shadow-[0_0_6px_hsl(var(--neon-cyan))]"
                )}
              />
              <span className="text-[10px] font-medium leading-none">{tab.label}</span>
              {isActive && (
                <span className="absolute -bottom-0 w-6 h-0.5 rounded-full bg-accent" />
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
};

export { BottomTabBar };
