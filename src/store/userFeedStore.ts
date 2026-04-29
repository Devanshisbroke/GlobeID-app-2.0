/**
 * Slice-E — real user-feed store.
 *
 * Sits *alongside* the existing demo `socialStore` (which is the curated
 * explore feed) and manages the user's own posts + comments + likes with
 * IndexedDB-backed persistence.
 *
 * State machine (per mutation):
 *   idle → pending → (success | error)
 * Pending state surfaces in the UI so users see "Posting…" instead of a
 * hung button.
 *
 * Every mutation writes through to Dexie first, then updates in-memory
 * state. Hydration on boot reads from Dexie.
 */
import { create } from "zustand";
import {
  socialDB,
  type UserPost,
  type UserComment,
  type UserLike,
  type UserReaction,
  type ReactionKind,
  type MediaBlob,
} from "@/lib/socialDB";

export type MutationStatus = "idle" | "pending" | "success" | "error";

export interface CreatePostInput {
  authorId: string;
  authorName: string;
  authorAvatar?: string;
  caption: string;
  image?: string;
  /** Slice-F: optional image blob, stored in mediaBlobs table. */
  imageBlob?: Blob;
  location?: string;
  country?: string;
  iata?: string;
  tags?: string[];
}

interface UserFeedState {
  posts: UserPost[];
  comments: UserComment[];
  likes: UserLike[];
  reactions: UserReaction[];
  mediaUrls: Record<string, string>; // mediaId → object URL
  hydrated: boolean;
  status: MutationStatus;
  error: string | null;
  hydrate: () => Promise<void>;
  createPost: (input: CreatePostInput) => Promise<UserPost>;
  updatePost: (id: string, patch: Partial<Pick<UserPost, "caption" | "tags" | "image">>) => Promise<void>;
  deletePost: (id: string) => Promise<void>;
  addComment: (postId: string, authorId: string, authorName: string, text: string) => Promise<UserComment>;
  deleteComment: (id: string) => Promise<void>;
  toggleLike: (userId: string, postId: string) => Promise<boolean>;
  hasLiked: (userId: string, postId: string) => boolean;
  likesFor: (postId: string) => number;
  commentsFor: (postId: string) => UserComment[];
  toggleReaction: (userId: string, postId: string, kind: ReactionKind) => Promise<boolean>;
  hasReaction: (userId: string, postId: string, kind: ReactionKind) => boolean;
  reactionsFor: (postId: string) => Record<ReactionKind, number>;
  getMediaUrl: (mediaId: string) => Promise<string | null>;
}

function nowIso() {
  return new Date().toISOString();
}

function rid(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) return crypto.randomUUID();
  return `id-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

const EMPTY_REACTION_BUCKET: Record<ReactionKind, number> = {
  like: 0,
  love: 0,
  clap: 0,
  plane: 0,
  fire: 0,
};

export const useUserFeedStore = create<UserFeedState>((set, get) => ({
  posts: [],
  comments: [],
  likes: [],
  reactions: [],
  mediaUrls: {},
  hydrated: false,
  status: "idle",
  error: null,

  hydrate: async () => {
    try {
      const [posts, comments, likes, reactions] = await Promise.all([
        socialDB.posts.where("deleted").equals(0).toArray(),
        socialDB.comments.where("deleted").equals(0).toArray(),
        socialDB.likes.toArray(),
        socialDB.reactions.toArray(),
      ]);
      set({
        posts: posts.sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
        comments,
        likes,
        reactions,
        hydrated: true,
      });
    } catch (e) {
      set({ hydrated: true, error: e instanceof Error ? e.message : "hydrate failed" });
    }
  },

  createPost: async (input) => {
    set({ status: "pending", error: null });
    let mediaId: string | undefined;
    if (input.imageBlob) {
      mediaId = rid();
      const media: MediaBlob = {
        id: mediaId,
        blob: input.imageBlob,
        mime: input.imageBlob.type || "image/jpeg",
        byteSize: input.imageBlob.size,
        createdAt: nowIso(),
      };
      await socialDB.mediaBlobs.put(media);
    }
    const post: UserPost = {
      id: rid(),
      authorId: input.authorId,
      authorName: input.authorName,
      authorAvatar: input.authorAvatar,
      caption: input.caption,
      image: input.image,
      mediaId,
      location: input.location,
      country: input.country,
      iata: input.iata,
      tags: input.tags ?? [],
      createdAt: nowIso(),
      updatedAt: nowIso(),
      deleted: 0,
    };
    try {
      await socialDB.posts.add(post);
      set((s) => ({ posts: [post, ...s.posts], status: "success" }));
      return post;
    } catch (e) {
      set({ status: "error", error: e instanceof Error ? e.message : "createPost failed" });
      throw e;
    }
  },

  updatePost: async (id, patch) => {
    const existing = await socialDB.posts.get(id);
    if (!existing) return;
    const merged: UserPost = { ...existing, ...patch, updatedAt: nowIso() };
    await socialDB.posts.put(merged);
    set((s) => ({ posts: s.posts.map((p) => (p.id === id ? merged : p)) }));
  },

  deletePost: async (id) => {
    const existing = await socialDB.posts.get(id);
    if (!existing) return;
    const tomb: UserPost = { ...existing, deleted: 1, updatedAt: nowIso() };
    await socialDB.posts.put(tomb);
    set((s) => ({ posts: s.posts.filter((p) => p.id !== id) }));
  },

  addComment: async (postId, authorId, authorName, text) => {
    const c: UserComment = {
      id: rid(),
      postId,
      authorId,
      authorName,
      text,
      createdAt: nowIso(),
      deleted: 0,
    };
    await socialDB.comments.add(c);
    set((s) => ({ comments: [...s.comments, c] }));
    return c;
  },

  deleteComment: async (id) => {
    const existing = await socialDB.comments.get(id);
    if (!existing) return;
    const tomb: UserComment = { ...existing, deleted: 1 };
    await socialDB.comments.put(tomb);
    set((s) => ({ comments: s.comments.filter((c) => c.id !== id) }));
  },

  toggleLike: async (userId, postId) => {
    const key = `${userId}_${postId}`;
    const existing = await socialDB.likes.get(key);
    if (existing) {
      await socialDB.likes.delete(key);
      set((s) => ({ likes: s.likes.filter((l) => l.id !== key) }));
      return false;
    }
    const like: UserLike = { id: key, userId, postId, createdAt: nowIso() };
    await socialDB.likes.put(like);
    set((s) => ({ likes: [...s.likes, like] }));
    return true;
  },

  hasLiked: (userId, postId) => {
    const key = `${userId}_${postId}`;
    return get().likes.some((l) => l.id === key);
  },

  likesFor: (postId) => get().likes.filter((l) => l.postId === postId).length,

  commentsFor: (postId) =>
    get()
      .comments.filter((c) => c.postId === postId)
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt)),

  toggleReaction: async (userId, postId, kind) => {
    const key = `${userId}_${postId}_${kind}`;
    const existing = await socialDB.reactions.get(key);
    if (existing) {
      await socialDB.reactions.delete(key);
      set((s) => ({ reactions: s.reactions.filter((r) => r.id !== key) }));
      return false;
    }
    const r: UserReaction = { id: key, userId, postId, kind, createdAt: nowIso() };
    await socialDB.reactions.put(r);
    set((s) => ({ reactions: [...s.reactions, r] }));
    return true;
  },

  hasReaction: (userId, postId, kind) => {
    const key = `${userId}_${postId}_${kind}`;
    return get().reactions.some((r) => r.id === key);
  },

  reactionsFor: (postId) => {
    const bucket = { ...EMPTY_REACTION_BUCKET };
    for (const r of get().reactions) {
      if (r.postId === postId) bucket[r.kind] += 1;
    }
    return bucket;
  },

  getMediaUrl: async (mediaId) => {
    const cached = get().mediaUrls[mediaId];
    if (cached) return cached;
    const row = await socialDB.mediaBlobs.get(mediaId);
    if (!row) return null;
    const url = URL.createObjectURL(row.blob);
    set((s) => ({ mediaUrls: { ...s.mediaUrls, [mediaId]: url } }));
    return url;
  },
}));
