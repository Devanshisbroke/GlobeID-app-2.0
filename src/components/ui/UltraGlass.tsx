import React from "react";
import { motion, type HTMLMotionProps } from "framer-motion";
import { cn } from "@/lib/utils";
import { cinematicCard, cinematicEase, cinematicDuration } from "@/cinematic/motionEngine";

interface UltraGlassProps extends Omit<HTMLMotionProps<"div">, "children"> {
  children: React.ReactNode;
  /** Depth layer level */
  depth?: 1 | 2 | 3;
  /** Enable animated light sweep */
  lightSweep?: boolean;
  /** Enable gradient edge highlights */
  edgeHighlight?: boolean;
  /** Interactive hover/tap */
  interactive?: boolean;
  className?: string;
}

const UltraGlass = React.forwardRef<HTMLDivElement, UltraGlassProps>(
  ({ children, depth = 1, lightSweep = true, edgeHighlight = false, interactive = true, className, ...props }, ref) => {
    const blurValue = depth === 1 ? 24 : depth === 2 ? 32 : 40;
    const bgOpacity = depth === 1 ? 0.7 : depth === 2 ? 0.6 : 0.5;

    return (
      <motion.div
        ref={ref}
        className={cn(
          "relative rounded-2xl overflow-hidden will-change-transform",
          interactive && "cursor-pointer",
          className
        )}
        style={{
          background: `linear-gradient(145deg, hsl(var(--card) / ${bgOpacity + 0.15}) 0%, hsl(var(--card) / ${bgOpacity}) 50%, hsl(var(--card) / ${bgOpacity + 0.08}) 100%)`,
          border: "1px solid hsl(var(--glass-border))",
          backdropFilter: `blur(${blurValue}px) saturate(${1.2 + depth * 0.2})`,
          WebkitBackdropFilter: `blur(${blurValue}px) saturate(${1.2 + depth * 0.2})`,
          boxShadow: `var(--shadow-${depth === 1 ? "md" : depth === 2 ? "lg" : "xl"})`,
        }}
        {...(interactive ? cinematicCard : {})}
        {...props}
      >
        {/* Internal glass reflection */}
        <div
          className="absolute inset-0 pointer-events-none rounded-[inherit]"
          style={{
            background: "linear-gradient(135deg, hsl(var(--glass-shine)) 0%, transparent 40%)",
          }}
        />

        {/* Depth blur layer */}
        {depth >= 2 && (
          <div
            className="absolute inset-0 pointer-events-none rounded-[inherit]"
            style={{
              background: `radial-gradient(ellipse at 50% 0%, hsl(var(--primary) / ${0.02 * depth}) 0%, transparent 60%)`,
            }}
          />
        )}

        {/* Gradient edge highlights */}
        {edgeHighlight && (
          <div
            className="absolute inset-0 pointer-events-none rounded-[inherit]"
            style={{
              background: "linear-gradient(135deg, hsl(var(--blue-start) / 0.06) 0%, transparent 30%, transparent 70%, hsl(var(--tropical-start) / 0.04) 100%)",
            }}
          />
        )}

        {/* Animated light sweep */}
        {lightSweep && (
          <motion.div
            className="absolute inset-0 pointer-events-none rounded-[inherit]"
            style={{
              background: "linear-gradient(115deg, transparent 30%, hsl(0 0% 100% / 0.03) 45%, hsl(0 0% 100% / 0.06) 50%, hsl(0 0% 100% / 0.03) 55%, transparent 70%)",
              backgroundSize: "250% 100%",
            }}
            animate={{ backgroundPosition: ["-100% 0%", "250% 0%"] }}
            transition={{ duration: 6, repeat: Infinity, ease: "linear", repeatDelay: 3 }}
          />
        )}

        {/* Content */}
        <div className="relative z-10 p-4">{children}</div>
      </motion.div>
    );
  }
);

UltraGlass.displayName = "UltraGlass";

export { UltraGlass };
