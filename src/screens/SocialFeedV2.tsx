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
import React, { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowLeft, Heart, MessageCircle, Send, Trash2 } from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useUserFeedStore } from "@/store/userFeedStore";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";

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

  const [caption, setCaption] = useState("");
  const [location, setLocation] = useState("");
  const [expandedPost, setExpandedPost] = useState<string | null>(null);
  const [commentDrafts, setCommentDrafts] = useState<Record<string, string>>({});

  useEffect(() => {
    if (!hydrated) void hydrate();
  }, [hydrated, hydrate]);

  const meId = user?.id ?? "me";
  const meName = user?.name ?? "Me";

  const handlePost = useCallback(async () => {
    if (!caption.trim()) return;
    await createPost({
      authorId: meId,
      authorName: meName,
      caption: caption.trim(),
      location: location.trim() || undefined,
    });
    setCaption("");
    setLocation("");
  }, [caption, location, createPost, meId, meName]);

  const handleComment = useCallback(
    async (postId: string) => {
      const text = (commentDrafts[postId] ?? "").trim();
      if (!text) return;
      await addComment(postId, meId, meName, text);
      setCommentDrafts((d) => ({ ...d, [postId]: "" }));
    },
    [commentDrafts, addComment, meId, meName],
  );

  return (
    <div className="px-4 py-6 pb-28 space-y-4">
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
        <Button
          size="sm"
          onClick={handlePost}
          disabled={!caption.trim() || status === "pending"}
          className="w-full"
        >
          <Send className="w-3 h-3 mr-1" />
          {status === "pending" ? "Posting…" : "Post"}
        </Button>
      </GlassCard>

      {posts.length === 0 ? (
        <GlassCard className="p-6 text-center">
          <p className="text-sm text-muted-foreground">No posts yet — share your first trip update.</p>
        </GlassCard>
      ) : (
        posts.map((p) => {
          const liked = hasLiked(meId, p.id);
          const likes = likesFor(p.id);
          const comments = commentsFor(p.id);
          const expanded = expandedPost === p.id;
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
    </div>
  );
};

export default SocialFeedV2;
