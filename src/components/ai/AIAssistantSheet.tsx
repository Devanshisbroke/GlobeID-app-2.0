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
        className="absolute inset-0 bg-background/80 backdrop-blur-sm"
        onClick={() => onOpenChange(false)}
      />

      {/* Sheet */}
      <div
        className={cn(
          "relative mt-auto w-full max-w-lg mx-auto",
          "glass rounded-t-3xl border-t border-x border-border",
          "flex flex-col",
          "animate-slide-up",
          "max-h-[75dvh]"
        )}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-border">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-neon-cyan" />
            <span className="font-semibold text-foreground">GlobeID AI</span>
          </div>
          <button
            onClick={() => {
              onOpenChange(false);
              clearMessages();
            }}
            aria-label="Close assistant"
            className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-secondary transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Messages */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-3 hide-scrollbar">
          {messages.length === 0 && (
            <div className="text-center py-8 space-y-4">
              <Sparkles className="w-10 h-10 mx-auto text-neon-cyan opacity-60" />
              <p className="text-muted-foreground text-sm">
                Ask me anything about travel, identity, or payments
              </p>
              <div className="flex flex-wrap gap-2 justify-center">
                {AI_SUGGESTIONS.map((s) => (
                  <button
                    key={s}
                    onClick={() => sendMessage(s)}
                    className="text-xs px-3 py-1.5 rounded-full glass border border-border text-muted-foreground hover:text-foreground transition-colors"
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
                "max-w-[85%] rounded-2xl px-3.5 py-2.5 text-sm animate-scale-in",
                msg.role === "user"
                  ? "ml-auto bg-primary text-primary-foreground"
                  : "mr-auto glass border border-border text-foreground"
              )}
            >
              <p className="whitespace-pre-wrap leading-relaxed">{msg.content}</p>
              {msg.actions && (
                <div className="flex gap-2 mt-2">
                  {msg.actions.map((a) => (
                    <button
                      key={a.label}
                      className="text-xs px-2.5 py-1 rounded-full bg-accent/20 text-accent font-medium"
                    >
                      {a.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div className="mr-auto glass border border-border rounded-2xl px-4 py-3 animate-scale-in">
              <div className="flex gap-1">
                <span className="w-2 h-2 rounded-full bg-muted-foreground animate-glow-pulse" style={{ animationDelay: "0ms" }} />
                <span className="w-2 h-2 rounded-full bg-muted-foreground animate-glow-pulse" style={{ animationDelay: "200ms" }} />
                <span className="w-2 h-2 rounded-full bg-muted-foreground animate-glow-pulse" style={{ animationDelay: "400ms" }} />
              </div>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="p-3 border-t border-border">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSend()}
              placeholder="Ask GlobeID AI..."
              className="flex-1 bg-secondary rounded-xl px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground outline-none focus:ring-1 focus:ring-accent"
            />
            <button
              onClick={handleSend}
              disabled={!input.trim()}
              aria-label="Send message"
              className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center disabled:opacity-40 transition-opacity active:scale-90"
            >
              <Send className="w-4 h-4 text-accent-foreground" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export { AIAssistantSheet };
