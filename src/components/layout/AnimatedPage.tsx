import React from "react";
import { cn } from "@/lib/utils";
import { staggerDelay } from "@/hooks/useMotion";

interface AnimatedPageProps {
  children: React.ReactNode;
  className?: string;
  staggerIndex?: number;
}

const AnimatedPage: React.FC<AnimatedPageProps> = ({
  children,
  className,
  staggerIndex,
}) => (
  <div
    className={cn("animate-fade-in", className)}
    style={
      staggerIndex !== undefined
        ? { animationDelay: staggerDelay(staggerIndex) }
        : undefined
    }
  >
    {children}
  </div>
);

export { AnimatedPage };
