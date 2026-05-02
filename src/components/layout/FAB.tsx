import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Scan, CreditCard, Plus, Plane, FileText, X, Mic, MicOff } from "lucide-react";
import { haptics } from "@/utils/haptics";
import { spring } from "@/motion/motionConfig";
import { useVoiceControl } from "@/hooks/useVoiceControl";
import { VoiceTranscriptOverlay } from "@/components/voice/VoiceCommandButton";

/**
 * Floating action speed-dial.
 *
 * Tapping the `+` button opens a vertical column of action chips. The
 * voice command toggle is part of this menu so users only ever see one
 * floating affordance at a time — previously we had separate FAB / voice
 * / AI buttons that overlapped in the lower-right corner.
 */

interface ActionItem {
  icon: React.ComponentType<{ className?: string; strokeWidth?: number }>;
  label: string;
  path?: string;
  // Optional inline action — runs instead of navigating when set.
  run?: () => void;
  active?: boolean;
}

const baseActions: ActionItem[] = [
  { icon: CreditCard, label: "Quick Pay", path: "/wallet" },
  { icon: Scan, label: "Scan ID", path: "/scan" },
  { icon: Plane, label: "Add Trip", path: "/travel" },
  { icon: FileText, label: "Add Doc", path: "/scan" },
];

const FAB: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const voice = useVoiceControl();

  if (location.pathname === "/lock") return null;

  // Build the action set dynamically so the voice item only shows when
  // the underlying SpeechRecognition engine is supported in this WebView.
  const actions: ActionItem[] = [...baseActions];
  if (voice.supported) {
    actions.push({
      icon: voice.listening ? MicOff : Mic,
      label: voice.listening ? "Stop voice" : "Voice command",
      run: () => (voice.listening ? voice.stop() : voice.start()),
      active: voice.listening,
    });
  }

  const runAction = (a: ActionItem) => {
    setOpen(false);
    if (a.run) {
      a.run();
      return;
    }
    if (a.path) {
      haptics.tap();
      navigate(a.path);
    }
  };

  return (
    <>
      {/* Listening indicator — sits above the FAB so the chip + transcript
          are visible even when the speed-dial is closed. */}
      <VoiceTranscriptOverlay
        listening={voice.listening}
        transcript={voice.transcript}
      />

      {/* Backdrop */}
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-40 bg-background/40 backdrop-blur-sm"
            onClick={() => setOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Action buttons */}
      <AnimatePresence>
        {open && (
          <div
            className="fixed z-50 right-4 flex flex-col-reverse gap-3 items-end"
            style={{
              // Anchor above the FAB; safe-area-inset-bottom keeps us
              // clear of the Android gesture bar / iOS home indicator.
              bottom: "calc(env(safe-area-inset-bottom, 0px) + 152px)",
            }}
          >
            {actions.map((action, i) => {
              const Icon = action.icon;
              return (
                <motion.button
                  key={action.label}
                  type="button"
                  aria-label={action.label}
                  initial={{ opacity: 0, scale: 0.3, y: 20 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.3, y: 20 }}
                  transition={{ ...spring.fab, delay: i * 0.04 }}
                  onClick={() => runAction(action)}
                  className="flex items-center gap-2.5 outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] rounded-full"
                  whileTap={{ scale: 0.95 }}
                >
                  <span className="text-xs font-semibold text-foreground glass px-3 py-1.5 rounded-lg shadow-depth-sm whitespace-nowrap">
                    {action.label}
                  </span>
                  <span
                    className={cn(
                      "w-11 h-11 rounded-full flex items-center justify-center shadow-depth-md",
                      action.active
                        ? "bg-rose-500"
                        : "bg-gradient-brand",
                    )}
                  >
                    <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                  </span>
                </motion.button>
              );
            })}
          </div>
        )}
      </AnimatePresence>

      {/* Main FAB */}
      <motion.button
        type="button"
        aria-label={open ? "Close menu" : "Quick actions"}
        aria-expanded={open}
        onClick={() => {
          haptics.medium();
          setOpen((v) => !v);
        }}
        animate={{ rotate: open ? 135 : 0 }}
        whileTap={{ scale: 0.94 }}
        transition={spring.fab}
        style={{
          // Anchor above safe-area-inset-bottom so the FAB sits clear of
          // the Android gesture bar on devices with edge-to-edge layouts.
          bottom: "calc(env(safe-area-inset-bottom, 0px) + 88px)",
        }}
        className={cn(
          "fixed z-50 right-4 w-14 h-14 rounded-full",
          "flex items-center justify-center",
          "bg-gradient-brand shadow-glow-lg",
          "outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
          "will-change-transform",
        )}
      >
        {open ? (
          <X className="w-6 h-6 text-primary-foreground" strokeWidth={2} />
        ) : (
          <Plus className="w-6 h-6 text-primary-foreground" strokeWidth={2} />
        )}
      </motion.button>
    </>
  );
};

export { FAB };
