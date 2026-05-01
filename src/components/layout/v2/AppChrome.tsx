import * as React from "react";
import BottomNavV2 from "./BottomNav";
import PageTransitionV2 from "./PageTransition";
import { FAB } from "@/components/layout/FAB";
import { AIAssistantButton } from "@/components/ai/AIAssistantButton";
import VoiceCommandButton from "@/components/voice/VoiceCommandButton";
import ThemeToggle from "@/components/ThemeToggle";
import AtmosphereLayer from "@/cinematic/AtmosphereLayer";
import SyncBadge from "@/components/layout/SyncBadge";
import OfflineBanner from "@/components/layout/OfflineBanner";
import CommandPaletteProvider from "./CommandPalette";

/**
 * AppChrome v2 — primary chrome wrapper for every routed screen.
 *
 * Composes the v2 design system:
 *  - `BottomNavV2`         — v2 glass surface + shared-layout active pill.
 *  - `PageTransitionV2`    — motion@12, prefers-reduced-motion aware.
 *  - `CommandPaletteProvider` — Cmd+K reachable from any screen.
 *  - `FAB`, `AIAssistantButton`, `VoiceCommandButton`, `ThemeToggle`,
 *    `SyncBadge`, `OfflineBanner`, `AtmosphereLayer` — shared chrome.
 *
 * Exported as the default so `src/App.tsx` can use it as the route element.
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
        <OfflineBanner />
        <SyncBadge />
        {/* Theme toggle — safe-area-aware so on Android it sits below the
            status bar punch-hole / notch. Will be folded into a top status
            row in PR-δ. */}
        <div className="fixed top-safe-4 right-safe-4 z-40">
          <ThemeToggle />
        </div>
        <main
          className="pb-nav-safe pt-safe gpu-layer"
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
        <VoiceCommandButton />
        <BottomNavV2 />
      </div>
    </CommandPaletteProvider>
  );
};

export default AppChromeV2;
