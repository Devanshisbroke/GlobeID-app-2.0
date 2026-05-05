/**
 * <EmptyState /> — first-class empty surface (BACKLOG J 118).
 *
 * Used wherever a list / collection / grid renders zero items. Provides:
 *   - illustrative icon (lucide) at brand-tinted disc
 *   - 1-line title
 *   - optional 1-2 line body
 *   - optional primary CTA button
 *
 * Apple Wallet / Notion empty states inspired the layout: centered,
 * generous vertical padding so the surface doesn't feel "broken", and
 * always *some* affordance for the user to act, never just text.
 */
import React from "react";
import type { LucideIcon } from "lucide-react";
import { motion } from "framer-motion";
import { Surface, Text } from "@/components/ui/v2";
import { cn } from "@/lib/utils";

interface Props {
  icon: LucideIcon;
  title: string;
  body?: string;
  /** Tone for the icon disc background. Default brand. */
  tone?: "brand" | "info" | "success" | "warning" | "muted";
  cta?: {
    label: string;
    onClick: () => void;
    icon?: LucideIcon;
  };
  className?: string;
}

const TONE_CLASS: Record<NonNullable<Props["tone"]>, string> = {
  brand: "bg-brand-soft text-brand",
  info: "bg-state-accent-soft text-state-accent",
  success: "bg-emerald-500/15 text-emerald-300",
  warning: "bg-amber-500/15 text-amber-200",
  muted: "bg-muted text-muted-foreground",
};

const EmptyState: React.FC<Props> = ({
  icon: Icon,
  title,
  body,
  tone = "brand",
  cta,
  className,
}) => {
  return (
    <Surface
      variant="elevated"
      radius="surface"
      className={cn(
        "flex flex-col items-center justify-center text-center px-6 py-10 gap-4",
        className,
      )}
    >
      <motion.span
        aria-hidden
        initial={{ scale: 0.85, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.32, ease: [0.32, 0.72, 0, 1] }}
        className={cn(
          "flex h-14 w-14 items-center justify-center rounded-2xl",
          TONE_CLASS[tone],
        )}
      >
        <Icon className="h-6 w-6" strokeWidth={1.8} />
      </motion.span>
      <div className="space-y-1.5 max-w-sm">
        <Text variant="body-em" tone="primary">
          {title}
        </Text>
        {body ? (
          <Text variant="caption-1" tone="tertiary">
            {body}
          </Text>
        ) : null}
      </div>
      {cta ? (
        <button
          type="button"
          onClick={cta.onClick}
          className="inline-flex items-center gap-2 rounded-full bg-brand px-5 py-2 text-sm font-semibold text-brand-foreground shadow-depth-sm active:scale-[0.97] focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] focus-visible:ring-offset-2"
        >
          {cta.icon ? <cta.icon className="h-4 w-4" strokeWidth={2} /> : null}
          <span>{cta.label}</span>
        </button>
      ) : null}
    </Surface>
  );
};

export default EmptyState;
