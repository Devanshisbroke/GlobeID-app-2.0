import React from "react";
import { cn } from "@/lib/utils";

interface GlassCardProps extends React.HTMLAttributes<HTMLDivElement> {
  glow?: boolean;
  neonBorder?: boolean;
  depth?: "sm" | "md" | "lg";
  children: React.ReactNode;
}

const GlassCard = React.forwardRef<HTMLDivElement, GlassCardProps>(
  ({ className, glow, neonBorder, depth = "sm", children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        "glass glass-shine rounded-2xl p-4",
        "transition-all duration-[var(--motion-small)] ease-[var(--ease-cinematic)]",
        depth === "sm" && "shadow-depth-sm",
        depth === "md" && "shadow-depth-md",
        depth === "lg" && "shadow-depth-lg",
        glow && "shadow-glow-md border-gradient",
        neonBorder && "border-gradient",
        "hover:shadow-depth-md active:scale-[0.985]",
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
