import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

/**
 * Surface — the foundational visual layer of the v2 system.
 *
 * Three variants map to the three surface tiers locked in PR-α:
 *  - `plain`     — base canvas with hairline border. Most cards / list groups.
 *  - `elevated`  — pure white (light) / graphite-rise (dark) + soft shadow.
 *                  Used when an element needs to lift off the base.
 *  - `glass`     — backdrop blur + tint. **Reserved for chrome only**
 *                  (top status bar, bottom nav, command palette overlay).
 *                  Do NOT use glass for general cards — that was the
 *                  Phase 5/6 mistake (96 ad-hoc `.glass*` usages flagged
 *                  in the audit). The whole point of restricting it is
 *                  that "everything is glass" reads as "nothing is glass".
 *
 * Surfaces are radius-aware via the `radius` prop. Padding is intentionally
 * NOT a Surface concern — wrap a Surface around content and pad the
 * content. This keeps Surface a pure visual primitive.
 */

const surfaceCva = cva(
  // Base — every surface gets crisp text rendering and respects focus rings
  // when a child consumes them.
  "relative",
  {
    variants: {
      variant: {
        plain:
          "bg-surface-base text-ink-primary border border-surface-hairline",
        elevated:
          "bg-surface-elevated text-ink-primary border border-surface-hairline shadow-p7-md",
        glass:
          // `--p7-glass-tint` already encodes the right HSL+alpha for both themes.
          // Saturate boost (1.4) compensates for the visual desaturation that
          // mobile WebView applies to `backdrop-filter`.
          "border border-surface-hairline shadow-p7-md " +
          "bg-[hsl(var(--p7-glass-tint))] " +
          "[backdrop-filter:blur(var(--p7-glass-blur))_saturate(1.4)] " +
          "[-webkit-backdrop-filter:blur(var(--p7-glass-blur))_saturate(1.4)]",
        flush:
          // Used inside groups (List, Tabs) where the parent owns the surface.
          "bg-transparent text-ink-primary",
      },
      radius: {
        none: "rounded-none",
        chip: "rounded-p7-chip",
        input: "rounded-p7-input",
        surface: "rounded-p7-surface",
        sheet: "rounded-p7-sheet",
        full: "rounded-full",
      },
    },
    defaultVariants: {
      variant: "plain",
      radius: "surface",
    },
  },
);

export type SurfaceProps = React.HTMLAttributes<HTMLDivElement> &
  VariantProps<typeof surfaceCva> & {
    asChild?: boolean;
  };

export const Surface = React.forwardRef<HTMLDivElement, SurfaceProps>(
  ({ className, variant, radius, asChild = false, ...rest }, ref) => {
    const Comp = asChild ? Slot : "div";
    return (
      <Comp
        ref={ref}
        className={cn(surfaceCva({ variant, radius }), className)}
        {...rest}
      />
    );
  },
);
Surface.displayName = "Surface";
