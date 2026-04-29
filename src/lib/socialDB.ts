/**
 * Slice-E + Slice-F — IndexedDB schema for the real social feed.
 *
 * Slice-E tables (v1): posts / comments / likes.
 * Slice-F tables (v2): reactions (richer than binary likes) + a dedicated
 * `mediaBlobs` table so image attachments don't blow up the posts row.
 *
 * Dexie migrates users from v1 → v2 on next open without data loss.
 */
import Dexie, { type Table } from "dexie";

export interface UserPost {
  id: string;
  authorId: string;
  authorName: string;
  authorAvatar?: string;
  image?: string;
  /** v2: optional mediaBlobs.id reference. Takes precedence over `image`. */
  mediaId?: string;
  caption: string;
  location?: string;
  country?: string;
  iata?: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
  /** Tombstone marker for soft-delete + future server sync. */
  deleted: 0 | 1;
}

export interface UserComment {
  id: string;
  postId: string;
  authorId: string;
  authorName: string;
  text: string;
  createdAt: string;
  deleted: 0 | 1;
}

export interface UserLike {
  /** Composite PK `${userId}_${postId}` so upserts are idempotent. */
  id: string;
  userId: string;
  postId: string;
  createdAt: string;
}

export const REACTIONS = ["like", "love", "clap", "plane", "fire"] as const;
export type ReactionKind = (typeof REACTIONS)[number];

export interface UserReaction {
  /** Composite PK `${userId}_${postId}_${kind}` so upserts are idempotent. */
  id: string;
  userId: string;
  postId: string;
  kind: ReactionKind;
  createdAt: string;
}

export interface MediaBlob {
  id: string;
  blob: Blob;
  mime: string;
  byteSize: number;
  width?: number;
  height?: number;
  createdAt: string;
}

class SocialDB extends Dexie {
  posts!: Table<UserPost, string>;
  comments!: Table<UserComment, string>;
  likes!: Table<UserLike, string>;
  reactions!: Table<UserReaction, string>;
  mediaBlobs!: Table<MediaBlob, string>;

  constructor() {
    super("globe-social");
    // v1 schema (Slice E).
    this.version(1).stores({
      posts: "id, authorId, createdAt, deleted",
      comments: "id, postId, createdAt, deleted",
      likes: "id, userId, postId, createdAt",
    });
    // v2: add reactions + mediaBlobs; upgrade posts index to include mediaId.
    this.version(2).stores({
      posts: "id, authorId, createdAt, deleted, mediaId",
      comments: "id, postId, createdAt, deleted",
      likes: "id, userId, postId, createdAt",
      reactions: "id, userId, postId, kind, createdAt",
      mediaBlobs: "id, createdAt",
    });
  }
}

export const socialDB = new SocialDB();

/** Test-only helper. */
export async function _resetSocialDB(): Promise<void> {
  await socialDB.delete();
  await socialDB.open();
}
