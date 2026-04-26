import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

/**
 * Pill — small, dense label / status / tag.
 *
 * Three weights of visual presence:
 *  - `solid`   — filled background, used for status (e.g. `Active`, `Live`).
 *  - `tinted`  — soft brand/accent/critical fill (10–16% alpha). Default.
 *  - `outline` — hairline border only. For inert tags / metadata.
 *
 * Color tone selects the semantic. `neutral` defaults to ink-secondary on
 * surface-overlay and is the right choice for non-status metadata
 * (e.g. trip duration, seat number, currency code).
 *
 * Pills are inline-block by default so they sit on a baseline next to text.
 */

const pillCva = cva(
  [
    "inline-flex items-center gap-1",
    "px-2 py-0.5 rounded-p7-chip",
    "text-p7-caption-2 font-medium tracking-[0.02em]",
    "select-none",
  ].join(" "),
  {
    variants: {
      tone: {
        neutral: "",
        brand: "",
        accent: "",
        warning: "",
        critical: "",
      },
      weight: {
        solid: "",
        tinted: "",
        outline: "",
      },
    },
    compoundVariants: [
      // Tinted (default) — soft fill + saturated text
      { tone: "neutral", weight: "tinted", className: "bg-surface-overlay text-ink-secondary" },
      { tone: "brand",   weight: "tinted", className: "bg-brand-soft text-brand" },
      { tone: "accent",  weight: "tinted", className: "bg-state-accent-soft text-state-accent" },
      { tone: "warning", weight: "tinted", className: "bg-[hsl(var(--p7-warning-soft))] text-[hsl(var(--p7-warning))]" },
      { tone: "critical",weight: "tinted", className: "bg-critical-soft text-critical" },
      // Solid — saturated bg + on-brand ink
      { tone: "neutral", weight: "solid",  className: "bg-ink-secondary text-surface-base" },
      { tone: "brand",   weight: "solid",  className: "bg-brand text-ink-on-brand" },
      { tone: "accent",  weight: "solid",  className: "bg-state-accent text-ink-on-brand" },
      { tone: "warning", weight: "solid",  className: "bg-[hsl(var(--p7-warning))] text-ink-on-brand" },
      { tone: "critical",weight: "solid",  className: "bg-critical text-ink-on-brand" },
      // Outline — hairline + tone-tinted text
      { tone: "neutral", weight: "outline", className: "border border-surface-hairline text-ink-secondary" },
      { tone: "brand",   weight: "outline", className: "border border-brand text-brand" },
      { tone: "accent",  weight: "outline", className: "border border-state-accent text-state-accent" },
      { tone: "warning", weight: "outline", className: "border border-[hsl(var(--p7-warning))] text-[hsl(var(--p7-warning))]" },
      { tone: "critical",weight: "outline", className: "border border-critical text-critical" },
    ],
    defaultVariants: {
      tone: "neutral",
      weight: "tinted",
    },
  },
);

export type PillProps = React.HTMLAttributes<HTMLSpanElement> &
  VariantProps<typeof pillCva> & {
    /** Optional dot indicator (animated when `pulse`). */
    dot?: boolean;
    /** Pulse the dot — used for live / active states. */
    pulse?: boolean;
  };

export const Pill = React.forwardRef<HTMLSpanElement, PillProps>(
  ({ className, tone, weight, dot, pulse, children, ...rest }, ref) => {
    return (
      <span
        ref={ref}
        className={cn(pillCva({ tone, weight }), className)}
        {...rest}
      >
        {dot ? (
          <span className="relative flex h-1.5 w-1.5 shrink-0">
            {pulse ? (
              <span className="absolute inset-0 animate-ping rounded-full bg-current opacity-60" />
            ) : null}
            <span className="relative h-1.5 w-1.5 rounded-full bg-current" />
          </span>
        ) : null}
        {children}
      </span>
    );
  },
);
Pill.displayName = "Pill";
