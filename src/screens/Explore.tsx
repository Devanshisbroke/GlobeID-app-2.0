import React from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { trendingDestinations, useSocialStore } from "@/store/socialStore";
import { cn } from "@/lib/utils";
import { ArrowLeft, TrendingUp, MapPin, Heart, Search } from "lucide-react";
import { useState } from "react";

const Explore: React.FC = () => {
  const navigate = useNavigate();
  const { posts, users } = useSocialStore();
  const [search, setSearch] = useState("");

  const filtered = search
    ? trendingDestinations.filter((d) =>
        d.name.toLowerCase().includes(search.toLowerCase()) ||
        d.country.toLowerCase().includes(search.toLowerCase())
      )
    : trendingDestinations;

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-foreground">Explore</h1>
            <p className="text-xs text-muted-foreground">Discover trending destinations</p>
          </div>
        </div>
      </AnimatedPage>

      {/* Search */}
      <AnimatedPage staggerIndex={0}>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search destinations…"
            className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border/40 text-sm bg-transparent focus:outline-none focus:ring-2 focus:ring-primary/30 placeholder:text-muted-foreground"
          />
        </div>
      </AnimatedPage>

      {/* Trending grid */}
      <div className="space-y-2">
        <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest flex items-center gap-1.5">
          <TrendingUp className="w-3 h-3 text-primary" /> Trending Now
        </h3>
        <div className="grid grid-cols-2 gap-3">
          {filtered.map((dest, i) => (
            <AnimatedPage key={dest.name} staggerIndex={i + 1}>
              <GlassCard interactive={false} className="overflow-hidden p-0 cursor-pointer" depth="md">
                <div className="relative">
                  <img src={dest.image} alt={dest.name} className="w-full h-32 object-cover" loading="lazy" />
                  <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                  <div className="absolute bottom-2 left-2 right-2">
                    <p className="text-sm font-bold text-foreground">{dest.name}</p>
                    <p className="text-[10px] text-muted-foreground flex items-center gap-0.5">
                      <MapPin className="w-2.5 h-2.5" /> {dest.country}
                    </p>
                  </div>
                </div>
                <div className="px-3 py-2 flex items-center justify-between">
                  <span className="text-[10px] text-muted-foreground">{(dest.posts / 1000).toFixed(1)}k posts</span>
                  <Heart className="w-3.5 h-3.5 text-muted-foreground" />
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      </div>

      {/* Recent posts grid */}
      <div className="space-y-2">
        <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Recent Posts</h3>
        <div className="grid grid-cols-3 gap-1 rounded-xl overflow-hidden">
          {posts.map((post, i) => (
            <motion.div
              key={post.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => navigate("/social")}
              className="aspect-square cursor-pointer relative group"
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
    </div>
  );
};

export default Explore;
