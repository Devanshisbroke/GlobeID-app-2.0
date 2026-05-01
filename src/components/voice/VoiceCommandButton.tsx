/**
 * Slice-C — floating voice-command button.
 *
 * A small mic button users can tap to dictate a command. Navigates in
 * response to parsed intents. Surfaces the listening state + transcript
 * in an inline toast.
 */
import React, { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { Mic, MicOff } from "lucide-react";
import { useVoiceCommands } from "@/hooks/useVoiceCommands";
import { type VoiceIntent } from "@/lib/voiceIntents";
import { setLanguage, currentLanguage, SUPPORTED_LANGS } from "@/i18n";
import { toast } from "sonner";
import { useUserStore } from "@/store/userStore";

const VoiceCommandButton: React.FC = () => {
  const navigate = useNavigate();

  const onIntent = useCallback(
    (intent: VoiceIntent) => {
      if (intent.kind === "navigate") {
        navigate(intent.path);
        toast.success(`→ ${intent.label}`);
      } else if (intent.kind === "action") {
        if (intent.action === "refresh") {
          toast.info("Refreshing…");
          window.location.reload();
        } else if (intent.action === "start-scan") {
          navigate("/scan");
          toast.success("→ Scanner");
        } else if (intent.action === "toggle-language") {
          const cur = currentLanguage();
          const idx = SUPPORTED_LANGS.indexOf(cur);
          const next = SUPPORTED_LANGS[(idx + 1) % SUPPORTED_LANGS.length]!;
          setLanguage(next);
          toast.success(`Language → ${next}`);
        }
      } else if (intent.kind === "query") {
        if (intent.query === "next-trip") {
          // Resolve the next upcoming trip directly so the user lands
          // on the trip detail rather than the timeline list.
          const history = useUserStore.getState().travelHistory;
          const today = new Date().toISOString().slice(0, 10);
          const upcoming = history
            .filter((r) => r.type !== "past" && r.date.slice(0, 10) >= today)
            .sort((a, b) => a.date.localeCompare(b.date))[0];
          if (upcoming) {
            navigate(`/trip/${encodeURIComponent(upcoming.id)}`);
            toast.success(`→ Next trip · ${upcoming.from} → ${upcoming.to}`);
          } else {
            navigate("/timeline");
            toast.info("No upcoming trips — opening Timeline");
          }
          return;
        }
        const map: Record<string, string> = {
          "wallet-balance": "/wallet",
          score: "/intelligence",
          weather: "/services/super",
        };
        const p = map[intent.query];
        if (p) {
          navigate(p);
          toast.success(`→ ${intent.label}`);
        }
      } else if (intent.kind === "search") {
        const map: Record<string, string> = {
          hotels: "/services/hotels",
          rides: "/services/rides",
          food: "/services/food",
          visa: "/services/super",
        };
        const p = map[intent.target];
        if (p) {
          navigate(p);
          toast.success(`→ ${intent.label}`);
        }
      } else if (intent.kind === "unknown") {
        toast.error(`Didn't catch "${intent.transcript}"`);
      }
    },
    [navigate],
  );

  const { supported, listening, start, stop, transcript } = useVoiceCommands({ onIntent });

  if (!supported) return null;

  return (
    <>
      <AnimatePresence>
        {listening && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            className="fixed left-1/2 -translate-x-1/2 bottom-28 z-50 px-4 py-2 rounded-full bg-primary/90 text-primary-foreground text-xs font-semibold shadow-xl backdrop-blur-md"
          >
            Listening… {transcript && `"${transcript}"`}
          </motion.div>
        )}
      </AnimatePresence>
      <button
        aria-label="Voice command"
        onClick={() => (listening ? void stop() : void start())}
        className="fixed right-4 bottom-28 z-40 w-11 h-11 rounded-full bg-gradient-brand shadow-lg flex items-center justify-center active:scale-95 transition-transform"
      >
        {listening ? (
          <MicOff className="w-4 h-4 text-white" />
        ) : (
          <Mic className="w-4 h-4 text-white" />
        )}
      </button>
    </>
  );
};

export default VoiceCommandButton;
