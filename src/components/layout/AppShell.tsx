import React from "react";
import { BottomTabBar } from "./BottomTabBar";
import { FAB } from "./FAB";
import { AIAssistantButton } from "@/components/ai/AIAssistantButton";
import ThemeToggle from "@/components/ThemeToggle";

interface AppShellProps {
  children: React.ReactNode;
}

const AppShell: React.FC<AppShellProps> = ({ children }) => {
  return (
    <div className="relative min-h-[100dvh] max-w-lg mx-auto overflow-x-hidden">
      <div className="fixed inset-0 pointer-events-none bg-mesh opacity-50 -z-10" />
      {/* Theme toggle */}
      <div className="fixed top-4 right-4 z-40">
        <ThemeToggle />
      </div>
      <main className="pb-20 pt-safe momentum-scroll gpu-layer">{children}</main>
      <FAB />
      <AIAssistantButton />
      <BottomTabBar />
    </div>
  );
};

export { AppShell };
