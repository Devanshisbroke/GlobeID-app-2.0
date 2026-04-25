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
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import {
  ArrowLeft, Send, Sparkles, Plane, MapPin, Globe2, Ruler,
  Save, RotateCcw, Minus, Plus, Palmtree, Briefcase, Mountain,
  Compass, Zap,
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
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: "welcome",
      role: "assistant",
      content: "Hey! I'm your AI Travel Copilot ✈️\n\nTell me where you want to go and I'll build the perfect itinerary. Try:\n\n• \"Plan a 10 day Asia trip\"\n• \"European capitals tour 2 weeks\"\n• \"Round the world adventure\"",
    },
  ]);
  const [input, setInput] = useState("");
  const [currentTrip, setCurrentTrip] = useState<GeneratedTrip | null>(null);
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, isTyping]);

  const processPrompt = useCallback((prompt: string) => {
    const userMsg: ChatMessage = { id: crypto.randomUUID(), role: "user", content: prompt };
    setMessages((prev) => [...prev, userMsg]);
    setIsTyping(true);
    haptics.selection();

    setTimeout(() => {
      const trip = generateTrip(prompt);
      setCurrentTrip(trip);

      const route = trip.stops.map((s) => s.iata).join(" → ");
      const dist = totalJourneyDistance(trip.stops.map((s) => s.iata));
      const countries = uniqueCountries(trip.stops.map((s) => s.iata));
      const continents = uniqueContinents(trip.stops.map((s) => s.iata));

      const response = `Here's your **${trip.name}**!\n\n` +
        `🗺️ **Route:** ${route}\n` +
        `📅 **Duration:** ${trip.totalDays} days\n` +
        `✈️ **Flights:** ${trip.stops.length - 1}\n` +
        `🌍 **Countries:** ${countries.length} · **Continents:** ${continents.length}\n` +
        `📏 **Distance:** ${(dist / 1000).toFixed(1)}k km\n\n` +
        `Scroll down to see each stop. You can adjust the trip length or save it to your planner!`;

      const assistantMsg: ChatMessage = {
        id: crypto.randomUUID(),
        role: "assistant",
        content: response,
        trip,
      };
      setMessages((prev) => [...prev, assistantMsg]);
      setIsTyping(false);
      haptics.success();
    }, 1200);
  }, []);

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
    saveCurrentTrip();
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

  return (
    <div className="flex flex-col h-[calc(100dvh-5rem)]">
      {/* Header */}
      <div className="px-4 pt-6 pb-3 flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
          <ArrowLeft className="w-4 h-4 text-foreground" />
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <motion.div
              animate={{ scale: [1, 1.15, 1] }}
              transition={{ repeat: Infinity, duration: 2.5, ease: "easeInOut" }}
              className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-glow-sm"
            >
              <Sparkles className="w-4 h-4 text-primary-foreground" />
            </motion.div>
            <div>
              <h1 className="text-lg font-bold text-foreground">AI Copilot</h1>
              <p className="text-[10px] text-muted-foreground">Powered by GlobeID</p>
            </div>
          </div>
        </div>
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
