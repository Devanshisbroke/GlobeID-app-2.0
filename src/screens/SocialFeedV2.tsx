/**
 * Slice-E — real social feed (IndexedDB-backed CRUD).
 *
 * Separate from the existing curated explore feed (`SocialFeed`). This
 * screen renders the user's own posts + lets them create, edit, like,
 * comment, and delete in a persistent local-first store.
 *
 * UX:
 *  - New-post composer at top (caption + optional image upload).
 *  - Post list sorted newest-first.
 *  - Each post shows like count (live from likes table), comment count,
 *    and an inline expandable comment thread.
 */
import React, { useCallback, useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  ArrowLeft,
  Heart,
  MessageCircle,
  Send,
  Trash2,
  ImagePlus,
  RefreshCw,
} from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useUserFeedStore } from "@/store/userFeedStore";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";
import { REACTIONS, type ReactionKind } from "@/lib/socialDB";
import { usePullToRefresh } from "@/hooks/usePullToRefresh";

const REACTION_GLYPH: Record<ReactionKind, string> = {
  like: "👍",
  love: "❤️",
  clap: "👏",
  plane: "✈️",
  fire: "🔥",
};

const PAGE_SIZE = 8;

const SocialFeedV2: React.FC = () => {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const user = useUserStore((s) => s.user);
  const posts = useUserFeedStore((s) => s.posts);
  const status = useUserFeedStore((s) => s.status);
  const hydrated = useUserFeedStore((s) => s.hydrated);
  const hydrate = useUserFeedStore((s) => s.hydrate);
  const createPost = useUserFeedStore((s) => s.createPost);
  const deletePost = useUserFeedStore((s) => s.deletePost);
  const toggleLike = useUserFeedStore((s) => s.toggleLike);
  const hasLiked = useUserFeedStore((s) => s.hasLiked);
  const likesFor = useUserFeedStore((s) => s.likesFor);
  const commentsFor = useUserFeedStore((s) => s.commentsFor);
  const addComment = useUserFeedStore((s) => s.addComment);
  const deleteComment = useUserFeedStore((s) => s.deleteComment);
  const toggleReaction = useUserFeedStore((s) => s.toggleReaction);
  const hasReaction = useUserFeedStore((s) => s.hasReaction);
  const reactionsFor = useUserFeedStore((s) => s.reactionsFor);
  const getMediaUrl = useUserFeedStore((s) => s.getMediaUrl);

  const [caption, setCaption] = useState("");
  const [location, setLocation] = useState("");
  const [imageBlob, setImageBlob] = useState<Blob | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [expandedPost, setExpandedPost] = useState<string | null>(null);
  const [commentDrafts, setCommentDrafts] = useState<Record<string, string>>({});
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [mediaUrls, setMediaUrls] = useState<Record<string, string>>({});
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const loadMoreSentinelRef = useRef<HTMLDivElement | null>(null);

  const pull = usePullToRefresh({
    onRefresh: async () => {
      await hydrate();
    },
  });

  useEffect(() => {
    if (!hydrated) void hydrate();
  }, [hydrated, hydrate]);

  const meId = user?.id ?? "me";
  const meName = user?.name ?? "Me";

  const handlePickImage = useCallback(() => {
    fileInputRef.current?.click();
  }, []);

  const handleFileChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const f = e.target.files?.[0];
      if (!f) return;
      setImageBlob(f);
      setImagePreview(URL.createObjectURL(f));
    },
    [],
  );

  const handlePost = useCallback(async () => {
    if (!caption.trim()) return;
    await createPost({
      authorId: meId,
      authorName: meName,
      caption: caption.trim(),
      location: location.trim() || undefined,
      imageBlob: imageBlob ?? undefined,
    });
    setCaption("");
    setLocation("");
    setImageBlob(null);
    if (imagePreview) URL.revokeObjectURL(imagePreview);
    setImagePreview(null);
  }, [caption, location, imageBlob, imagePreview, createPost, meId, meName]);

  const handleComment = useCallback(
    async (postId: string) => {
      const text = (commentDrafts[postId] ?? "").trim();
      if (!text) return;
      await addComment(postId, meId, meName, text);
      setCommentDrafts((d) => ({ ...d, [postId]: "" }));
    },
    [commentDrafts, addComment, meId, meName],
  );

  // Resolve mediaBlobs to object URLs for the posts currently in view.
  useEffect(() => {
    let cancelled = false;
    const visiblePosts = posts.slice(0, visibleCount);
    void (async () => {
      for (const p of visiblePosts) {
        if (!p.mediaId || mediaUrls[p.mediaId]) continue;
        const url = await getMediaUrl(p.mediaId);
        if (cancelled || !url) continue;
        setMediaUrls((m) => ({ ...m, [p.mediaId!]: url }));
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [posts, visibleCount, getMediaUrl, mediaUrls]);

  // Infinite scroll: bump `visibleCount` when sentinel enters viewport.
  useEffect(() => {
    const el = loadMoreSentinelRef.current;
    if (!el) return;
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setVisibleCount((c) => Math.min(posts.length, c + PAGE_SIZE));
          }
        }
      },
      { rootMargin: "200px" },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [posts.length]);

  const visiblePosts = posts.slice(0, visibleCount);

  return (
    <div className="px-4 py-6 pb-28 space-y-4" {...pull.bind()}>
      {(pull.progress > 0 || pull.refreshing) && (
        <div className="flex items-center justify-center text-xs text-muted-foreground py-1">
          <RefreshCw
            className={cn(
              "w-3 h-3 mr-1 transition-transform",
              pull.refreshing && "animate-spin",
            )}
            style={{ transform: `rotate(${pull.progress * 180}deg)` }}
          />
          {pull.refreshing
            ? "Refreshing…"
            : pull.armed
              ? "Release to refresh"
              : "Pull to refresh"}
        </div>
      )}
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button
            onClick={() => navigate(-1)}
            className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center"
          >
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">{t("nav.social")}</h1>
            <p className="text-xs text-muted-foreground">Your posts · stored on-device</p>
          </div>
        </div>
      </AnimatedPage>

      <GlassCard className="p-4 space-y-2">
        <Textarea
          value={caption}
          onChange={(e) => setCaption(e.target.value)}
          placeholder="What's happening on your trip?"
          rows={3}
          className="text-sm resize-none"
        />
        <Input
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          placeholder="Location (optional)"
          className="text-sm"
        />
        {imagePreview && (
          <div className="relative">
            <img
              src={imagePreview}
              alt=""
              className="w-full max-h-52 object-cover rounded-lg"
            />
            <button
              onClick={() => {
                setImageBlob(null);
                if (imagePreview) URL.revokeObjectURL(imagePreview);
                setImagePreview(null);
              }}
              className="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-black/60 text-white text-[10px]"
            >
              Remove
            </button>
          </div>
        )}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={handleFileChange}
        />
        <div className="flex gap-2">
          <Button
            size="sm"
            variant="outline"
            onClick={handlePickImage}
            className="flex-1"
          >
            <ImagePlus className="w-3 h-3 mr-1" />
            {imageBlob ? "Replace image" : "Add image"}
          </Button>
          <Button
            size="sm"
            onClick={handlePost}
            disabled={!caption.trim() || status === "pending"}
            className="flex-1"
          >
            <Send className="w-3 h-3 mr-1" />
            {status === "pending" ? "Posting…" : "Post"}
          </Button>
        </div>
      </GlassCard>

      {posts.length === 0 ? (
        <GlassCard className="p-6 text-center">
          <p className="text-sm text-muted-foreground">No posts yet — share your first trip update.</p>
        </GlassCard>
      ) : (
        visiblePosts.map((p) => {
          const liked = hasLiked(meId, p.id);
          const likes = likesFor(p.id);
          const comments = commentsFor(p.id);
          const expanded = expandedPost === p.id;
          const reactionCounts = reactionsFor(p.id);
          const mediaUrl = p.mediaId ? mediaUrls[p.mediaId] : null;
          return (
            <GlassCard key={p.id} className="p-4 space-y-3">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-sm font-bold text-primary">
                  {p.authorName.slice(0, 1)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-foreground">{p.authorName}</p>
                  <p className="text-[11px] text-muted-foreground">
                    {p.location ?? "On the road"} · {new Date(p.createdAt).toLocaleString()}
                  </p>
                </div>
                {p.authorId === meId && (
                  <button
                    onClick={() => deletePost(p.id)}
                    className="text-[11px] text-destructive hover:underline flex items-center gap-1"
                  >
                    <Trash2 className="w-3 h-3" /> Delete
                  </button>
                )}
              </div>
              <p className="text-sm text-foreground whitespace-pre-wrap">{p.caption}</p>
              {mediaUrl && (
                <img
                  src={mediaUrl}
                  alt=""
                  loading="lazy"
                  className="w-full max-h-80 object-cover rounded-lg"
                />
              )}
              <div className="flex flex-wrap gap-1.5">
                {REACTIONS.map((kind) => {
                  const on = hasReaction(meId, p.id, kind);
                  return (
                    <button
                      key={kind}
                      onClick={() => toggleReaction(meId, p.id, kind)}
                      className={cn(
                        "px-2 py-1 rounded-full text-xs border transition",
                        on
                          ? "bg-primary/15 border-primary text-foreground"
                          : "bg-transparent border-border/40 text-muted-foreground hover:border-primary/40",
                      )}
                    >
                      <span className="mr-1">{REACTION_GLYPH[kind]}</span>
                      <span>{reactionCounts[kind]}</span>
                    </button>
                  );
                })}
              </div>
              <div className="flex items-center gap-4 text-xs">
                <button
                  onClick={() => toggleLike(meId, p.id)}
                  className={cn(
                    "flex items-center gap-1 transition-colors",
                    liked ? "text-rose-400" : "text-muted-foreground hover:text-foreground",
                  )}
                >
                  <Heart className={cn("w-4 h-4", liked && "fill-current")} />
                  <span>{likes}</span>
                </button>
                <button
                  onClick={() => setExpandedPost(expanded ? null : p.id)}
                  className="flex items-center gap-1 text-muted-foreground hover:text-foreground"
                >
                  <MessageCircle className="w-4 h-4" />
                  <span>{comments.length}</span>
                </button>
              </div>
              {expanded && (
                <div className="pt-2 border-t border-border/30 space-y-2">
                  {comments.map((c) => (
                    <div key={c.id} className="flex items-start justify-between gap-2 text-xs">
                      <div className="flex-1 min-w-0">
                        <p className="text-foreground">
                          <span className="font-bold">{c.authorName}</span>{" "}
                          <span className="text-muted-foreground">
                            · {new Date(c.createdAt).toLocaleTimeString()}
                          </span>
                        </p>
                        <p className="text-muted-foreground">{c.text}</p>
                      </div>
                      {c.authorId === meId && (
                        <button
                          onClick={() => deleteComment(c.id)}
                          className="text-destructive hover:underline shrink-0"
                        >
                          Delete
                        </button>
                      )}
                    </div>
                  ))}
                  <div className="flex gap-2">
                    <Input
                      value={commentDrafts[p.id] ?? ""}
                      onChange={(e) =>
                        setCommentDrafts((d) => ({ ...d, [p.id]: e.target.value }))
                      }
                      placeholder="Add a comment…"
                      className="text-xs"
                    />
                    <Button size="sm" variant="ghost" onClick={() => handleComment(p.id)}>
                      <Send className="w-3 h-3" />
                    </Button>
                  </div>
                </div>
              )}
            </GlassCard>
          );
        })
      )}
      {visibleCount < posts.length && (
        <div
          ref={loadMoreSentinelRef}
          className="flex items-center justify-center py-4 text-xs text-muted-foreground"
        >
          Loading more…
        </div>
      )}
    </div>
  );
};

export default SocialFeedV2;
