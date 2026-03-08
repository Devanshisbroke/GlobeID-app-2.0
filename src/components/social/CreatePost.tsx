import React, { useState } from "react";
import { motion } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { haptics } from "@/utils/haptics";
import { Camera, MapPin, X, Send, Image, Hash } from "lucide-react";

interface CreatePostProps {
  open: boolean;
  onClose: () => void;
}

const CreatePost: React.FC<CreatePostProps> = ({ open, onClose }) => {
  const [caption, setCaption] = useState("");
  const [location, setLocation] = useState("");

  if (!open) return null;

  const handlePost = () => {
    haptics.success();
    onClose();
    setCaption("");
    setLocation("");
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-end justify-center"
    >
      <div className="absolute inset-0 bg-background/70 backdrop-blur-md" onClick={onClose} />
      <motion.div
        initial={{ y: "100%" }}
        animate={{ y: 0 }}
        exit={{ y: "100%" }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        className="relative w-full max-w-lg glass rounded-t-3xl border-t border-border/30 p-5 pb-8 space-y-4"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold text-foreground">New Post</h2>
          <button onClick={onClose} className="w-8 h-8 rounded-full glass border border-border/30 flex items-center justify-center">
            <X className="w-4 h-4 text-foreground" />
          </button>
        </div>

        {/* Photo placeholder */}
        <div className="w-full aspect-video rounded-xl bg-secondary/30 border-2 border-dashed border-border/40 flex flex-col items-center justify-center gap-2 cursor-pointer hover:border-primary/30 transition-colors">
          <Camera className="w-8 h-8 text-muted-foreground" />
          <span className="text-xs text-muted-foreground">Tap to add photo</span>
        </div>

        {/* Caption */}
        <textarea
          value={caption}
          onChange={(e) => setCaption(e.target.value)}
          placeholder="Write a caption…"
          rows={3}
          className="w-full bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none resize-none"
        />

        {/* Location */}
        <div className="flex items-center gap-2 px-3 py-2.5 rounded-xl glass border border-border/30">
          <MapPin className="w-4 h-4 text-muted-foreground" />
          <input
            value={location}
            onChange={(e) => setLocation(e.target.value)}
            placeholder="Add location…"
            className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none"
          />
        </div>

        {/* Quick tags */}
        <div className="flex gap-2">
          {["travel", "adventure", "food", "sunset"].map((tag) => (
            <button key={tag} className="px-2.5 py-1 rounded-full bg-primary/10 text-primary text-[10px] font-medium border border-primary/20">
              <Hash className="w-2.5 h-2.5 inline mr-0.5" />{tag}
            </button>
          ))}
        </div>

        {/* Post button */}
        <button
          onClick={handlePost}
          disabled={!caption.trim()}
          className="w-full py-3 rounded-xl bg-primary text-primary-foreground text-sm font-semibold flex items-center justify-center gap-2 shadow-glow-sm disabled:opacity-40"
        >
          <Send className="w-4 h-4" /> Share Post
        </button>
      </motion.div>
    </motion.div>
  );
};

export default CreatePost;
