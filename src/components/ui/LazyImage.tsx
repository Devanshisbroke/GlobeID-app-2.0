/**
 * <LazyImage /> — image with native lazy-loading + LQIP placeholder
 * (BACKLOG M 148).
 *
 * Wraps `<img>` with:
 *   - `loading="lazy"` and `decoding="async"` for off-screen images.
 *   - An LQIP (low-quality image placeholder) that shows a blurred
 *     thumbnail while the full image loads, then cross-fades on `load`.
 *   - An `onError` fallback that swaps in a tinted block (instead of
 *     the broken-image glyph the browser would render by default).
 *
 * The LQIP can be either:
 *   - A pre-encoded data URI (e.g. base64 32×32 JPG produced by
 *     plaiceholder during build), or
 *   - A solid colour string ("#0d111a"), in which case we fill a div.
 *
 * This is intentionally framework-agnostic — no Next/Image, no
 * optimised CDN, just the platform.
 */
import React, { useState } from "react";
import { cn } from "@/lib/utils";

interface Props extends React.ImgHTMLAttributes<HTMLImageElement> {
  src: string;
  alt: string;
  /** Either a data URI for the blurred placeholder or a solid colour. */
  lqip?: string;
  /** Tailwind-friendly class for the rounded container. */
  className?: string;
  /** Custom fallback when the image fails to load. */
  fallback?: React.ReactNode;
  /** Aspect ratio (width / height) to reserve layout space. */
  aspect?: number;
}

const LazyImage: React.FC<Props> = ({
  src,
  alt,
  lqip,
  className,
  fallback,
  aspect = 16 / 9,
  ...rest
}) => {
  const [loaded, setLoaded] = useState(false);
  const [errored, setErrored] = useState(false);

  const isDataUri = lqip?.startsWith("data:");
  const placeholderStyle: React.CSSProperties = lqip
    ? isDataUri
      ? {
          backgroundImage: `url(${lqip})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          filter: "blur(20px)",
          transform: "scale(1.1)",
        }
      : { backgroundColor: lqip }
    : { backgroundColor: "hsl(var(--muted))" };

  return (
    <div
      className={cn("relative overflow-hidden", className)}
      style={{ aspectRatio: String(aspect) }}
    >
      {!loaded && !errored ? (
        <div
          aria-hidden
          className="absolute inset-0"
          style={placeholderStyle}
        />
      ) : null}
      {errored ? (
        fallback ?? (
          <div className="absolute inset-0 flex items-center justify-center bg-muted text-muted-foreground text-xs">
            Image unavailable
          </div>
        )
      ) : (
        <img
          src={src}
          alt={alt}
          loading="lazy"
          decoding="async"
          onLoad={() => setLoaded(true)}
          onError={() => setErrored(true)}
          className={cn(
            "absolute inset-0 h-full w-full object-cover transition-opacity duration-500",
            loaded ? "opacity-100" : "opacity-0",
          )}
          {...rest}
        />
      )}
    </div>
  );
};

export default LazyImage;
