/**
 * Slice-E — IndexedDB schema for the real social feed (posts / comments /
 * likes).
 *
 * Uses Dexie because the existing store file uses plain Zustand without
 * persistence middleware, and we want strongly-typed indexed queries
 * (`where({ postId }).toArray()`) without reinventing them on top of the
 * lower-level `idb` module.
 *
 * Schema choices:
 *  - All three tables use UUIDs (crypto.randomUUID) rather than
 *    auto-increment ints. That way the same ID survives across devices
 *    once we get a sync backend.
 *  - `posts.createdAt` is an ISO-8601 string and is indexed so feed
 *    sort-by-newest is a cheap range query instead of an array sort.
 *  - `likes` is its own table (not a counter on `posts`) — this mirrors
 *    the eventual server schema and lets us idempotently upsert a like
 *    per (userId, postId) without race conditions.
 */
import Dexie, { type Table } from "dexie";

export interface UserPost {
  id: string;
  authorId: string;
  authorName: string;
  authorAvatar?: string;
  image?: string;
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

class SocialDB extends Dexie {
  posts!: Table<UserPost, string>;
  comments!: Table<UserComment, string>;
  likes!: Table<UserLike, string>;

  constructor() {
    super("globe-social");
    this.version(1).stores({
      posts: "id, authorId, createdAt, deleted",
      comments: "id, postId, createdAt, deleted",
      likes: "id, userId, postId, createdAt",
    });
  }
}

export const socialDB = new SocialDB();

/** Test-only helper. */
export async function _resetSocialDB(): Promise<void> {
  await socialDB.delete();
  await socialDB.open();
}
