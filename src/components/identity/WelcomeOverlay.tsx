import React, { useEffect, useState, useCallback } from "react";
import { cn } from "@/lib/utils";
import { getCountryTheme } from "@/lib/countryThemes";
import { useMotion } from "@/hooks/useMotion";

interface WelcomeOverlayProps {
  countryCode: string;
  onComplete: () => void;
}

const WelcomeOverlay: React.FC<WelcomeOverlayProps> = ({ countryCode, onComplete }) => {
  const theme = getCountryTheme(countryCode);
  const { prefersReducedMotion } = useMotion();
  const [phase, setPhase] = useState<"flag" | "sweep" | "text" | "exit" | "done">("flag");

  const advance = useCallback(() => {
    if (prefersReducedMotion) {
      // Skip animation — show static then dismiss
      setTimeout(onComplete, 1200);
      return;
    }

    // flag: 300ms → sweep: 250ms → text: 280ms → hold 1500ms → exit: 320ms
    setTimeout(() => setPhase("sweep"), 300);
    setTimeout(() => setPhase("text"), 550);
    setTimeout(() => setPhase("exit"), 2800);
    setTimeout(() => {
      setPhase("done");
      onComplete();
    }, 3120);
  }, [prefersReducedMotion, onComplete]);

  useEffect(() => {
    advance();
  }, [advance]);

  if (phase === "done") return null;

  if (prefersReducedMotion) {
    return (
      <div className="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-background/95">
        <span className="text-6xl mb-4">{theme.flag}</span>
        <h2 className="text-xl font-bold text-foreground">{theme.greeting}</h2>
        <p className="text-sm text-muted-foreground mt-1">{theme.greetingLocal}</p>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-background/95 overflow-hidden">
      {/* Flag reveal */}
      <div
        className={cn(
          "transition-all ease-[cubic-bezier(0.22,1,0.36,1)]",
          phase === "flag" && "scale-0 opacity-0",
          phase !== "flag" && "scale-100 opacity-100"
        )}
        style={{ transitionDuration: "300ms" }}
      >
        <span className="text-8xl block">{theme.flag}</span>
      </div>

      {/* Light sweep */}
      <div
        className={cn(
          "absolute inset-0 pointer-events-none transition-opacity",
          phase === "sweep" || phase === "text" ? "opacity-60" : "opacity-0"
        )}
        style={{
          transitionDuration: "250ms",
          background: `linear-gradient(135deg, transparent 30%, hsl(${theme.accentHsl} / 0.15) 50%, transparent 70%)`,
        }}
      />

      {/* Text */}
      <div
        className={cn(
          "mt-6 text-center transition-all ease-[cubic-bezier(0.22,1,0.36,1)]",
          (phase === "text" || phase === "exit") ? "opacity-100 translate-y-0" : "opacity-0 translate-y-2"
        )}
        style={{ transitionDuration: "280ms" }}
      >
        <h2 className="text-2xl font-bold text-foreground">{theme.greeting}</h2>
        <p className="text-sm text-muted-foreground mt-1">{theme.greetingLocal}</p>
        <div className="flex items-center justify-center gap-2 mt-3 text-xs text-muted-foreground">
          <span>💰 {theme.currency} enabled</span>
          <span>•</span>
          <span>🌐 Local services available</span>
        </div>
      </div>

      {/* Exit fade */}
      {phase === "exit" && (
        <div
          className="absolute inset-0 bg-background transition-opacity duration-300"
          style={{ opacity: 1 }}
        />
      )}
    </div>
  );
};

export default WelcomeOverlay;
