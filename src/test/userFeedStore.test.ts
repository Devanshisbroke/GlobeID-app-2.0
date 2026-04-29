import { beforeEach, describe, expect, it } from "vitest";
import { useUserFeedStore } from "@/store/userFeedStore";
import { _resetSocialDB } from "@/lib/socialDB";

async function resetStore() {
  await _resetSocialDB();
  useUserFeedStore.setState({
    posts: [],
    comments: [],
    likes: [],
    hydrated: false,
    status: "idle",
    error: null,
  });
}

describe("userFeedStore — CRUD state machine", () => {
  beforeEach(async () => {
    await resetStore();
  });

  it("creates a post and persists it through hydrate", async () => {
    const { createPost, hydrate } = useUserFeedStore.getState();
    const post = await createPost({
      authorId: "me",
      authorName: "Me",
      caption: "Hello Tokyo",
    });
    expect(post.id).toBeTruthy();
    expect(useUserFeedStore.getState().posts).toHaveLength(1);

    // Wipe in-memory state but keep DB; hydrate should restore the row.
    useUserFeedStore.setState({ posts: [], comments: [], likes: [], hydrated: false });
    await hydrate();
    expect(useUserFeedStore.getState().posts).toHaveLength(1);
    expect(useUserFeedStore.getState().posts[0]!.caption).toBe("Hello Tokyo");
  });

  it("soft-deletes a post (tombstone survives hydrate)", async () => {
    const { createPost, deletePost, hydrate } = useUserFeedStore.getState();
    const post = await createPost({ authorId: "me", authorName: "Me", caption: "x" });
    await deletePost(post.id);
    expect(useUserFeedStore.getState().posts).toHaveLength(0);
    useUserFeedStore.setState({ posts: [], comments: [], likes: [], hydrated: false });
    await hydrate();
    expect(useUserFeedStore.getState().posts).toHaveLength(0);
  });

  it("toggleLike is idempotent per (userId, postId)", async () => {
    const { createPost, toggleLike, likesFor, hasLiked } = useUserFeedStore.getState();
    const post = await createPost({ authorId: "me", authorName: "Me", caption: "x" });
    expect(await toggleLike("u1", post.id)).toBe(true);
    expect(await toggleLike("u1", post.id)).toBe(false);
    expect(likesFor(post.id)).toBe(0);
    await toggleLike("u2", post.id);
    await toggleLike("u1", post.id);
    expect(likesFor(post.id)).toBe(2);
    expect(hasLiked("u1", post.id)).toBe(true);
    expect(hasLiked("u3", post.id)).toBe(false);
  });

  it("comments are sorted oldest-first per post", async () => {
    const { createPost, addComment, commentsFor } = useUserFeedStore.getState();
    const p = await createPost({ authorId: "me", authorName: "Me", caption: "x" });
    const c1 = await addComment(p.id, "u1", "A", "first");
    await new Promise((r) => setTimeout(r, 5));
    const c2 = await addComment(p.id, "u2", "B", "second");
    const rows = commentsFor(p.id);
    expect(rows.map((r) => r.id)).toEqual([c1.id, c2.id]);
  });
});
