import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

/**
 * Text — typography primitive matching the 9-token type scale.
 *
 * Each variant carries pre-tuned size, line-height, tracking, AND weight
 * so a single class name (`<Text variant="title-1">`) communicates the
 * full type intent. This is the antidote to the Phase 5/6 problem of
 * stacking `text-sm font-semibold tracking-tight leading-snug` on every
 * heading.
 *
 * Tone selects ink hierarchy: `primary` (default) → `secondary` →
 * `tertiary`, with semantic tones (`brand`, `accent`, `warning`,
 * `critical`) for status copy.
 *
 * Element defaults to a sensible HTML tag per variant; override with
 * `as` for semantic correctness when nested.
 */

const textCva = cva("font-sans", {
  variants: {
    variant: {
      display: "text-p7-display [font-optical-sizing:auto]",
      "title-1": "text-p7-title-1 [font-optical-sizing:auto]",
      "title-2": "text-p7-title-2",
      "title-3": "text-p7-title-3",
      body: "text-p7-body",
      "body-em": "text-p7-body-em",
      callout: "text-p7-callout",
      "caption-1": "text-p7-caption-1",
      "caption-2": "text-p7-caption-2",
      mono: "font-mono text-p7-callout tracking-tight",
    },
    tone: {
      primary: "text-ink-primary",
      secondary: "text-ink-secondary",
      tertiary: "text-ink-tertiary",
      brand: "text-brand",
      accent: "text-state-accent",
      warning: "text-[hsl(var(--p7-warning))]",
      critical: "text-critical",
      "on-brand": "text-ink-on-brand",
    },
    align: {
      start: "text-left",
      center: "text-center",
      end: "text-right",
    },
    truncate: {
      true: "truncate",
      false: "",
    },
  },
  defaultVariants: {
    variant: "body",
    tone: "primary",
    truncate: false,
  },
});

const defaultElement: Record<
  NonNullable<VariantProps<typeof textCva>["variant"]>,
  keyof React.JSX.IntrinsicElements
> = {
  display: "h1",
  "title-1": "h1",
  "title-2": "h2",
  "title-3": "h3",
  body: "p",
  "body-em": "p",
  callout: "p",
  "caption-1": "span",
  "caption-2": "span",
  mono: "span",
};

export type TextProps = React.HTMLAttributes<HTMLElement> &
  VariantProps<typeof textCva> & {
    as?: keyof React.JSX.IntrinsicElements;
  };

export const Text = React.forwardRef<HTMLElement, TextProps>(
  ({ className, variant, tone, align, truncate, as, ...rest }, ref) => {
    const Comp = (as ??
      defaultElement[variant ?? "body"] ??
      "p") as keyof React.JSX.IntrinsicElements;
    return React.createElement(Comp, {
      ref,
      className: cn(textCva({ variant, tone, align, truncate }), className),
      ...rest,
    });
  },
);
Text.displayName = "Text";
