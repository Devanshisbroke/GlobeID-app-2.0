import React, { useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Scan, CreditCard } from "lucide-react";

const FAB: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [pressed, setPressed] = useState(false);

  if (location.pathname === "/lock") return null;

  const isWallet = location.pathname === "/wallet";
  const Icon = isWallet ? CreditCard : Scan;
  const label = isWallet ? "Quick Pay" : "Quick Scan";

  return (
    <button
      aria-label={label}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      onClick={() => navigate(isWallet ? "/wallet" : "/identity")}
      className={cn(
        "fixed z-50 right-4 bottom-[88px] w-14 h-14 rounded-full",
        "flex items-center justify-center",
        "bg-gradient-to-br from-neon-indigo via-neon-cyan to-neon-teal",
        "shadow-glow-lg",
        "transition-all duration-[var(--motion-micro)] ease-[var(--ease-cinematic)]",
        "active:scale-90",
        pressed ? "scale-90 shadow-glow-sm" : "scale-100"
      )}
    >
      <Icon className="w-6 h-6 text-primary-foreground" />
    </button>
  );
};

export { FAB };
