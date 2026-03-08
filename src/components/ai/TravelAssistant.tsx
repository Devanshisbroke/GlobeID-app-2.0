import React, { useState, useRef, useEffect } from "react";
import { cn } from "@/lib/utils";
import { getVisaRequirement } from "@/lib/visaEngine";
import { useUserStore } from "@/store/userStore";
import { Send, X, Plane, Sparkles, MapPin, ShieldCheck } from "lucide-react";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  suggestions?: string[];
}

const TRAVEL_SUGGESTIONS = [
  "Do I need a visa for Japan?",
  "Best time to visit Bali",
  "Visa-free countries for me",
  "Flights from Delhi to London",
];

// Simple intent-based response engine
function generateResponse(input: string, nationality: string): { content: string; suggestions?: string[] } {
  const lower = input.toLowerCase();

  // Visa queries
  const visaMatch = lower.match(/visa.*(?:for|to)\s+(\w[\w\s]*)/i) || lower.match(/(?:need|require).*visa.*(\w[\w\s]*)/i);
  if (visaMatch || lower.includes("visa")) {
    const countries = ["Japan", "Thailand", "Indonesia", "Singapore", "UAE", "United States", "United Kingdom", "France", "Brazil", "Turkey", "Australia", "Maldives", "Nepal", "Sri Lanka", "Malaysia", "Kenya"];
    const found = countries.find(c => lower.includes(c.toLowerCase()));
    if (found) {
      const req = getVisaRequirement(nationality, found);
      return {
        content: `🛂 **Visa for ${found}**\n\n**Status:** ${req.label}\n${req.durationAllowed ? `**Duration:** ${req.durationAllowed}\n` : ""}${req.notes ? `**Note:** ${req.notes}` : ""}`,
        suggestions: [`Best time to visit ${found}`, `Flights to ${found}`, "Visa-free countries for me"],
      };
    }

    // Visa-free list
    if (lower.includes("visa-free") || lower.includes("visa free") || lower.includes("without")) {
      const destinations = getVisaFreeDestinationsList(nationality);
      return {
        content: `🌍 **Visa-Free Destinations for ${nationality} Citizens**\n\n${destinations.length > 0 ? destinations.map((d: string) => `• ${d}`).join("\n") : "Check specific countries for details."}`,
        suggestions: ["Do I need a visa for Japan?", "Best time to visit Thailand"],
      };
    }

    return {
      content: "Which country are you asking about? I can check visa requirements for any destination.",
      suggestions: ["Visa for Japan", "Visa for Thailand", "Visa for Singapore", "Visa-free countries"],
    };
  }

  // Best time queries
  const timeMatch = lower.match(/best\s+time.*(?:to|for)\s+(?:visit|travel|go)\s+(?:to\s+)?(\w[\w\s]*)/i);
  if (timeMatch || lower.includes("best time")) {
    const timingData: Record<string, string> = {
      bali: "🌴 **Best Time for Bali**\n\nApril to October (dry season). Peak tourism July-August. Budget-friendly in shoulder months (April, May, September).",
      japan: "🌸 **Best Time for Japan**\n\nMarch-May (cherry blossoms) or October-November (autumn foliage). Summer is humid. Winter is great for skiing.",
      thailand: "🏖️ **Best Time for Thailand**\n\nNovember to February (cool & dry). Avoid June-October rainy season. Songkran festival in April.",
      singapore: "🏙️ **Best Time for Singapore**\n\nFebruary to April (least rain). Singapore is warm year-round (27-32°C). Great for any season.",
      dubai: "🏜️ **Best Time for Dubai**\n\nNovember to March (cooler temps around 20-25°C). Avoid summer heat (40°C+).",
    };

    for (const [key, value] of Object.entries(timingData)) {
      if (lower.includes(key)) return { content: value, suggestions: [`Visa for ${key.charAt(0).toUpperCase() + key.slice(1)}`, `Flights to ${key.charAt(0).toUpperCase() + key.slice(1)}`] };
    }

    return {
      content: "Which destination are you interested in? I can provide the best travel seasons for popular destinations.",
      suggestions: ["Best time for Bali", "Best time for Japan", "Best time for Thailand"],
    };
  }

  // Flight queries
  if (lower.includes("flight") || lower.includes("fly")) {
    return {
      content: "✈️ **Flight Search**\n\nI can help you find flights! Head to the **Travel** tab to search for available flights, or tell me your origin and destination.",
      suggestions: ["Flights from SFO to SIN", "Cheapest flights to Japan", "Do I need a visa for Singapore?"],
    };
  }

  // Country info
  const countryQueries = ["tell me about", "info about", "information about", "what about"];
  for (const q of countryQueries) {
    if (lower.includes(q)) {
      return {
        content: "I can provide travel insights for any country! Try tapping a country on the **Map** tab, or ask me about visas, weather, or flight options.",
        suggestions: ["Visa for Japan", "Best time for Bali", "Tell me about Singapore"],
      };
    }
  }

  // Greeting
  if (lower.match(/^(hi|hello|hey|good\s)/)) {
    return {
      content: `👋 Hello! I'm your AI travel assistant. I can help with:\n\n🛂 **Visa requirements** — Check if you need a visa\n✈️ **Flight info** — Find routes and durations\n🌍 **Destinations** — Best times to visit\n💡 **Suggestions** — Personalized for you\n\nWhat would you like to know?`,
      suggestions: TRAVEL_SUGGESTIONS,
    };
  }

  // Default
  return {
    content: "I can help with visa requirements, flight information, destination guides, and travel suggestions. Try asking me about a specific country or travel topic!",
    suggestions: TRAVEL_SUGGESTIONS,
  };
}

interface TravelAssistantProps {
  open: boolean;
  onClose: () => void;
}

const TravelAssistant: React.FC<TravelAssistantProps> = ({ open, onClose }) => {
  const { profile } = useUserStore();
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isTyping]);

  const handleSend = (text?: string) => {
    const msg = (text || input).trim();
    if (!msg) return;

    const userMsg: Message = { id: `u-${Date.now()}`, role: "user", content: msg };
    setMessages((prev) => [...prev, userMsg]);
    setInput("");
    setIsTyping(true);

    setTimeout(() => {
      const response = generateResponse(msg, profile.nationality);
      const assistantMsg: Message = {
        id: `a-${Date.now()}`,
        role: "assistant",
        content: response.content,
        suggestions: response.suggestions,
      };
      setMessages((prev) => [...prev, assistantMsg]);
      setIsTyping(false);
    }, 600 + Math.random() * 800);
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[60] flex flex-col">
      <div className="absolute inset-0 bg-background/70 backdrop-blur-md" onClick={onClose} />
      <div className={cn(
        "relative mt-auto w-full max-w-lg mx-auto",
        "glass-premium rounded-t-3xl border-t border-x border-border/40",
        "flex flex-col animate-slide-up max-h-[80dvh]"
      )}>
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-border/30">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-gradient-ocean flex items-center justify-center shadow-glow-sm">
              <Plane className="w-4 h-4 text-primary-foreground" />
            </div>
            <div>
              <span className="font-bold text-foreground text-sm">Travel Assistant</span>
              <p className="text-[10px] text-muted-foreground">Visa · Flights · Destinations</p>
            </div>
          </div>
          <button onClick={onClose} className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-secondary/80 transition-colors">
            <X className="w-4 h-4 text-muted-foreground" />
          </button>
        </div>

        {/* Messages */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-3 hide-scrollbar">
          {messages.length === 0 && (
            <div className="text-center py-8 space-y-4">
              <div className="w-14 h-14 rounded-2xl bg-gradient-ocean/20 flex items-center justify-center mx-auto border border-primary/20">
                <Plane className="w-7 h-7 text-primary" />
              </div>
              <p className="text-muted-foreground text-sm">Ask me about visas, flights, or destinations</p>
              <div className="flex flex-wrap gap-2 justify-center">
                {TRAVEL_SUGGESTIONS.map((s) => (
                  <button
                    key={s}
                    onClick={() => handleSend(s)}
                    className="text-xs px-3.5 py-2 rounded-xl glass border border-border/30 text-muted-foreground hover:text-foreground hover:border-primary/30 transition-all"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((msg) => (
            <div key={msg.id}>
              <div className={cn(
                "max-w-[85%] rounded-2xl px-4 py-3 text-sm animate-scale-in",
                msg.role === "user"
                  ? "ml-auto bg-gradient-ocean text-primary-foreground shadow-glow-sm"
                  : "mr-auto glass-premium border border-border/30 text-foreground"
              )}>
                <p className="whitespace-pre-wrap leading-relaxed">{msg.content}</p>
              </div>
              {msg.suggestions && msg.role === "assistant" && (
                <div className="flex flex-wrap gap-1.5 mt-2 ml-1">
                  {msg.suggestions.map((s) => (
                    <button
                      key={s}
                      onClick={() => handleSend(s)}
                      className="text-[10px] px-2.5 py-1.5 rounded-lg glass border border-border/30 text-muted-foreground hover:text-foreground transition-all"
                    >
                      {s}
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div className="mr-auto glass-premium border border-border/30 rounded-2xl px-4 py-3 animate-scale-in">
              <div className="flex gap-1.5">
                <span className="w-2 h-2 rounded-full bg-primary animate-glow-pulse" style={{ animationDelay: "0ms" }} />
                <span className="w-2 h-2 rounded-full bg-primary animate-glow-pulse" style={{ animationDelay: "200ms" }} />
                <span className="w-2 h-2 rounded-full bg-primary animate-glow-pulse" style={{ animationDelay: "400ms" }} />
              </div>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="p-3 border-t border-border/30">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSend()}
              placeholder="Ask about visas, flights..."
              className="flex-1 bg-secondary/50 rounded-xl px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground outline-none focus:ring-1 focus:ring-primary/50 border border-border/20 transition-all"
            />
            <button
              onClick={() => handleSend()}
              disabled={!input.trim()}
              className="w-11 h-11 rounded-xl bg-gradient-ocean flex items-center justify-center disabled:opacity-30 transition-all active:scale-90 shadow-glow-sm"
            >
              <Send className="w-4 h-4 text-primary-foreground" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TravelAssistant;
