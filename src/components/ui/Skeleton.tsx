/**
 * Lightweight skeleton primitives used across first-load empty states.
 *
 * Honours `prefers-reduced-motion` — when reduced motion is set the
 * shimmer animation is dropped in favour of a flat tinted block. The
 * shimmer uses a CSS keyframe defined in `index.css` (`globeid-shimmer`)
 * so DOM count stays low (no extra child element per skeleton).
 */
import React from "react";
import { cn } from "@/lib/utils";

export interface SkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Optional explicit width. */
  w?: number | string;
  /** Optional explicit height. */
  h?: number | string;
  /** When true, drop the rounded corners (e.g. for a single line). */
  square?: boolean;
}

export const Skeleton: React.FC<SkeletonProps> = ({
  className,
  w,
  h,
  square,
  style,
  ...rest
}) => {
  const finalStyle: React.CSSProperties = {
    ...style,
    width: w,
    height: h,
  };
  return (
    <div
      aria-hidden
      className={cn(
        "globeid-skeleton bg-muted/60",
        square ? "" : "rounded-xl",
        className,
      )}
      style={finalStyle}
      {...rest}
    />
  );
};

/** Pre-shaped skeleton tile that matches a typical wallet pass card. */
export const PassSkeleton: React.FC = () => (
  <div className="space-y-3">
    <Skeleton h={180} className="rounded-[22px]" />
    <div className="flex gap-2">
      <Skeleton w="60%" h={14} />
      <Skeleton w="20%" h={14} />
    </div>
  </div>
);

/** Trip card skeleton — 3 lines + footer chip. */
export const TripSkeleton: React.FC = () => (
  <div className="rounded-2xl border border-border bg-card p-4 space-y-2.5">
    <div className="flex items-center gap-3">
      <Skeleton w={36} h={36} className="rounded-xl" />
      <div className="flex-1 space-y-1.5">
        <Skeleton w="55%" h={12} />
        <Skeleton w="35%" h={10} />
      </div>
    </div>
    <Skeleton w="100%" h={10} />
    <Skeleton w="80%" h={10} />
  </div>
);
