import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { motion, type HTMLMotionProps } from "motion/react";
import { cn } from "@/lib/utils";
import { spring } from "@/lib/motion-tokens";

/**
 * Button — primary tactile primitive.
 *
 *  - 5 variants ×  3 sizes covers >95 % of in-app press targets.
 *  - Spring-physics tap response (`spring.snap`) replaces the default
 *    duration-based transition. This is what gives the press a "physical"
 *    feel without any visible animation noise.
 *  - The default `<button>` element accepts `asChild` so Buttons can wrap
 *    `<a>` / `<Link>` without losing semantics.
 *  - Loading state uses an inline spinner glyph; the underlying button
 *    is disabled but keeps its width so layout doesn't jump.
 *  - Focus ring uses `--p7-ring` and respects `--p7-ring-offset` for
 *    on-base contrast in both themes.
 */

const buttonCva = cva(
  [
    "relative inline-flex items-center justify-center gap-2",
    "select-none whitespace-nowrap font-sans",
    "outline-none transition-colors",
    "focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
    "focus-visible:ring-offset-2 focus-visible:ring-offset-[hsl(var(--p7-ring-offset))]",
    "disabled:opacity-50 disabled:pointer-events-none",
  ].join(" "),
  {
    variants: {
      variant: {
        primary: [
          "bg-brand text-ink-on-brand",
          "hover:bg-brand-strong",
          "shadow-p7-sm",
        ].join(" "),
        secondary: [
          "bg-surface-overlay text-ink-primary",
          "border border-surface-hairline",
          "hover:bg-surface-elevated",
        ].join(" "),
        ghost: [
          "bg-transparent text-ink-primary",
          "hover:bg-surface-overlay",
        ].join(" "),
        subtle: [
          "bg-brand-soft text-brand",
          "hover:bg-brand-soft hover:brightness-105",
        ].join(" "),
        critical: [
          "bg-critical text-ink-on-brand",
          "hover:bg-critical hover:brightness-110",
          "shadow-p7-sm",
        ].join(" "),
      },
      size: {
        sm: "h-8 px-3 rounded-p7-input text-p7-callout",
        md: "h-10 px-4 rounded-p7-input text-p7-body-em",
        lg: "h-12 px-5 rounded-p7-input text-p7-body-em",
        icon: "h-10 w-10 rounded-p7-input",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  },
);

export type ButtonProps = Omit<HTMLMotionProps<"button">, "ref"> &
  VariantProps<typeof buttonCva> & {
    asChild?: boolean;
    /** Inline spinner; preserves layout width so the button doesn't jump. */
    loading?: boolean;
    /** Glyph rendered before the label. */
    leading?: React.ReactNode;
    /** Glyph rendered after the label. */
    trailing?: React.ReactNode;
  };

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      className,
      variant,
      size,
      asChild = false,
      loading = false,
      leading,
      trailing,
      children,
      disabled,
      ...rest
    },
    ref,
  ) => {
    // When `asChild`, we lose the motion wrapper (a Slot can only have one
    // child element). The trade-off: rendering a Link / anchor is more
    // important than the press animation in those cases (browser native
    // active state still applies).
    if (asChild) {
      return (
        <Slot
          className={cn(buttonCva({ variant, size }), className)}
          ref={ref as React.Ref<HTMLElement>}
          {...(rest as React.HTMLAttributes<HTMLElement>)}
        >
          {children}
        </Slot>
      );
    }
    return (
      <motion.button
        ref={ref}
        whileTap={loading || disabled ? undefined : { scale: 0.97 }}
        transition={spring.snap}
        className={cn(buttonCva({ variant, size }), className)}
        disabled={disabled || loading}
        {...rest}
      >
        {loading ? (
          <SpinnerGlyph />
        ) : leading ? (
          <span className="shrink-0 [&>svg]:h-4 [&>svg]:w-4">{leading}</span>
        ) : null}
        {children !== undefined && <span className="truncate">{children}</span>}
        {trailing && !loading ? (
          <span className="shrink-0 [&>svg]:h-4 [&>svg]:w-4">{trailing}</span>
        ) : null}
      </motion.button>
    );
  },
);
Button.displayName = "Button";

function SpinnerGlyph() {
  return (
    <span
      aria-hidden
      className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
    />
  );
}
