import React from "react";
import { useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useSocialStore } from "@/store/socialStore";
import PostCard from "@/components/social/PostCard";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { ArrowLeft, MapPin, Globe2, Award, UserPlus, UserCheck, Heart } from "lucide-react";

const UserProfile: React.FC = () => {
  const navigate = useNavigate();
  const { userId } = useParams<{ userId: string }>();
  const { users, posts, following, toggleFollow } = useSocialStore();

  const user = users.find((u) => u.id === userId);
  const userPosts = posts.filter((p) => p.userId === userId);
  const isFollowing = userId ? following.includes(userId) : false;

  if (!user) {
    return (
      <div className="px-4 py-6">
        <AnimatedPage>
          <p className="text-muted-foreground text-center py-20">User not found</p>
        </AnimatedPage>
      </div>
    );
  }

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <h1 className="text-xl font-bold text-foreground flex-1">{user.name}</h1>
        </div>
      </AnimatedPage>

      {/* Profile header */}
      <AnimatedPage staggerIndex={0}>
        <GlassCard interactive={false} variant="premium" depth="lg" className="text-center">
          <div className="flex flex-col items-center gap-3">
            <div className="relative">
              <img src={user.avatar} alt={user.name} className="w-20 h-20 rounded-full object-cover ring-3 ring-primary/20" />
              {user.verified && (
                <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-primary flex items-center justify-center text-[10px] text-primary-foreground font-bold shadow-glow-sm">✓</div>
              )}
            </div>
            <div>
              <p className="text-lg font-bold text-foreground">{user.name}</p>
              <p className="text-xs text-muted-foreground">{user.handle}</p>
              <p className="text-sm text-foreground/80 mt-1">{user.bio}</p>
            </div>

            {/* Stats */}
            <div className="flex gap-6 py-2">
              <div className="text-center">
                <p className="text-lg font-bold text-foreground">{user.countriesVisited}</p>
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Countries</p>
              </div>
              <div className="text-center">
                <p className="text-lg font-bold text-foreground">{user.travelScore}</p>
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Score</p>
              </div>
              <div className="text-center">
                <p className="text-lg font-bold text-foreground">{userPosts.length}</p>
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Posts</p>
              </div>
            </div>

            {/* Follow button */}
            <button
              onClick={() => { toggleFollow(user.id); haptics.selection(); }}
              className={cn(
                "px-6 py-2.5 rounded-xl text-sm font-semibold flex items-center gap-2 transition-all",
                isFollowing
                  ? "glass border border-border/30 text-foreground"
                  : "bg-primary text-primary-foreground shadow-glow-sm"
              )}
            >
              {isFollowing ? <><UserCheck className="w-4 h-4" /> Following</> : <><UserPlus className="w-4 h-4" /> Follow</>}
            </button>
          </div>
        </GlassCard>
      </AnimatedPage>

      {/* Posts grid */}
      {userPosts.length > 0 && (
        <div className="space-y-2">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Posts</h3>
          <div className="grid grid-cols-3 gap-1 rounded-xl overflow-hidden">
            {userPosts.map((post, i) => (
              <motion.div
                key={post.id}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.06 }}
                className="aspect-square relative group cursor-pointer"
                onClick={() => navigate("/social")}
              >
                <img src={post.image} alt="" className="w-full h-full object-cover" loading="lazy" />
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/30 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100">
                  <span className="text-white text-xs font-medium flex items-center gap-1">
                    <Heart className="w-3 h-3 fill-white" /> {post.likes}
                  </span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      )}

      {/* Full posts */}
      <div className="space-y-4">
        {userPosts.map((post, i) => (
          <AnimatedPage key={post.id} staggerIndex={i + 1}>
            <PostCard postId={post.id} onLocationTap={() => navigate("/map")} />
          </AnimatedPage>
        ))}
      </div>
    </div>
  );
};

export default UserProfile;
