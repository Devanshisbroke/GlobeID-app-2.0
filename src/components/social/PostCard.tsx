import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useSocialStore } from "@/store/socialStore";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { Heart, MessageCircle, Share2, MapPin, MoreHorizontal, Bookmark } from "lucide-react";

interface PostCardProps {
  postId: string;
  onLocationTap?: (iata: string) => void;
  onProfileTap?: (userId: string) => void;
}

const PostCard: React.FC<PostCardProps> = ({ postId, onLocationTap, onProfileTap }) => {
  const { posts, users, likedPosts, toggleLike, addComment } = useSocialStore();
  const post = posts.find((p) => p.id === postId);
  const user = post ? users.find((u) => u.id === post.userId) : undefined;
  const [showComments, setShowComments] = useState(false);
  const [commentText, setCommentText] = useState("");
  const [showHeart, setShowHeart] = useState(false);

  if (!post || !user) return null;

  const isLiked = likedPosts.includes(post.id);

  const handleDoubleTap = () => {
    if (!isLiked) toggleLike(post.id);
    setShowHeart(true);
    haptics.success();
    setTimeout(() => setShowHeart(false), 800);
  };

  const handleComment = () => {
    if (!commentText.trim()) return;
    addComment(post.id, commentText.trim());
    setCommentText("");
    haptics.selection();
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 280, damping: 24 }}
      className="glass rounded-2xl border border-border/30 overflow-hidden"
    >
      {/* Header */}
      <div className="flex items-center gap-3 px-4 py-3">
        <button onClick={() => onProfileTap?.(user.id)} className="w-9 h-9 rounded-full overflow-hidden ring-2 ring-primary/20">
          <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1">
            <span className="text-sm font-semibold text-foreground">{user.name}</span>
            {user.verified && <span className="w-3.5 h-3.5 rounded-full bg-primary flex items-center justify-center text-[8px] text-primary-foreground font-bold">✓</span>}
          </div>
          <button
            onClick={() => post.iata && onLocationTap?.(post.iata)}
            className="text-[11px] text-muted-foreground flex items-center gap-0.5 hover:text-primary transition-colors"
          >
            <MapPin className="w-2.5 h-2.5" /> {post.location}
          </button>
        </div>
        <button className="w-8 h-8 rounded-full hover:bg-secondary/50 flex items-center justify-center">
          <MoreHorizontal className="w-4 h-4 text-muted-foreground" />
        </button>
      </div>

      {/* Image */}
      <div className="relative" onDoubleClick={handleDoubleTap}>
        <img src={post.image} alt={post.caption} className="w-full aspect-square object-cover" loading="lazy" />
        <AnimatePresence>
          {showHeart && (
            <motion.div
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 1.5, opacity: 0 }}
              className="absolute inset-0 flex items-center justify-center"
            >
              <Heart className="w-20 h-20 fill-white text-white drop-shadow-lg" />
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Actions */}
      <div className="px-4 pt-3 pb-2">
        <div className="flex items-center gap-4 mb-2">
          <button onClick={() => { toggleLike(post.id); haptics.selection(); }}>
            <Heart className={cn("w-6 h-6 transition-all", isLiked ? "fill-destructive text-destructive scale-110" : "text-foreground")} />
          </button>
          <button onClick={() => setShowComments(!showComments)}>
            <MessageCircle className="w-6 h-6 text-foreground" />
          </button>
          <button><Share2 className="w-5 h-5 text-foreground" /></button>
          <div className="flex-1" />
          <button><Bookmark className="w-5 h-5 text-foreground" /></button>
        </div>

        <p className="text-sm font-semibold text-foreground">{post.likes.toLocaleString()} likes</p>
        <p className="text-sm text-foreground mt-1">
          <span className="font-semibold">{user.handle}</span>{" "}
          {post.caption}
        </p>
        {post.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-1.5">
            {post.tags.map((tag) => (
              <span key={tag} className="text-[11px] text-primary font-medium">#{tag}</span>
            ))}
          </div>
        )}
        <p className="text-[10px] text-muted-foreground mt-1.5 uppercase tracking-wider">{post.createdAt}</p>
      </div>

      {/* Comments */}
      <AnimatePresence>
        {showComments && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="overflow-hidden border-t border-border/20"
          >
            <div className="px-4 py-2 space-y-2 max-h-32 overflow-y-auto">
              {post.comments.map((c) => {
                const commentUser = users.find((u) => u.id === c.userId);
                return (
                  <div key={c.id} className="flex gap-2 text-sm">
                    <span className="font-semibold text-foreground">{commentUser?.handle || "you"}</span>
                    <span className="text-foreground/80">{c.text}</span>
                  </div>
                );
              })}
            </div>
            <div className="flex items-center gap-2 px-4 py-2 border-t border-border/20">
              <input
                value={commentText}
                onChange={(e) => setCommentText(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleComment()}
                placeholder="Add a comment…"
                className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none"
              />
              <button onClick={handleComment} className="text-xs font-semibold text-primary">Post</button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
};

export default PostCard;
