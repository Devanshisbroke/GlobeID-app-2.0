import React from "react";
import { cn } from "@/lib/utils";

interface GlassCardProps extends React.HTMLAttributes<HTMLDivElement> {
  glow?: boolean;
  neonBorder?: boolean;
  depth?: "sm" | "md" | "lg" | "xl";
  variant?: "default" | "premium" | "ultra";
  interactive?: boolean;
  children: React.ReactNode;
}

const GlassCard = React.forwardRef<HTMLDivElement, GlassCardProps>(
  ({ className, glow, neonBorder, depth = "sm", variant = "default", interactive = true, children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        "rounded-2xl p-4",
        variant === "default" && "glass glass-shine",
        variant === "premium" && "glass-premium glass-shine",
        variant === "ultra" && "glass-ultra glass-shine",
        "transition-all duration-[var(--motion-small)] ease-[var(--ease-cinematic)]",
        depth === "sm" && "shadow-depth-sm",
        depth === "md" && "shadow-depth-md",
        depth === "lg" && "shadow-depth-lg",
        depth === "xl" && "shadow-depth-xl",
        glow && "shadow-glow-md border-gradient",
        neonBorder && "border-gradient",
        interactive && "hover:shadow-depth-md active:scale-[0.985]",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
);
GlassCard.displayName = "GlassCard";

export { GlassCard };
