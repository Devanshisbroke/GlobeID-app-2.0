import React from "react";
import { motion } from "framer-motion";
import { useSocialStore } from "@/store/socialStore";
import { cn } from "@/lib/utils";
import { Plus } from "lucide-react";

interface StoriesBarProps {
  onStoryTap?: (storyId: string) => void;
}

const StoriesBar: React.FC<StoriesBarProps> = ({ onStoryTap }) => {
  const { stories, users, markStoryViewed } = useSocialStore();

  const handleTap = (storyId: string) => {
    markStoryViewed(storyId);
    onStoryTap?.(storyId);
  };

  return (
    <div className="flex gap-3 overflow-x-auto hide-scrollbar py-1 px-1">
      {/* Your story */}
      <div className="flex flex-col items-center gap-1 flex-shrink-0">
        <div className="w-16 h-16 rounded-full bg-secondary/50 border-2 border-dashed border-border/50 flex items-center justify-center">
          <Plus className="w-5 h-5 text-muted-foreground" />
        </div>
        <span className="text-[10px] text-muted-foreground font-medium">Your Story</span>
      </div>

      {stories.map((story, i) => {
        const user = users.find((u) => u.id === story.userId);
        if (!user) return null;
        return (
          <motion.button
            key={story.id}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.05 }}
            onClick={() => handleTap(story.id)}
            className="flex flex-col items-center gap-1 flex-shrink-0"
          >
            <div className={cn(
              "w-16 h-16 rounded-full p-[2px]",
              story.viewed
                ? "bg-secondary/50"
                : "bg-gradient-to-br from-primary via-accent to-primary"
            )}>
              <img
                src={user.avatar}
                alt={user.name}
                className="w-full h-full rounded-full object-cover border-2 border-background"
              />
            </div>
            <span className="text-[10px] text-muted-foreground font-medium truncate w-16 text-center">{story.location}</span>
          </motion.button>
        );
      })}
    </div>
  );
};

export default StoriesBar;
