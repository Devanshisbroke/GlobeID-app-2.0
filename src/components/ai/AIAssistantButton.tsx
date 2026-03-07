import React, { useState } from "react";
import { cn } from "@/lib/utils";
import { MessageCircle } from "lucide-react";
import { AIAssistantSheet } from "./AIAssistantSheet";

const AIAssistantButton: React.FC = () => {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        aria-label="Open AI Assistant"
        onClick={() => setOpen(true)}
        className={cn(
          "fixed z-40 left-4 bottom-[88px] w-12 h-12 rounded-full",
          "glass border border-border",
          "flex items-center justify-center",
          "transition-transform duration-[var(--motion-micro)] ease-[var(--ease-out-expo)]",
          "active:scale-90 hover:scale-105",
          "shadow-[0_0_16px_hsl(var(--neon-indigo)/0.2)]"
        )}
      >
        <MessageCircle className="w-5 h-5 text-neon-cyan" />
      </button>
      <AIAssistantSheet open={open} onOpenChange={setOpen} />
    </>
  );
};

export { AIAssistantButton };
