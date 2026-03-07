import React from "react";
import { cn } from "@/lib/utils";

interface GlassCardProps extends React.HTMLAttributes<HTMLDivElement> {
  glow?: boolean;
  neonBorder?: boolean;
  children: React.ReactNode;
}

const GlassCard = React.forwardRef<HTMLDivElement, GlassCardProps>(
  ({ className, glow, neonBorder, children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        "glass glass-shine rounded-2xl p-4 transition-transform duration-[var(--motion-micro)]",
        glow && "neon-glow",
        neonBorder && "border-gradient",
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
