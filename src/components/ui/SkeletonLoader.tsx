import React from "react";
import { cn } from "@/lib/utils";

interface SkeletonLoaderProps {
  className?: string;
  variant?: "text" | "card" | "circle" | "rect";
  lines?: number;
}

const SkeletonLoader: React.FC<SkeletonLoaderProps> = ({ className, variant = "rect", lines = 1 }) => {
  if (variant === "card") {
    return (
      <div className={cn("rounded-2xl p-4 space-y-3 glass", className)}>
        <div className="h-4 w-2/3 rounded-lg bg-muted shimmer-loading" />
        <div className="h-3 w-full rounded-lg bg-muted/60 shimmer-loading" style={{ animationDelay: "100ms" }} />
        <div className="h-3 w-4/5 rounded-lg bg-muted/60 shimmer-loading" style={{ animationDelay: "200ms" }} />
        <div className="flex gap-2 pt-1">
          <div className="h-8 flex-1 rounded-lg bg-muted/40 shimmer-loading" style={{ animationDelay: "300ms" }} />
          <div className="h-8 flex-1 rounded-lg bg-muted/40 shimmer-loading" style={{ animationDelay: "400ms" }} />
        </div>
      </div>
    );
  }

  if (variant === "circle") {
    return <div className={cn("w-12 h-12 rounded-full bg-muted shimmer-loading", className)} />;
  }

  if (variant === "text") {
    return (
      <div className={cn("space-y-2", className)}>
        {Array.from({ length: lines }).map((_, i) => (
          <div
            key={i}
            className="h-3 rounded-lg bg-muted/60 shimmer-loading"
            style={{
              width: i === lines - 1 ? "60%" : "100%",
              animationDelay: `${i * 80}ms`,
            }}
          />
        ))}
      </div>
    );
  }

  return <div className={cn("h-12 rounded-xl bg-muted shimmer-loading", className)} />;
};

export { SkeletonLoader };
