import React from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { AlertTriangle, AlertCircle, Info, ArrowRight } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAutomationFlags } from "@/hooks/useTravelContext";
import type { AutomationFlag, AutomationFlagSeverity } from "@shared/types/intelligence";

const severityStyle: Record<
  AutomationFlagSeverity,
  { icon: typeof Info; bg: string; text: string; border: string }
> = {
  critical: {
    icon: AlertTriangle,
    bg: "bg-destructive/10",
    text: "text-destructive",
    border: "border-destructive/30",
  },
  warning: {
    icon: AlertCircle,
    bg: "bg-amber-500/10",
    text: "text-amber-500",
    border: "border-amber-500/30",
  },
  info: {
    icon: Info,
    bg: "bg-primary/10",
    text: "text-primary",
    border: "border-primary/20",
  },
};

interface AutomationFlagItemProps {
  flag: AutomationFlag;
  index: number;
}

const AutomationFlagItem: React.FC<AutomationFlagItemProps> = ({ flag, index }) => {
  const navigate = useNavigate();
  const style = severityStyle[flag.severity];
  const Icon = style.icon;

  return (
    <motion.button
      type="button"
      onClick={flag.cta ? () => navigate(flag.cta!.route) : undefined}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.04, duration: 0.25 }}
      className={cn(
        "w-full text-left rounded-xl border px-3.5 py-3 flex gap-3 items-start",
        style.bg,
        style.border,
        flag.cta && "active:scale-[0.98] transition-transform",
      )}
      data-flag-id={flag.id}
    >
      <Icon className={cn("w-4 h-4 mt-0.5 shrink-0", style.text)} />
      <div className="flex-1 min-w-0">
        <p className="text-[13px] font-semibold text-foreground leading-tight">
          {flag.title}
        </p>
        <p className="text-[11.5px] text-muted-foreground mt-0.5 leading-snug">
          {flag.description}
        </p>
        {flag.cta ? (
          <span
            className={cn(
              "mt-1.5 inline-flex items-center gap-1 text-[11px] font-medium",
              style.text,
            )}
          >
            {flag.cta.label} <ArrowRight className="w-3 h-3" />
          </span>
        ) : null}
      </div>
    </motion.button>
  );
};

interface AutomationFlagListProps {
  /** Render only the first N flags. Defaults to all. */
  limit?: number;
  /** Show a header above the list. */
  heading?: string;
  className?: string;
}

const AutomationFlagList: React.FC<AutomationFlagListProps> = ({
  limit,
  heading,
  className,
}) => {
  const flags = useAutomationFlags();
  const items = limit ? flags.slice(0, limit) : flags;

  if (items.length === 0) return null;

  return (
    <div className={cn("space-y-2", className)}>
      {heading ? (
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1">
          {heading}
        </p>
      ) : null}
      {items.map((flag, i) => (
        <AutomationFlagItem key={flag.id} flag={flag} index={i} />
      ))}
    </div>
  );
};

export default AutomationFlagList;
