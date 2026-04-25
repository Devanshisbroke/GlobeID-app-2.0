import React from "react";
import { BottomTabBar } from "./BottomTabBar";
import { FAB } from "./FAB";
import { AIAssistantButton } from "@/components/ai/AIAssistantButton";
import ThemeToggle from "@/components/ThemeToggle";
import AtmosphereLayer from "@/cinematic/AtmosphereLayer";
import SyncBadge from "./SyncBadge";

interface AppShellProps {
  children: React.ReactNode;
}

const AppShell: React.FC<AppShellProps> = ({ children }) => {
  return (
    <div className="relative min-h-[100dvh] max-w-lg mx-auto overflow-x-hidden">
      {/* Single fixed mesh layer — replaces the body background-image so
          we avoid `background-attachment: fixed` repaints during scroll
          on mobile WebView. */}
      <div className="fixed inset-0 pointer-events-none bg-mesh -z-10" />
      <AtmosphereLayer />
      <SyncBadge />
      {/* Theme toggle — Phase 6 PR-α: positioned with safe-area-aware
          offsets so on Android it sits below the status bar instead of
          underneath the punch-hole / notch. */}
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
        {children}
      </main>
      <FAB />
      <AIAssistantButton />
      <BottomTabBar />
    </div>
  );
};

export { AppShell };
