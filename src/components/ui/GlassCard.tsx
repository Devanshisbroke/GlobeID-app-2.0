import React from "react";
import { motion, type HTMLMotionProps } from "framer-motion";
import { cn } from "@/lib/utils";
import { cardInteraction, spring } from "@/motion/motionConfig";

interface GlassCardProps extends Omit<HTMLMotionProps<"div">, "children"> {
  glow?: boolean;
  neonBorder?: boolean;
  depth?: "sm" | "md" | "lg" | "xl";
  variant?: "default" | "premium" | "ultra";
  interactive?: boolean;
  children: React.ReactNode;
}

const GlassCard = React.forwardRef<HTMLDivElement, GlassCardProps>(
  ({ className, glow, neonBorder, depth = "sm", variant = "default", interactive = true, children, ...props }, ref) => (
    <motion.div
      ref={ref}
      className={cn(
        "rounded-2xl p-4 will-change-transform",
        variant === "default" && "glass glass-shine",
        variant === "premium" && "glass-premium glass-shine",
        variant === "ultra" && "glass-ultra glass-shine",
        depth === "sm" && "shadow-depth-sm",
        depth === "md" && "shadow-depth-md",
        depth === "lg" && "shadow-depth-lg",
        depth === "xl" && "shadow-depth-xl",
        glow && "shadow-glow-md border-gradient",
        neonBorder && "border-gradient",
        interactive && "cursor-pointer",
        className
      )}
      {...(interactive ? cardInteraction : {})}
      transition={spring.card}
      {...props}
    >
      {children}
    </motion.div>
  )
);
GlassCard.displayName = "GlassCard";

export { GlassCard };
