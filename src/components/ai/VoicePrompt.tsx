import React from "react";
import { motion } from "framer-motion";
import { Mic, MicOff } from "lucide-react";
import { cn } from "@/lib/utils";

interface VoicePromptProps {
  onTranscript?: (text: string) => void;
}

const VoicePrompt: React.FC<VoicePromptProps> = ({ onTranscript }) => {
  const [listening, setListening] = React.useState(false);

  const toggle = () => {
    setListening((prev) => {
      if (!prev) {
        // Simulate voice input after 2s
        setTimeout(() => {
          onTranscript?.("Plan a 10 day Asia trip");
          setListening(false);
        }, 2000);
      }
      return !prev;
    });
  };

  return (
    <motion.button
      whileTap={{ scale: 0.9 }}
      onClick={toggle}
      className={cn(
        "w-10 h-10 rounded-xl flex items-center justify-center transition-all",
        listening
          ? "bg-destructive/15 border border-destructive/30 text-destructive"
          : "glass border border-border/30 text-muted-foreground hover:text-foreground"
      )}
    >
      {listening ? (
        <motion.div animate={{ scale: [1, 1.2, 1] }} transition={{ repeat: Infinity, duration: 1 }}>
          <MicOff className="w-4 h-4" />
        </motion.div>
      ) : (
        <Mic className="w-4 h-4" />
      )}
    </motion.button>
  );
};

export default VoicePrompt;
