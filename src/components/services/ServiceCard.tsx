import React from "react";
import { ChevronRight } from "lucide-react";
import { Surface, Text } from "@/components/ui/v2";
import { cn } from "@/lib/utils";

interface ServiceCardProps {
  title: string;
  description: string;
  icon: React.ReactNode;
  /**
   * Tone halo behind the icon. Defaults to a neutral brand-soft halo.
   * Pass `accent` for trip-related services, `warning` for high-attention
   * concierge actions, etc.
   */
  tone?: "brand" | "accent" | "warning" | "critical" | "neutral";
  onAction?: () => void;
  className?: string;
}

const TONE_HALO: Record<NonNullable<ServiceCardProps["tone"]>, string> = {
  brand: "bg-brand-soft text-brand",
  accent: "bg-state-accent-soft text-state-accent",
  warning: "bg-[hsl(var(--p7-warning-soft))] text-[hsl(var(--p7-warning))]",
  critical: "bg-critical-soft text-critical",
  neutral: "bg-surface-overlay text-ink-secondary",
};

const ServiceCard: React.FC<ServiceCardProps> = ({
  title,
  description,
  icon,
  tone = "brand",
  onAction,
  className,
}) => {
  return (
    <Surface
      variant="elevated"
      radius="surface"
      className={cn(
        "flex items-center gap-3 p-3.5 cursor-pointer transition-transform active:scale-[0.99]",
        className,
      )}
      onClick={onAction}
    >
      <div
        className={cn(
          "w-10 h-10 rounded-p7-input flex items-center justify-center shrink-0",
          TONE_HALO[tone],
        )}
      >
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <Text variant="body-em" tone="primary" truncate>
          {title}
        </Text>
        <Text variant="caption-1" tone="tertiary" truncate>
          {description}
        </Text>
      </div>
      <ChevronRight className="w-4 h-4 text-ink-tertiary shrink-0" />
    </Surface>
  );
};

export default ServiceCard;
