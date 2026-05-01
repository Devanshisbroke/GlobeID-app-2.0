/**
 * Centralised voice intent dispatcher used by the FAB speed-dial item
 * and the listening transcript overlay.
 *
 * Wraps `useVoiceCommands` (the low-level recognition engine) with the
 * intent → navigation / action mapping the rest of the app expects.
 * Lives in its own file so React Fast Refresh stays happy
 * (`react-refresh/only-export-components` forbids exporting both
 * components and hooks/functions from the same module).
 */
import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { useVoiceCommands } from "@/hooks/useVoiceCommands";
import { type VoiceIntent } from "@/lib/voiceIntents";
import { setLanguage, currentLanguage, SUPPORTED_LANGS } from "@/i18n";
import { useUserStore } from "@/store/userStore";
import { haptics } from "@/utils/haptics";

export interface UseVoiceControl {
  supported: boolean;
  listening: boolean;
  start: () => void;
  stop: () => void;
  transcript: string;
}

export function useVoiceControl(): UseVoiceControl {
  const navigate = useNavigate();

  const onIntent = useCallback(
    (intent: VoiceIntent) => {
      if (intent.kind === "navigate") {
        navigate(intent.path);
        toast.success(`→ ${intent.label}`);
        return;
      }
      if (intent.kind === "action") {
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
        return;
      }
      if (intent.kind === "query") {
        if (intent.query === "next-trip") {
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
        return;
      }
      if (intent.kind === "search") {
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
        return;
      }
      if (intent.kind === "unknown") {
        toast.error(`Didn't catch "${intent.transcript}"`);
      }
    },
    [navigate],
  );

  const { supported, listening, start, stop, transcript } = useVoiceCommands({
    onIntent,
  });

  const wrappedStart = useCallback(() => {
    haptics.medium();
    void start();
  }, [start]);
  const wrappedStop = useCallback(() => {
    haptics.light();
    void stop();
  }, [stop]);

  return {
    supported,
    listening,
    start: wrappedStart,
    stop: wrappedStop,
    transcript,
  };
}
