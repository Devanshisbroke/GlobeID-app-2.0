/**
 * Deterministic initials avatar — used as a fallback when an image
 * URL fails to load (avatars, hotel images, airline logos). Same
 * input → same colour, so the user sees a stable visual anchor for
 * each entity rather than a blank square.
 *
 * Hash: a tiny djb2 over the input string → HSL hue. Saturation /
 * lightness pinned for legibility on both light and dark themes.
 */
import React from "react";
import { cn } from "@/lib/utils";

export interface InitialsAvatarProps {
  /** Display name or any stable id. Used for both initials + colour. */
  name: string;
  /** Optional remote image — when provided, we render an <img> with a
   *  built-in onError fallback to the initials gradient. */
  src?: string | null;
  className?: string;
  /** Visual diameter; defaults to size-9 (36 px). */
  size?: number;
  /** When true, force the initials gradient and ignore `src`. */
  forceFallback?: boolean;
}

function hash(str: string): number {
  let h = 5381;
  for (let i = 0; i < str.length; i++) {
    h = ((h << 5) + h + str.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

function initials(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return "?";
  const parts = trimmed.split(/\s+/u).filter(Boolean);
  if (parts.length === 1) return parts[0]!.slice(0, 2).toUpperCase();
  return ((parts[0]![0] ?? "") + (parts[parts.length - 1]![0] ?? "")).toUpperCase();
}

const InitialsAvatar: React.FC<InitialsAvatarProps> = ({
  name,
  src,
  className,
  size = 36,
  forceFallback = false,
}) => {
  const [errored, setErrored] = React.useState(false);
  const useImage = !forceFallback && src && !errored;
  const hue = hash(name) % 360;
  const style: React.CSSProperties = useImage
    ? { width: size, height: size }
    : {
        width: size,
        height: size,
        background: `linear-gradient(135deg, hsl(${hue}, 65%, 55%), hsl(${(hue + 30) % 360}, 70%, 45%))`,
      };

  if (useImage) {
    return (
      <img
        src={src ?? undefined}
        alt={name}
        loading="lazy"
        onError={() => setErrored(true)}
        className={cn(
          "rounded-full object-cover",
          className,
        )}
        style={style}
      />
    );
  }

  return (
    <div
      role="img"
      aria-label={name}
      className={cn(
        "inline-flex items-center justify-center rounded-full font-semibold text-white shadow-inner",
        className,
      )}
      style={style}
    >
      <span style={{ fontSize: Math.round(size * 0.4) }}>{initials(name)}</span>
    </div>
  );
};

export default InitialsAvatar;
