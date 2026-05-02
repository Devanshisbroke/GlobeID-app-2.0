/**
 * Slice-G – Apple-Wallet-style stacked pass UI.
 *
 * Replaces the flat list of DocumentCards in the Wallet → Documents tab.
 * Behavior:
 *   • Passes render stacked with a peek offset; the topmost pass is fully
 *     visible, each pass below shows a ~16 px sliver + 6 px vertical
 *     tuck.
 *   • Dragging down on a pass "releases" it from the stack — picks the
 *     target pass. Tap-to-pick also works.
 *   • Tapping the active pass opens `PassDetail` full-screen with a
 *     shared `layoutId` transition so the card morphs into the sheet.
 *
 * Purely presentational: all data comes from the parent. No store reads
 * so this stays unit-testable in isolation.
 */
import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { FileText, Plane, ShieldCheck, CreditCard, AlertTriangle } from "lucide-react";
import { spring } from "@/components/ui/v2";
import type { TravelDocument } from "@/store/userStore";
import { cn } from "@/lib/utils";
import { haptics } from "@/utils/haptics";
import { describeExpiry } from "@/lib/documentExpiry";
import { brandForBoardingPass } from "@/lib/airlineBrand";
import PassDetail from "./PassDetail";

export interface PassStackProps {
  documents: TravelDocument[];
  className?: string;
}

const TYPE_META: Record<
  TravelDocument["type"],
  { icon: React.ComponentType<{ className?: string }>; hue: string; accent: string }
> = {
  passport: {
    icon: FileText,
    hue: "from-indigo-600 via-indigo-700 to-slate-900",
    accent: "text-indigo-100",
  },
  visa: {
    icon: ShieldCheck,
    hue: "from-emerald-600 via-emerald-700 to-slate-900",
    accent: "text-emerald-100",
  },
  boarding_pass: {
    icon: Plane,
    hue: "from-sky-600 via-blue-700 to-slate-900",
    accent: "text-sky-100",
  },
  travel_insurance: {
    icon: CreditCard,
    hue: "from-rose-600 via-rose-700 to-slate-900",
    accent: "text-rose-100",
  },
};

const PEEK_Y = 18;
const PEEK_SCALE = 0.04;

const PassStack: React.FC<PassStackProps> = ({ documents, className }) => {
  const [activeIdx, setActiveIdx] = useState(0);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  // The active pass is on top. We render the rest under it in a tight
  // stack with incremental peek offsets. Guarded with `safeIdx` so an
  // empty documents array doesn't throw — the early-return below then
  // takes over for the render path. Hooks always run to preserve order.
  const ordered = React.useMemo(() => {
    if (documents.length === 0) return null;
    const safeIdx = Math.min(activeIdx, documents.length - 1);
    const head = documents[safeIdx]!;
    const rest = documents.filter((_, i) => i !== safeIdx);
    return { head, rest };
  }, [documents, activeIdx]);

  if (!ordered) {
    return (
      <div className="rounded-p7-surface border border-dashed border-border/60 p-8 text-center text-sm text-muted-foreground">
        No travel documents yet
      </div>
    );
  }

  const handlePick = (idx: number) => {
    haptics.selection();
    setActiveIdx(idx);
  };

  return (
    <div className={cn("relative", className)}>
      {/* Stack area. Height scales with the number of visible peeks. */}
      <div
        className="relative"
        style={{ height: 180 + ordered.rest.length * PEEK_Y }}
      >
        {/* Background passes, peeking from under the active one. */}
        {ordered.rest.map((doc, i) => {
          const depth = i + 1;
          const origIdx = documents.findIndex((d) => d.id === doc.id);
          return (
            <React.Fragment key={doc.id}>
              <motion.div
                aria-hidden="true"
                className="pointer-events-none absolute inset-x-0"
                style={{
                  top: depth * PEEK_Y,
                  zIndex: 10 - depth,
                }}
                initial={false}
                animate={{
                  scale: 1 - depth * PEEK_SCALE,
                  opacity: 1 - depth * 0.12,
                }}
                transition={spring.default}
              >
                <PassCard doc={doc} />
              </motion.div>
              <button
                type="button"
                aria-label={`Select ${doc.label}`}
                onClick={() => handlePick(origIdx)}
                className="absolute inset-x-0 rounded-b-[22px] focus:outline-none focus-visible:ring-2 focus-visible:ring-brand bg-transparent"
                style={{
                  top: 180 + (depth - 1) * PEEK_Y,
                  height: PEEK_Y,
                  zIndex: 30 - depth,
                  touchAction: "pan-y",
                }}
              />
            </React.Fragment>
          );
        })}

        {/* Active pass — top of stack.
            Architecture notes:
              • `layoutId` is required so the card morphs into PassDetail
                via shared layout transition.
              • Drag is locked to the X axis with `dragDirectionLock` so
                the user can horizontal-swipe to cycle through passes
                (Apple Wallet style) AND vertical-scroll the page —
                framer waits for the first axis the user moves on and
                locks to it.
              • Tap-to-expand lives on a child `<button>` overlay rather
                than `onTap` so the page-scroll touch stream isn't
                captured by framer's tap handler.
              • `whileTap` removed for the same reason — its pointer
                capture interfered with vertical pan on touch devices. */}
        <motion.div
          key={ordered.head.id}
          layoutId={`pass-${ordered.head.id}`}
          className="absolute inset-x-0 top-0 rounded-[22px]"
          style={{ zIndex: 20, touchAction: "pan-y", willChange: "transform" }}
          drag="x"
          dragDirectionLock
          dragConstraints={{ left: 0, right: 0 }}
          dragElastic={0.18}
          onDragEnd={(_, info) => {
            if (documents.length < 2) return;
            const SWIPE_THRESHOLD = 60;
            if (info.offset.x < -SWIPE_THRESHOLD) {
              haptics.medium();
              setActiveIdx((i) => (i + 1) % documents.length);
            } else if (info.offset.x > SWIPE_THRESHOLD) {
              haptics.medium();
              setActiveIdx(
                (i) => (i - 1 + documents.length) % documents.length,
              );
            }
          }}
        >
          <PassCard doc={ordered.head} active />
          {/* Tap-to-expand surface — its own focusable element, doesn't
              capture pointer for movement so vertical scroll still wins. */}
          <button
            type="button"
            aria-label={`Open ${ordered.head.label} pass`}
            onClick={() => {
              haptics.light();
              setExpandedId(ordered.head.id);
            }}
            className="absolute inset-0 rounded-[22px] outline-none focus-visible:ring-2 focus-visible:ring-brand bg-transparent"
            style={{ touchAction: "pan-y" }}
          />
        </motion.div>
      </div>

      <AnimatePresence>
        {expandedId ? (
          <PassDetail
            doc={documents.find((d) => d.id === expandedId)!}
            onClose={() => {
              haptics.light();
              setExpandedId(null);
            }}
          />
        ) : null}
      </AnimatePresence>
    </div>
  );
};

interface PassCardProps {
  doc: TravelDocument;
  active?: boolean;
}

export const PassCard: React.FC<PassCardProps> = ({ doc, active = false }) => {
  const meta = TYPE_META[doc.type];
  const Icon = meta.icon;
  const expiry = describeExpiry(doc.expiryDate);
  // Boarding-pass cards adopt the carrier's brand gradient (real Apple
  // / Google Wallet behaviour). Other doc types keep their semantic hue.
  const brand = doc.type === "boarding_pass" ? brandForBoardingPass(doc) : null;
  const hueClasses = brand?.gradient ?? meta.hue;
  const accentClass = brand?.accent ?? meta.accent;
  return (
    <div
      className={cn(
        "relative w-full overflow-hidden rounded-[22px] p-5",
        "bg-gradient-to-br",
        hueClasses,
        "shadow-[0_18px_40px_-20px_rgba(0,0,0,0.45)]",
        active ? "ring-1 ring-white/10" : "ring-1 ring-white/5",
      )}
    >
      {expiry.severity !== "none" ? (
        <div
          aria-label={expiry.label}
          className={cn(
            "absolute right-4 top-4 z-10 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-medium tracking-wide",
            expiry.severity === "critical"
              ? "bg-rose-500/95 text-white"
              : "bg-amber-400/95 text-amber-950",
          )}
        >
          <AlertTriangle className="h-2.5 w-2.5" />
          {expiry.daysUntil < 0 ? "Expired" : `${expiry.daysUntil}d`}
        </div>
      ) : null}
      <div className="flex items-start justify-between text-white">
        <div>
          <p className={cn("text-[10px] uppercase tracking-[0.24em]", accentClass)}>
            {doc.label}
          </p>
          <p className="mt-1 text-lg font-medium leading-tight">{doc.country}</p>
          <p className="mt-0.5 text-[11px] text-white/60">{doc.countryFlag}</p>
        </div>
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-white/10 backdrop-blur-sm">
          <Icon className="h-4 w-4 text-white" />
        </div>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-3 text-white">
        <div>
          <p className="text-[10px] uppercase tracking-widest text-white/50">
            Number
          </p>
          <p className="mt-0.5 text-sm font-mono tracking-wider">
            {maskNumber(doc.number)}
          </p>
        </div>
        <div className="text-right">
          <p className="text-[10px] uppercase tracking-widest text-white/50">
            Expires
          </p>
          <p className="mt-0.5 text-sm tabular-nums">{doc.expiryDate}</p>
        </div>
      </div>

      {/* subtle sheen */}
      <div
        aria-hidden
        className="pointer-events-none absolute -top-1/2 right-[-20%] h-[200%] w-[60%] rotate-12 bg-white/5 blur-2xl"
      />
    </div>
  );
};

function maskNumber(n: string): string {
  if (n.length <= 4) return n;
  const tail = n.slice(-4);
  return "•••• " + tail;
}

export default PassStack;
