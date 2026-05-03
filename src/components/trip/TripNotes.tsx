import React, { lazy, Suspense } from "react";
import { motion } from "framer-motion";

/**
 * TripNotes — Notion-style rich-text editor for per-trip notes
 * (BACKLOG D 45). The editor itself is code-split via React.lazy so
 * Tiptap + ProseMirror only ship for users who actually open a trip
 * detail screen and start typing. Outside that flow the bundle stays
 * lean.
 */
const TripNotesEditor = lazy(() => import("./TripNotesEditor"));

const SkeletonNotes: React.FC = () => (
  <div
    className="rounded-2xl border border-border bg-card p-3 min-h-[120px]"
    aria-hidden
  >
    <div className="h-3 w-1/3 bg-surface-overlay/60 rounded mb-2 animate-pulse" />
    <div className="h-3 w-2/3 bg-surface-overlay/40 rounded mb-1.5 animate-pulse" />
    <div className="h-3 w-1/2 bg-surface-overlay/40 rounded animate-pulse" />
  </div>
);

const TripNotes: React.FC<{ tripId: string }> = ({ tripId }) => {
  return (
    <motion.section
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 240, damping: 28 }}
    >
      <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2">
        Notes
      </h2>
      <Suspense fallback={<SkeletonNotes />}>
        <TripNotesEditor tripId={tripId} />
      </Suspense>
    </motion.section>
  );
};

export default TripNotes;
