/**
 * Compact document-expiry banner (BACKLOG E 60).
 *
 * Renders the most-pressing upcoming document expiry as a small chip
 * above the IdentityScoreCard. If the soonest expiry is more than a
 * year away the chip stays hidden (no useless ambient warnings).
 *
 * Uses the existing user store as the source of truth so changes
 * elsewhere flow into the chip without a refactor.
 */
import React from "react";
import { motion } from "motion/react";
import { AlertCircle, Clock } from "lucide-react";
import { useUserStore } from "@/store/userStore";
import { spring } from "@/lib/motion-tokens";

const DAY_MS = 1000 * 60 * 60 * 24;

const DocExpiryChip: React.FC = () => {
  const { documents } = useUserStore();
  const now = Date.now();

  const upcoming = documents
    .filter((d) => d.status === "active" && Boolean(d.expiryDate))
    .map((d) => ({
      ...d,
      msUntil: new Date(d.expiryDate).getTime() - now,
    }))
    .filter((d) => d.msUntil > 0)
    .sort((a, b) => a.msUntil - b.msUntil)[0];

  if (!upcoming) return null;

  const days = Math.ceil(upcoming.msUntil / DAY_MS);
  if (days > 365) return null;

  const tone = days <= 30 ? "urgent" : days <= 90 ? "soon" : "ambient";
  const palette: Record<typeof tone, { bg: string; text: string; ring: string; Icon: React.ComponentType<{ className?: string }> }> = {
    urgent: {
      bg: "rgba(239,68,68,0.10)",
      text: "rgb(220,38,38)",
      ring: "rgba(239,68,68,0.30)",
      Icon: AlertCircle,
    },
    soon: {
      bg: "rgba(234,179,8,0.10)",
      text: "rgb(202,138,4)",
      ring: "rgba(234,179,8,0.28)",
      Icon: Clock,
    },
    ambient: {
      bg: "hsl(var(--p7-brand) / 0.08)",
      text: "hsl(var(--p7-brand-strong))",
      ring: "hsl(var(--p7-brand) / 0.20)",
      Icon: Clock,
    },
  };
  const p = palette[tone];

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={spring.snap}
      role="status"
      aria-live="polite"
      className="inline-flex max-w-full items-center gap-2 rounded-full px-3 py-1.5 text-[12px] font-medium"
      style={{
        backgroundColor: p.bg,
        color: p.text,
        boxShadow: `inset 0 0 0 1px ${p.ring}`,
      }}
    >
      <p.Icon className="w-3.5 h-3.5 shrink-0" />
      <span className="truncate">
        {upcoming.label} expires in {days} day{days === 1 ? "" : "s"}
      </span>
    </motion.div>
  );
};

export default DocExpiryChip;
