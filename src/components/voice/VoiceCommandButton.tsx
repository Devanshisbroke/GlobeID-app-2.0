/**
 * Voice command surfaces.
 *
 * Used to be a standalone floating button at `bottom-28 right-4`,
 * which collided visually with the `+` FAB. Voice is now an item in
 * the FAB's speed-dial via `useVoiceControl()` and the listening
 * transcript is rendered separately by `<VoiceTranscriptOverlay />`
 * mounted inside the FAB. The standalone fixed button is deliberately
 * removed — the default export is a no-op component kept for backward
 * compatibility with prior mount points.
 */
import React from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Mic } from "lucide-react";

interface OverlayProps {
  listening: boolean;
  transcript: string;
}

export const VoiceTranscriptOverlay: React.FC<OverlayProps> = ({
  listening,
  transcript,
}) => {
  return (
    <AnimatePresence>
      {listening ? (
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 16 }}
          className="fixed left-1/2 -translate-x-1/2 bottom-[180px] z-[60] px-4 py-2 rounded-full bg-primary/95 text-primary-foreground text-xs font-semibold shadow-xl backdrop-blur-md"
          role="status"
          aria-live="polite"
        >
          <span className="flex items-center gap-2">
            <Mic className="h-3.5 w-3.5 animate-pulse" />
            {transcript ? `"${transcript}"` : "Listening…"}
          </span>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
};

const VoiceCommandButton: React.FC = () => null;
export default VoiceCommandButton;
