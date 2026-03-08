import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { useSocialStore } from "@/store/socialStore";
import PostCard from "@/components/social/PostCard";
import StoriesBar from "@/components/social/StoriesBar";
import CreatePost from "@/components/social/CreatePost";
import Notifications from "@/components/social/Notifications";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { Plus, Bell, Compass, Trophy } from "lucide-react";

type Tab = "feed" | "notifications" | "leaderboard";

const SocialFeed: React.FC = () => {
  const navigate = useNavigate();
  const { posts, unreadCount } = useSocialStore();
  const [tab, setTab] = useState<Tab>("feed");
  const [showCreate, setShowCreate] = useState(false);
  const { users } = useSocialStore();
  const { leaderboard: lb } = require("@/store/socialStore");

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: "feed", label: "Feed", icon: Compass },
    { key: "notifications", label: "Alerts", icon: Bell },
    { key: "leaderboard", label: "Ranking", icon: Trophy },
  ];

  return (
    <div className="px-4 py-6 pb-28 space-y-4">
      <AnimatedPage>
        <div className="flex items-center justify-between mb-1">
          <h1 className="text-xl font-bold text-foreground">Travel Feed</h1>
          <div className="flex items-center gap-2">
            <button
              onClick={() => navigate("/explore")}
              className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center"
            >
              <Compass className="w-4 h-4 text-foreground" />
            </button>
            <button
              onClick={() => { setShowCreate(true); haptics.selection(); }}
              className="w-9 h-9 rounded-xl bg-primary text-primary-foreground flex items-center justify-center shadow-glow-sm"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>
        </div>
      </AnimatedPage>

      {/* Tabs */}
      <AnimatedPage staggerIndex={0}>
        <div className="flex gap-1 p-1 rounded-2xl glass border border-border/40">
          {tabs.map((t) => {
            const Icon = t.icon;
            const active = tab === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={cn(
                  "flex-1 flex items-center justify-center gap-1.5 py-2 rounded-xl text-xs font-semibold transition-all relative",
                  active ? "bg-primary text-primary-foreground shadow-depth-sm" : "text-muted-foreground"
                )}
              >
                <Icon className="w-3.5 h-3.5" />
                {t.label}
                {t.key === "notifications" && unreadCount() > 0 && (
                  <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-destructive text-destructive-foreground text-[8px] font-bold flex items-center justify-center">
                    {unreadCount()}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {tab === "feed" && (
        <div className="space-y-4">
          {/* Stories */}
          <AnimatedPage staggerIndex={1}>
            <StoriesBar />
          </AnimatedPage>

          {/* Posts */}
          {posts.map((post, i) => (
            <AnimatedPage key={post.id} staggerIndex={i + 2}>
              <PostCard
                postId={post.id}
                onProfileTap={(userId) => navigate(`/profile/${userId}`)}
                onLocationTap={() => navigate("/map")}
              />
            </AnimatedPage>
          ))}
        </div>
      )}

      {tab === "notifications" && (
        <AnimatedPage>
          <Notifications />
        </AnimatedPage>
      )}

      {tab === "leaderboard" && (
        <div className="space-y-2">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Top Travelers</h3>
          {(lb as any[]).map((entry: any, i: number) => {
            const user = users.find((u) => u.id === entry.userId);
            if (!user) return null;
            return (
              <AnimatedPage key={entry.userId} staggerIndex={i}>
                <motion.div className="flex items-center gap-3 px-3 py-3 rounded-xl glass border border-border/30">
                  <span className={cn(
                    "w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold",
                    i === 0 ? "bg-neon-amber/20 text-neon-amber" :
                    i === 1 ? "bg-secondary text-foreground" :
                    i === 2 ? "bg-orange-500/20 text-orange-400" :
                    "bg-secondary/50 text-muted-foreground"
                  )}>
                    {entry.rank}
                  </span>
                  <img src={user.avatar} alt={user.name} className="w-9 h-9 rounded-full object-cover" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-foreground">{user.name}</p>
                    <p className="text-[10px] text-muted-foreground">{entry.countries} countries · Score {entry.score}</p>
                  </div>
                  {user.verified && (
                    <span className="px-2 py-0.5 rounded-full bg-primary/10 text-primary text-[9px] font-bold">Verified</span>
                  )}
                </motion.div>
              </AnimatedPage>
            );
          })}
        </div>
      )}

      <AnimatePresence>
        {showCreate && <CreatePost open={showCreate} onClose={() => setShowCreate(false)} />}
      </AnimatePresence>
    </div>
  );
};

export default SocialFeed;
