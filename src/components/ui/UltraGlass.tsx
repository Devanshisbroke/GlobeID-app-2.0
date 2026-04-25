import React from "react";
import { motion, type HTMLMotionProps } from "framer-motion";
import { cn } from "@/lib/utils";
import { cinematicCard } from "@/cinematic/motionEngine";
import { useReducedEffects } from "@/hooks/useReducedEffects";

interface UltraGlassProps extends Omit<HTMLMotionProps<"div">, "children"> {
  children: React.ReactNode;
  /** Depth layer level (1 = surface, 2 = elevated). depth=3 removed in Phase 5 PR-α. */
  depth?: 1 | 2;
  /** @deprecated removed in Phase 5 PR-α (perceived-noise win). Prop preserved for API compat. */
  lightSweep?: boolean;
  /** @deprecated removed in Phase 5 PR-α. Prop preserved for API compat. */
  edgeHighlight?: boolean;
  /** Interactive hover/tap */
  interactive?: boolean;
  className?: string;
}

/**
 * UltraGlass — layered glass surface.
 *
 * Phase 5 PR-α: stripped of `lightSweep`, `edgeHighlight`, and `depth=3`.
 * The component now renders a single calm glass with one inner shine.
 * Old props are accepted (no-op) so callers don't need to change.
 */
const UltraGlass = React.forwardRef<HTMLDivElement, UltraGlassProps>(
  ({ children, depth = 1, interactive = true, className, lightSweep: _lightSweep, edgeHighlight: _edgeHighlight, ...props }, ref) => {
    const reduced = useReducedEffects();
    const blurValue = reduced
      ? (depth === 1 ? 16 : 22)
      : (depth === 1 ? 20 : 28);
    const bgOpacity = depth === 1 ? 0.7 : 0.6;

    return (
      <motion.div
        ref={ref}
        className={cn(
          "relative rounded-2xl overflow-hidden will-change-transform",
          interactive && "cursor-pointer",
          className
        )}
        style={{
          background: `linear-gradient(145deg, hsl(var(--card) / ${bgOpacity + 0.12}) 0%, hsl(var(--card) / ${bgOpacity}) 100%)`,
          border: "1px solid hsl(var(--glass-border))",
          backdropFilter: `blur(${blurValue}px) saturate(1.3)`,
          WebkitBackdropFilter: `blur(${blurValue}px) saturate(1.3)`,
          boxShadow: `var(--shadow-${depth === 1 ? "md" : "lg"})`,
        }}
        {...(interactive ? cinematicCard : {})}
        {...props}
      >
        {/* Single inner shine — no light-sweep, no edge gradient, no radial overlay */}
        <div
          className="absolute inset-0 pointer-events-none rounded-[inherit]"
          style={{
            background: "linear-gradient(135deg, hsl(var(--glass-shine)) 0%, transparent 40%)",
          }}
        />

        <div className="relative z-10 p-4">{children}</div>
      </motion.div>
    );
  }
);

UltraGlass.displayName = "UltraGlass";

export { UltraGlass };
