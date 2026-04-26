import * as React from "react";
import * as AvatarPrimitive from "@radix-ui/react-avatar";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

/**
 * Avatar — circular profile mark.
 *
 * Built on `@radix-ui/react-avatar` so loading state (image → fallback)
 * is handled correctly without flash. Initials fallback uses the
 * tinted-brand background; a 1px hairline border holds the avatar
 * crisp on glass surfaces (otherwise the edge feathers in WebView).
 */

const avatarCva = cva(
  "relative inline-flex shrink-0 overflow-hidden rounded-full border border-surface-hairline bg-brand-soft",
  {
    variants: {
      size: {
        xs: "h-6 w-6 text-p7-caption-2",
        sm: "h-8 w-8 text-p7-caption-1",
        md: "h-10 w-10 text-p7-callout",
        lg: "h-12 w-12 text-p7-body-em",
        xl: "h-16 w-16 text-p7-title-3",
      },
    },
    defaultVariants: {
      size: "md",
    },
  },
);

export type AvatarProps = React.ComponentPropsWithoutRef<
  typeof AvatarPrimitive.Root
> &
  VariantProps<typeof avatarCva> & {
    /** URL for the image. If absent or fails, falls back to initials. */
    src?: string;
    alt?: string;
    /** Initials override; otherwise derived from `alt`. */
    initials?: string;
  };

function deriveInitials(input?: string): string {
  if (!input) return "·";
  const parts = input
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2);
  if (parts.length === 0) return "·";
  return parts.map((p) => p[0]?.toUpperCase() ?? "").join("");
}

export const Avatar = React.forwardRef<
  React.ComponentRef<typeof AvatarPrimitive.Root>,
  AvatarProps
>(({ className, size, src, alt, initials, ...rest }, ref) => {
  return (
    <AvatarPrimitive.Root
      ref={ref}
      className={cn(avatarCva({ size }), className)}
      {...rest}
    >
      {src ? (
        <AvatarPrimitive.Image
          src={src}
          alt={alt ?? ""}
          className="h-full w-full object-cover"
        />
      ) : null}
      <AvatarPrimitive.Fallback
        delayMs={src ? 200 : 0}
        className="flex h-full w-full items-center justify-center font-medium text-brand"
      >
        {initials ?? deriveInitials(alt)}
      </AvatarPrimitive.Fallback>
    </AvatarPrimitive.Root>
  );
});
Avatar.displayName = "Avatar";
