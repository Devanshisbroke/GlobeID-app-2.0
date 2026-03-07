import React from "react";
import { BottomTabBar } from "./BottomTabBar";
import { FAB } from "./FAB";
import { AIAssistantButton } from "@/components/ai/AIAssistantButton";

interface AppShellProps {
  children: React.ReactNode;
}

const AppShell: React.FC<AppShellProps> = ({ children }) => {
  return (
    <div className="relative min-h-[100dvh] max-w-lg mx-auto overflow-x-hidden">
      <main className="pb-20 pt-safe">{children}</main>
      <FAB />
      <AIAssistantButton />
      <BottomTabBar />
    </div>
  );
};

export { AppShell };
