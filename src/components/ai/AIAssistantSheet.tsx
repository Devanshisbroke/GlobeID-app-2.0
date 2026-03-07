import React, { useState, useRef, useEffect } from "react";
import { cn } from "@/lib/utils";
import { useAI, AI_SUGGESTIONS } from "@/hooks/useAI";
import { Send, X, Sparkles } from "lucide-react";

interface AIAssistantSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const AIAssistantSheet: React.FC<AIAssistantSheetProps> = ({
  open,
  onOpenChange,
}) => {
  const { messages, isTyping, sendMessage, clearMessages } = useAI();
  const [input, setInput] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isTyping]);

  const handleSend = () => {
    const text = input.trim();
    if (!text) return;
    sendMessage(text);
    setInput("");
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[60] flex flex-col">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-background/70 backdrop-blur-md"
        onClick={() => onOpenChange(false)}
      />

      {/* Sheet */}
      <div
        className={cn(
          "relative mt-auto w-full max-w-lg mx-auto",
          "glass-premium rounded-t-3xl border-t border-x border-border/40",
          "flex flex-col",
          "animate-slide-up",
          "max-h-[80dvh]"
        )}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-border/30">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-neon-indigo to-neon-cyan flex items-center justify-center shadow-glow-sm">
              <Sparkles className="w-4 h-4 text-primary-foreground" />
            </div>
            <div>
              <span className="font-bold text-foreground text-sm">GlobeID AI</span>
              <p className="text-[10px] text-muted-foreground">Travel · Payments · Identity</p>
            </div>
          </div>
          <button
            onClick={() => {
              onOpenChange(false);
              clearMessages();
            }}
            aria-label="Close assistant"
            className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-secondary/80 transition-colors"
          >
            <X className="w-4 h-4 text-muted-foreground" />
          </button>
        </div>

        {/* Messages */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-3 hide-scrollbar">
          {messages.length === 0 && (
            <div className="text-center py-8 space-y-4">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-neon-indigo/20 to-neon-cyan/20 flex items-center justify-center mx-auto border border-accent/20">
                <Sparkles className="w-7 h-7 text-accent" />
              </div>
              <p className="text-muted-foreground text-sm">
                Ask me anything about travel, identity, or payments
              </p>
              <div className="flex flex-wrap gap-2 justify-center">
                {AI_SUGGESTIONS.map((s) => (
                  <button
                    key={s}
                    onClick={() => sendMessage(s)}
                    className="text-xs px-3.5 py-2 rounded-xl glass border border-border/30 text-muted-foreground hover:text-foreground hover:border-accent/30 hover:shadow-glow-sm transition-all"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((msg) => (
            <div
              key={msg.id}
              className={cn(
                "max-w-[85%] rounded-2xl px-4 py-3 text-sm animate-scale-in",
                msg.role === "user"
                  ? "ml-auto bg-gradient-to-r from-primary to-neon-indigo text-primary-foreground shadow-glow-indigo"
                  : "mr-auto glass-premium border border-border/30 text-foreground"
              )}
            >
              <p className="whitespace-pre-wrap leading-relaxed">{msg.content}</p>
              {msg.actions && (
                <div className="flex gap-2 mt-2.5">
                  {msg.actions.map((a) => (
                    <button
                      key={a.label}
                      className="text-xs px-3 py-1.5 rounded-full bg-accent/15 text-accent font-semibold hover:bg-accent/25 transition-colors"
                    >
                      {a.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div className="mr-auto glass-premium border border-border/30 rounded-2xl px-4 py-3 animate-scale-in">
              <div className="flex gap-1.5">
                <span className="w-2 h-2 rounded-full bg-accent animate-glow-pulse" style={{ animationDelay: "0ms" }} />
                <span className="w-2 h-2 rounded-full bg-accent animate-glow-pulse" style={{ animationDelay: "200ms" }} />
                <span className="w-2 h-2 rounded-full bg-accent animate-glow-pulse" style={{ animationDelay: "400ms" }} />
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
              placeholder="Ask GlobeID AI..."
              className="flex-1 bg-secondary/50 rounded-xl px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground outline-none focus:ring-1 focus:ring-accent/50 border border-border/20 transition-all"
            />
            <button
              onClick={handleSend}
              disabled={!input.trim()}
              aria-label="Send message"
              className="w-11 h-11 rounded-xl bg-gradient-to-r from-neon-indigo to-neon-cyan flex items-center justify-center disabled:opacity-30 transition-all active:scale-90 shadow-glow-sm"
            >
              <Send className="w-4 h-4 text-primary-foreground" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export { AIAssistantSheet };
