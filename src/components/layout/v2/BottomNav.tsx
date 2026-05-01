import * as React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { Home, Shield, Wallet, Plane, LayoutGrid, Globe2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { spring } from "@/lib/motion-tokens";
import { haptics } from "@/utils/haptics";

/**
 * BottomNav v2 — 6-tab persistent bottom navigation.
 *
 *  - Surface is v2 glass (`--p7-glass-tint` + blur) — chrome-only use.
 *  - Active tab marker is a single shared-layout pill that springs between
 *    triggers via motion's `layoutId` (scoped per component instance so
 *    multiple navs on screen never cross-animate).
 *  - Icon weight is uniform (1.6) when inactive, 2.0 when active.
 *  - Label always renders below the icon. Active label is brand sapphire.
 *  - Hairline top border + safe-area-aware bottom padding for Android edge.
 *
 * Tabs: Home / Identity / Wallet / Travel / Map / Services.
 */

const tabs = [
  { path: "/", icon: Home, label: "Home" },
  { path: "/identity", icon: Shield, label: "Identity" },
  { path: "/wallet", icon: Wallet, label: "Wallet" },
  { path: "/travel", icon: Plane, label: "Travel" },
  { path: "/map", icon: Globe2, label: "Map" },
  { path: "/services", icon: LayoutGrid, label: "Services" },
] as const;

const INSTANCE_ID = "p7-bottom-nav-active";

const BottomNavV2: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  if (location.pathname === "/lock") return null;

  const activePath =
    tabs.find((t) =>
      t.path === "/"
        ? location.pathname === "/"
        : location.pathname.startsWith(t.path),
    )?.path ?? null;

  return (
    <nav
      role="tablist"
      aria-label="Main navigation"
      className={cn(
        "fixed bottom-0 left-0 right-0 z-50 pb-safe",
        "border-t border-surface-hairline",
        // Glass surface — see Surface.tsx variant=glass for the same recipe.
        "bg-[hsl(var(--p7-glass-tint))]",
        "[backdrop-filter:blur(var(--p7-glass-blur))_saturate(1.4)]",
        "[-webkit-backdrop-filter:blur(var(--p7-glass-blur))_saturate(1.4)]",
      )}
    >
      <div className="mx-auto flex h-16 max-w-lg items-stretch justify-around px-2">
        {tabs.map((tab) => {
          const isActive = activePath === tab.path;
          const Icon = tab.icon;
          return (
            <motion.button
              key={tab.path}
              role="tab"
              aria-selected={isActive}
              aria-label={tab.label}
              type="button"
              onClick={() => {
                if (location.pathname !== tab.path) {
                  haptics.navigate();
                  navigate(tab.path);
                }
              }}
              whileTap={{ scale: 0.94 }}
              transition={spring.snap}
              className={cn(
                "relative flex flex-1 flex-col items-center justify-center gap-0.5",
                "min-w-[48px] min-h-[48px] rounded-p7-input",
                "outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
                "transition-colors duration-p7-tap ease-p7-standard",
                isActive
                  ? "text-brand"
                  : "text-ink-tertiary hover:text-ink-secondary",
              )}
            >
              {/* Active background pill — single shared-layout element that
                  motion springs between triggers. Mounted only on the active
                  tab; switching tabs unmounts here and mounts on the new
                  trigger. */}
              {isActive ? (
                <motion.span
                  layoutId={INSTANCE_ID}
                  className="absolute inset-x-2 inset-y-1.5 rounded-p7-input bg-brand-soft -z-0"
                  transition={spring.default}
                  aria-hidden
                />
              ) : null}

              <Icon
                className="relative z-10 h-5 w-5"
                strokeWidth={isActive ? 2.0 : 1.6}
              />
              <span
                className={cn(
                  "relative z-10 text-[10px] font-medium leading-none",
                  isActive ? "font-semibold" : undefined,
                )}
              >
                {tab.label}
              </span>
            </motion.button>
          );
        })}
      </div>
    </nav>
  );
};

export default BottomNavV2;
