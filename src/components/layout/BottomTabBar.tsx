import React from "react";
import { motion } from "framer-motion";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Home, Shield, Wallet, Plane, LayoutGrid, Navigation } from "lucide-react";
import { haptics } from "@/utils/haptics";
import { spring } from "@/motion/motionConfig";
import { uiSound } from "@/cinematic/uiSound";

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
      className="fixed bottom-0 left-0 right-0 z-50 pb-safe border-t border-border/20"
      style={{
        background: "hsl(var(--card) / 0.82)",
        backdropFilter: "blur(32px) saturate(1.8)",
        WebkitBackdropFilter: "blur(32px) saturate(1.8)",
      }}
      role="tablist"
      aria-label="Main navigation"
    >
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto px-1">
        {tabs.map((tab) => {
          const isActive = location.pathname === tab.path;
          const Icon = tab.icon;
          return (
            <motion.button
              key={tab.path}
              role="tab"
              aria-selected={isActive}
              aria-label={tab.label}
              onClick={() => {
                haptics.navigate();
                uiSound.navigate();
                navigate(tab.path);
              }}
              whileTap={{ scale: 0.85 }}
              transition={spring.snappy}
              className={cn(
                "relative flex flex-col items-center justify-center gap-0.5 min-w-[48px] min-h-[48px] rounded-xl outline-none",
                isActive ? "text-primary" : "text-muted-foreground active:text-foreground/70"
              )}
            >
              {/* Active background pill */}
              {isActive && (
                <motion.span
                  layoutId="tab-active-bg"
                  className="absolute inset-0 rounded-xl bg-primary/8"
                  transition={spring.snappy}
                />
              )}

              <motion.div
                animate={isActive ? { scale: 1.15, y: -1 } : { scale: 1, y: 0 }}
                transition={spring.snappy}
              >
                <Icon
                  className="w-5 h-5 relative"
                  style={isActive ? { filter: "drop-shadow(0 0 8px currentColor)" } : undefined}
                  strokeWidth={isActive ? 2.2 : 1.7}
                />
              </motion.div>

              <span className={cn(
                "text-[9px] font-medium leading-none relative",
                isActive ? "text-primary" : "text-muted-foreground"
              )}>
                {tab.label}
              </span>

              {/* Active indicator line */}
              {isActive && (
                <motion.span
                  layoutId="tab-active-line"
                  className={cn("absolute -bottom-0.5 w-8 h-[2.5px] rounded-full bg-gradient-to-r", tab.gradient)}
                  transition={spring.snappy}
                />
              )}
            </motion.button>
          );
        })}
      </div>
    </nav>
  );
};

export { BottomTabBar };
