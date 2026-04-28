import React, { useState, useRef, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import TripPlanCard from "@/components/ai/TripPlanCard";
import VoicePrompt from "@/components/ai/VoicePrompt";
import { generateTrip, adjustTripDays, tripPresets, type GeneratedTrip } from "@/lib/tripGenerator";
import { totalJourneyDistance, uniqueCountries, uniqueContinents } from "@/lib/distanceEngine";
import { useTripPlannerStore, type TripTheme } from "@/store/tripPlannerStore";
import { useCopilotStore } from "@/store/copilotStore";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import {
  ArrowLeft, Send, Sparkles, Plane, MapPin, Globe2, Ruler,
  Save, RotateCcw, Minus, Plus, Palmtree, Briefcase, Mountain,
  Compass, Zap, Trash2,
} from "lucide-react";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  trip?: GeneratedTrip;
}

const styleModes = [
  { key: "vacation", label: "Luxury", icon: Palmtree },
  { key: "backpacking", label: "Backpack", icon: Mountain },
  { key: "business", label: "Business", icon: Briefcase },
  { key: "adventure", label: "Adventure", icon: Compass },
] as const;

// `GeneratedTrip.style` is free-form (the parser also returns
// "luxury"/"adventure"); the trip-planner store only accepts the canonical
// `TripTheme` union, so collapse non-canonical values to the safe default.
const VALID_THEMES: ReadonlySet<TripTheme> = new Set([
  "vacation",
  "business",
  "backpacking",
  "world_tour",
]);
const toTripTheme = (s: string): TripTheme =>
  VALID_THEMES.has(s as TripTheme) ? (s as TripTheme) : "vacation";

const TravelCopilot: React.FC = () => {
  const navigate = useNavigate();
  const { saveCurrentTrip, setCurrentName, setCurrentTheme, addDestination, clearCurrent } = useTripPlannerStore();
  const sendCopilotPrompt = useCopilotStore((s) => s.sendPrompt);
  const clearCopilotHistory = useCopilotStore((s) => s.clear);
  const persistedHistory = useCopilotStore((s) => s.messages);

  const WELCOME_MSG: ChatMessage = React.useMemo(
    () => ({
      id: "welcome",
      role: "assistant",
      content:
        "Hey! I'm your AI Travel Copilot ✈️\n\nTell me where you want to go and I'll build the perfect itinerary. Try:\n\n• \"Plan a 10 day Asia trip\"\n• \"European capitals tour 2 weeks\"\n• \"Round the world adventure\"",
    }),
    [],
  );

  // Initialize with whatever the store has at first render. If the store hasn't
  // hydrated yet (Phase 8: server `/copilot/history` is async), persistedHistory
  // is `[]` so we paint the welcome bubble. The effect below replaces that with
  // server-replay as soon as hydrate resolves.
  const [messages, setMessages] = useState<ChatMessage[]>(() =>
    persistedHistory.length === 0
      ? [WELCOME_MSG]
      : persistedHistory.map((m) => ({ id: m.id, role: m.role, content: m.content })),
  );
  const [input, setInput] = useState("");
  const [currentTrip, setCurrentTrip] = useState<GeneratedTrip | null>(null);
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  // Phase 9-α bug-fix #1: Copilot history rehydrate-after-clear.
  //
  // The previous implementation seeded `messages` from `persistedHistory` once
  // via `useMemo([], [])`, so when zustand-persist + the Phase-8 server hydrate
  // landed asynchronously after mount, the UI never re-rendered the recovered
  // log — it stayed pinned to the welcome bubble. We now mirror the store
  // exactly once, the first time it transitions from empty → populated, and
  // only when the local view hasn't been mutated by the user yet.
  const hydratedFromStore = useRef(false);
  useEffect(() => {
    if (hydratedFromStore.current) return;
    if (persistedHistory.length === 0) return;
    setMessages(
      persistedHistory.map((m) => ({ id: m.id, role: m.role, content: m.content })),
    );
    hydratedFromStore.current = true;
  }, [persistedHistory]);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, isTyping]);

  const renderGeneratedTrip = useCallback((prompt: string) => {
    const trip = generateTrip(prompt);
    setCurrentTrip(trip);
    const route = trip.stops.map((s) => s.iata).join(" → ");
    const dist = totalJourneyDistance(trip.stops.map((s) => s.iata));
    const countries = uniqueCountries(trip.stops.map((s) => s.iata));
    const continents = uniqueContinents(trip.stops.map((s) => s.iata));
    return {
      content:
        `Here's your **${trip.name}**!\n\n` +
        `🗺️ **Route:** ${route}\n` +
        `📅 **Duration:** ${trip.totalDays} days\n` +
        `✈️ **Flights:** ${trip.stops.length - 1}\n` +
        `🌍 **Countries:** ${countries.length} · **Continents:** ${continents.length}\n` +
        `📏 **Distance:** ${(dist / 1000).toFixed(1)}k km\n\n` +
        `Scroll down to see each stop. You can adjust the trip length or save it to your planner!`,
      trip,
    };
  }, []);

  const processPrompt = useCallback(
    (prompt: string) => {
      // Once the user starts a turn, freeze the rehydrate-from-store effect so
      // a late-arriving server hydrate can't trample over the live session.
      hydratedFromStore.current = true;
      const userMsg: ChatMessage = { id: crypto.randomUUID(), role: "user", content: prompt };
      setMessages((prev) => [...prev, userMsg]);
      setIsTyping(true);
      haptics.selection();

      void (async () => {
        let serverMessage = "";
        let actionType: string | null = null;
        try {
          const result = await sendCopilotPrompt(prompt);
          serverMessage = result.message;
          actionType = result.action?.type ?? null;
        } catch {
          // hard error → fall back to client generator
          actionType = "generate_trip";
        }

        // Slight delay for natural typing feel.
        await new Promise((r) => setTimeout(r, 600));

        if (actionType === "generate_trip") {
          const { content, trip } = renderGeneratedTrip(prompt);
          setMessages((prev) => [
            ...prev,
            { id: crypto.randomUUID(), role: "assistant", content, trip },
          ]);
        } else {
          // Data-grounded response — no trip card, just the server text.
          setMessages((prev) => [
            ...prev,
            {
              id: crypto.randomUUID(),
              role: "assistant",
              content: serverMessage || "I'm not sure I caught that. Try: 'Plan a 10 day Asia trip'.",
            },
          ]);
        }
        setIsTyping(false);
        haptics.success();
      })();
    },
    [renderGeneratedTrip, sendCopilotPrompt],
  );

  const handleSend = () => {
    const text = input.trim();
    if (!text) return;
    setInput("");
    processPrompt(text);
  };

  const handleSaveTrip = () => {
    if (!currentTrip) return;
    clearCurrent();
    setCurrentName(currentTrip.name);
    setCurrentTheme(toTripTheme(currentTrip.style));
    currentTrip.stops.forEach((s) => addDestination(s.iata));
    void saveCurrentTrip();
    haptics.success();

    const msg: ChatMessage = {
      id: crypto.randomUUID(),
      role: "assistant",
      content: `✅ **${currentTrip.name}** saved! You can find it in your Trip Planner.`,
    };
    setMessages((prev) => [...prev, msg]);
  };

  const handleAdjustDays = (delta: number) => {
    if (!currentTrip) return;
    const newDays = Math.max(3, Math.min(60, currentTrip.totalDays + delta));
    const adjusted = adjustTripDays(currentTrip, newDays);
    setCurrentTrip(adjusted);
    haptics.selection();
  };

  // Phase 9-α bug-fix #3: clear-chat surface. The store + server endpoint
  // already exist (Phase 8 PR #16) but had no UI trigger, leaving the
  // E2E test of `DELETE /copilot/history` unverifiable through the app.
  // Wipes server + persisted history, then resets the local view to the
  // welcome bubble so the next prompt starts clean.
  const handleClearChat = useCallback(() => {
    void clearCopilotHistory();
    setCurrentTrip(null);
    setMessages([WELCOME_MSG]);
    hydratedFromStore.current = true;
    haptics.selection();
  }, [clearCopilotHistory, WELCOME_MSG]);

  return (
    <div className="flex flex-col h-[calc(100dvh-5rem)]">
      {/* Header */}
      <div className="px-4 pt-6 pb-3 flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
          <ArrowLeft className="w-4 h-4 text-foreground" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <motion.div
              animate={{ scale: [1, 1.15, 1] }}
              transition={{ repeat: Infinity, duration: 2.5, ease: "easeInOut" }}
              className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-glow-sm shrink-0"
            >
              <Sparkles className="w-4 h-4 text-primary-foreground" />
            </motion.div>
            <div className="min-w-0">
              <h1 className="text-lg font-bold text-foreground truncate">AI Copilot</h1>
              <p className="text-[10px] text-muted-foreground truncate">Powered by GlobeID</p>
            </div>
          </div>
        </div>
        <button
          onClick={handleClearChat}
          aria-label="Clear chat history"
          className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>

      {/* Presets */}
      <div className="px-4 pb-3 flex gap-2 overflow-x-auto hide-scrollbar">
        {tripPresets.map((preset) => (
          <button
            key={preset.id}
            onClick={() => processPrompt(preset.prompt)}
            className="flex-shrink-0 px-3 py-1.5 rounded-full glass border border-border/30 text-xs font-medium text-foreground hover:border-primary/30 transition-colors"
          >
            <span className="mr-1">{preset.icon}</span>
            {preset.label}
          </button>
        ))}
      </div>

      {/* Chat messages */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto px-4 space-y-3 pb-4 hide-scrollbar">
        <AnimatePresence initial={false}>
          {messages.map((msg) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 10, scale: 0.97 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ type: "spring", stiffness: 300, damping: 25 }}
              className={cn("flex", msg.role === "user" ? "justify-end" : "justify-start")}
            >
              <div
                className={cn(
                  "max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-relaxed",
                  msg.role === "user"
                    ? "bg-primary text-primary-foreground rounded-br-md"
                    : "glass border border-border/30 text-foreground rounded-bl-md"
                )}
              >
                {msg.content.split("\n").map((line, i) => (
                  <p key={i} className={cn(line === "" && "h-2")}>
                    {line.split(/(\*\*.*?\*\*)/g).map((part, j) =>
                      part.startsWith("**") && part.endsWith("**") ? (
                        <strong key={j} className="font-semibold">{part.slice(2, -2)}</strong>
                      ) : (
                        <span key={j}>{part}</span>
                      )
                    )}
                  </p>
                ))}
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Typing indicator */}
        {isTyping && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex gap-1.5 px-4 py-3 glass rounded-2xl rounded-bl-md w-fit border border-border/30"
          >
            {[0, 1, 2].map((i) => (
              <motion.div
                key={i}
                animate={{ y: [0, -4, 0] }}
                transition={{ repeat: Infinity, duration: 0.6, delay: i * 0.15 }}
                className="w-2 h-2 rounded-full bg-primary/50"
              />
            ))}
          </motion.div>
        )}

        {/* Trip plan cards */}
        {currentTrip && !isTyping && (
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-3 pt-2"
          >
            {/* Itinerary */}
            <div className="space-y-2">
              {currentTrip.stops.map((stop, idx) => (
                <TripPlanCard
                  key={stop.iata}
                  stop={stop}
                  index={idx}
                  total={currentTrip.stops.length}
                />
              ))}
            </div>

            {/* Day adjustment */}
            <GlassCard interactive={false} className="flex items-center justify-between">
              <span className="text-sm font-medium text-foreground">Trip Length</span>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => handleAdjustDays(-1)}
                  className="w-8 h-8 rounded-lg glass border border-border/30 flex items-center justify-center"
                >
                  <Minus className="w-3.5 h-3.5 text-foreground" />
                </button>
                <span className="text-lg font-bold text-foreground w-12 text-center">
                  {currentTrip.totalDays}d
                </span>
                <button
                  onClick={() => handleAdjustDays(1)}
                  className="w-8 h-8 rounded-lg glass border border-border/30 flex items-center justify-center"
                >
                  <Plus className="w-3.5 h-3.5 text-foreground" />
                </button>
              </div>
            </GlassCard>

            {/* Actions */}
            <div className="flex gap-2">
              <button
                onClick={handleSaveTrip}
                className="flex-1 py-3 rounded-xl bg-primary text-primary-foreground text-sm font-semibold flex items-center justify-center gap-2 shadow-glow-sm"
              >
                <Save className="w-4 h-4" />
                Save to Planner
              </button>
              <button
                onClick={() => processPrompt(input || "Surprise me with a trip")}
                className="px-4 py-3 rounded-xl glass border border-border/30 text-foreground"
              >
                <RotateCcw className="w-4 h-4" />
              </button>
            </div>
          </motion.div>
        )}
      </div>

      {/* Input */}
      <div className="px-4 pb-4 pt-2">
        <div className="flex items-center gap-2 p-2 rounded-2xl glass border border-border/40">
          <VoicePrompt onTranscript={(text) => { setInput(text); processPrompt(text); }} />
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSend()}
            placeholder="Where do you want to go?"
            className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none px-1"
          />
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={handleSend}
            disabled={!input.trim()}
            className={cn(
              "w-10 h-10 rounded-xl flex items-center justify-center transition-all",
              input.trim()
                ? "bg-primary text-primary-foreground shadow-glow-sm"
                : "glass border border-border/30 text-muted-foreground"
            )}
          >
            <Send className="w-4 h-4" />
          </motion.button>
        </div>
      </div>
    </div>
  );
};

export default TravelCopilot;
