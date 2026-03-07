import { useState, useCallback } from "react";

export interface AIMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
  actions?: { label: string; route?: string }[];
}

const DEMO_REPLIES: Record<string, AIMessage> = {
  "Find best hotels near my meeting": {
    id: "ai-1",
    role: "assistant",
    content:
      "I found 3 highly-rated hotels near your meeting at Marina Bay:\n\n1. 🏨 The Fullerton — $280/night, 4.8★\n2. 🏨 Mandarin Oriental — $320/night, 4.9★\n3. 🏨 Ritz-Carlton — $450/night, 4.9★\n\nWant me to book one?",
    timestamp: new Date(),
    actions: [{ label: "Book Fullerton", route: "/travel" }],
  },
  "Convert 100 USD to INR and show balance": {
    id: "ai-2",
    role: "assistant",
    content:
      "💱 100 USD = ₹8,340.50 INR (rate: 83.405)\n\nYour updated balance:\n• USD: $4,900.00\n• INR: ₹58,340.50\n\nTransfer confirmed to your INR wallet.",
    timestamp: new Date(),
    actions: [{ label: "View Wallet", route: "/wallet" }],
  },
  "Summarize my trips this month": {
    id: "ai-3",
    role: "assistant",
    content:
      "📊 March 2026 Travel Summary:\n\n✈️ 2 flights (SFO→SIN, SIN→BOM)\n🏨 3 hotel nights (Marina Bay Sands)\n🚗 4 rides (total $62)\n🍽️ 8 food orders ($185)\n\nTotal spend: $2,847",
    timestamp: new Date(),
    actions: [{ label: "View Details", route: "/travel" }],
  },
};

const FALLBACK_REPLY: AIMessage = {
  id: "ai-fallback",
  role: "assistant",
  content:
    "I understand your request! In the full version, I'd help with that right away. For now, try one of the quick suggestions to see what I can do. 🚀",
  timestamp: new Date(),
};

export function useAI() {
  const [messages, setMessages] = useState<AIMessage[]>([]);
  const [isTyping, setIsTyping] = useState(false);

  const sendMessage = useCallback((content: string) => {
    const userMsg: AIMessage = {
      id: `user-${Date.now()}`,
      role: "user",
      content,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setIsTyping(true);

    setTimeout(() => {
      const reply = DEMO_REPLIES[content] || {
        ...FALLBACK_REPLY,
        id: `ai-${Date.now()}`,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, reply]);
      setIsTyping(false);
    }, 1200);
  }, []);

  const clearMessages = useCallback(() => setMessages([]), []);

  return { messages, isTyping, sendMessage, clearMessages };
}

export const AI_SUGGESTIONS = [
  "Find best hotels near my meeting",
  "Convert 100 USD to INR and show balance",
  "Summarize my trips this month",
];
