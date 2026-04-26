import * as React from "react";
import BottomNavV2 from "./BottomNav";
import PageTransitionV2 from "./PageTransition";
import { FAB } from "@/components/layout/FAB";
import { AIAssistantButton } from "@/components/ai/AIAssistantButton";
import ThemeToggle from "@/components/ThemeToggle";
import AtmosphereLayer from "@/cinematic/AtmosphereLayer";
import SyncBadge from "@/components/layout/SyncBadge";
import CommandPaletteProvider from "./CommandPalette";

/**
 * AppChrome v2 — Phase 7 PR-γ.
 *
 * Persistent shell that wraps every routed screen. Replaces the Phase 6
 * `AppShell.tsx`. Differences:
 *  - Uses `BottomNavV2` (v2 glass surface + sliding indicator) instead of
 *    the legacy `BottomTabBar`.
 *  - Uses `PageTransitionV2` (motion@12, prefers-reduced-motion aware)
 *    instead of the legacy framer-motion `PageTransition`.
 *  - Adds `CommandPaletteProvider` so Cmd+K is reachable from any screen.
 *
 * The screen-level chrome (FAB, AIAssistantButton, theme toggle, sync badge,
 * atmosphere layer) is preserved as-is to avoid touching unrelated surfaces
 * in PR-γ. Their visual migration to v2 happens in PR-δ / PR-ε / PR-ζ.
 *
 * `AppChrome` is exported as a default named component so the App router
 * can use it as a layout element. See `src/App.tsx` for wiring.
 */

interface AppChromeProps {
  children: React.ReactNode;
}

const AppChromeV2: React.FC<AppChromeProps> = ({ children }) => {
  return (
    <CommandPaletteProvider>
      <div className="relative min-h-[100dvh] max-w-lg mx-auto overflow-x-hidden bg-surface-base text-ink-primary">
        {/* Single fixed mesh layer — replaces the body background-image so
            we avoid `background-attachment: fixed` repaints during scroll
            on mobile WebView. Kept from Phase 6 for visual continuity until
            screens migrate. */}
        <div className="fixed inset-0 pointer-events-none bg-mesh -z-10" />
        <AtmosphereLayer />
        <SyncBadge />
        {/* Theme toggle — safe-area-aware so on Android it sits below the
            status bar punch-hole / notch. Will be folded into a top status
            row in PR-δ. */}
        <div className="fixed top-safe-4 right-safe-4 z-40">
          <ThemeToggle />
        </div>
        <main
          className="pb-20 pt-safe gpu-layer"
          style={{
            touchAction: "pan-y",
            WebkitOverflowScrolling: "touch",
            overscrollBehavior: "contain",
          }}
        >
          <PageTransitionV2>{children}</PageTransitionV2>
        </main>
        <FAB />
        <AIAssistantButton />
        <BottomNavV2 />
      </div>
    </CommandPaletteProvider>
  );
};

export default AppChromeV2;
