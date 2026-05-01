import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

// ── Types ──
export interface SocialUser {
  id: string;
  name: string;
  handle: string;
  avatar: string;
  countriesVisited: number;
  travelScore: number;
  bio: string;
  verified: boolean;
}

export interface SocialPost {
  id: string;
  userId: string;
  image: string;
  caption: string;
  location: string;
  country: string;
  iata?: string;
  likes: number;
  comments: SocialComment[];
  createdAt: string;
  tags: string[];
}

export interface SocialComment {
  id: string;
  userId: string;
  text: string;
  createdAt: string;
}

export interface Story {
  id: string;
  userId: string;
  image: string;
  location: string;
  viewed: boolean;
}

export interface SocialNotification {
  id: string;
  type: "like" | "follow" | "comment" | "trending";
  fromUserId: string;
  postId?: string;
  message: string;
  createdAt: string;
  read: boolean;
}

// ── Sample data ──
const sampleUsers: SocialUser[] = [
  { id: "u1", name: "Alex Chen", handle: "@alexglobetrotter", avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face", countriesVisited: 42, travelScore: 87, bio: "Chasing sunsets across continents ✈️", verified: true },
  { id: "u2", name: "Priya Sharma", handle: "@priyatravels", avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop&crop=face", countriesVisited: 28, travelScore: 72, bio: "Food & culture explorer 🍜", verified: true },
  { id: "u3", name: "Marco Rossi", handle: "@marcoworld", avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face", countriesVisited: 35, travelScore: 79, bio: "European nomad 🏰", verified: false },
  { id: "u4", name: "Yuki Tanaka", handle: "@yukitravels", avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face", countriesVisited: 19, travelScore: 61, bio: "Japan ↔ World 🗾", verified: false },
  { id: "u5", name: "Sofia Martinez", handle: "@sofiaexplores", avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=face", countriesVisited: 31, travelScore: 74, bio: "Adventure seeker 🏔️", verified: true },
];

const samplePosts: SocialPost[] = [
  { id: "p1", userId: "u1", image: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&h=600&fit=crop", caption: "Golden hour at the Eiffel Tower. Paris never gets old ✨", location: "Paris, France", country: "France", iata: "CDG", likes: 2847, comments: [{ id: "c1", userId: "u2", text: "Stunning shot! 😍", createdAt: "2h ago" }], createdAt: "3h ago", tags: ["paris", "sunset", "travel"] },
  { id: "p2", userId: "u2", image: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600&h=600&fit=crop", caption: "Lost in the neon lights of Shibuya 🌃 Tokyo is pure magic", location: "Tokyo, Japan", country: "Japan", iata: "NRT", likes: 1923, comments: [{ id: "c2", userId: "u4", text: "Welcome to my city! 🇯🇵", createdAt: "1h ago" }], createdAt: "5h ago", tags: ["tokyo", "nightlife", "japan"] },
  { id: "p3", userId: "u3", image: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=600&h=600&fit=crop", caption: "Dubai skyline from the 148th floor. Feeling on top of the world 🏙️", location: "Dubai, UAE", country: "UAE", iata: "DXB", likes: 3421, comments: [{ id: "c3", userId: "u1", text: "That view is insane!", createdAt: "30m ago" }], createdAt: "8h ago", tags: ["dubai", "skyline", "luxury"] },
  { id: "p4", userId: "u5", image: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&h=600&fit=crop", caption: "Morning train through the Swiss Alps. This is why I travel 🏔️", location: "Zermatt, Switzerland", country: "Switzerland", iata: "ZRH", likes: 4102, comments: [{ id: "c4", userId: "u3", text: "Europe's finest! ❤️", createdAt: "2h ago" }], createdAt: "12h ago", tags: ["switzerland", "alps", "train"] },
  { id: "p5", userId: "u4", image: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&h=600&fit=crop", caption: "Crystal clear waters in Bali. Paradise found 🌊", location: "Bali, Indonesia", country: "Indonesia", likes: 2156, comments: [], createdAt: "1d ago", tags: ["bali", "beach", "paradise"] },
  { id: "p6", userId: "u1", image: "https://images.unsplash.com/photo-1485738422979-f5c462d49f04?w=600&h=600&fit=crop", caption: "Street food heaven in Bangkok. Pad Thai at midnight 🍜", location: "Bangkok, Thailand", country: "Thailand", iata: "BKK", likes: 1678, comments: [{ id: "c5", userId: "u2", text: "The best food city!", createdAt: "5h ago" }], createdAt: "1d ago", tags: ["bangkok", "streetfood", "thailand"] },
];

const sampleStories: Story[] = [
  { id: "s1", userId: "u1", image: "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400&h=700&fit=crop", location: "Paris", viewed: false },
  { id: "s2", userId: "u2", image: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&h=700&fit=crop", location: "Tokyo", viewed: false },
  { id: "s3", userId: "u5", image: "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=400&h=700&fit=crop", location: "Maldives", viewed: true },
  { id: "s4", userId: "u3", image: "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400&h=700&fit=crop", location: "Venice", viewed: false },
];

const sampleNotifications: SocialNotification[] = [
  { id: "n1", type: "like", fromUserId: "u2", postId: "p1", message: "liked your Paris post", createdAt: "2m ago", read: false },
  { id: "n2", type: "follow", fromUserId: "u3", message: "started following you", createdAt: "15m ago", read: false },
  { id: "n3", type: "comment", fromUserId: "u4", postId: "p1", message: "commented on your post", createdAt: "1h ago", read: true },
  { id: "n4", type: "trending", fromUserId: "u1", postId: "p3", message: "Your Dubai post is trending!", createdAt: "3h ago", read: true },
];

// ── Leaderboard ──
export const leaderboard = [
  { userId: "u1", rank: 1, countries: 42, score: 87 },
  { userId: "u3", rank: 2, countries: 35, score: 79 },
  { userId: "u5", rank: 3, countries: 31, score: 74 },
  { userId: "u2", rank: 4, countries: 28, score: 72 },
  { userId: "u4", rank: 5, countries: 19, score: 61 },
];

// ── Trending destinations ──
export const trendingDestinations = [
  { name: "Kyoto", country: "Japan", image: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&h=300&fit=crop", posts: 12400 },
  { name: "Santorini", country: "Greece", image: "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400&h=300&fit=crop", posts: 9800 },
  { name: "Machu Picchu", country: "Peru", image: "https://images.unsplash.com/photo-1526392060635-9d6019884377?w=400&h=300&fit=crop", posts: 8200 },
  { name: "Maldives", country: "Maldives", image: "https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=400&h=300&fit=crop", posts: 15600 },
  { name: "Cape Town", country: "South Africa", image: "https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=400&h=300&fit=crop", posts: 6300 },
  { name: "Iceland", country: "Iceland", image: "https://images.unsplash.com/photo-1504829857797-ddff29c27927?w=400&h=300&fit=crop", posts: 7100 },
];

// ── Store ──
interface SocialState {
  users: SocialUser[];
  posts: SocialPost[];
  stories: Story[];
  notifications: SocialNotification[];
  following: string[];
  likedPosts: string[];
  getUser: (id: string) => SocialUser | undefined;
  toggleFollow: (userId: string) => void;
  toggleLike: (postId: string) => void;
  addComment: (postId: string, text: string) => void;
  markStoryViewed: (storyId: string) => void;
  markNotificationRead: (notificationId: string) => void;
  unreadCount: () => number;
}

export const useSocialStore = create<SocialState>()(
  persist(
    (set, get) => ({
      users: sampleUsers,
      posts: samplePosts,
      stories: sampleStories,
      notifications: sampleNotifications,
      following: ["u2", "u5"],
      likedPosts: [],

      getUser: (id) => get().users.find((u) => u.id === id),

      toggleFollow: (userId) =>
        set((s) => ({
          following: s.following.includes(userId)
            ? s.following.filter((f) => f !== userId)
            : [...s.following, userId],
        })),

      toggleLike: (postId) =>
        set((s) => ({
          likedPosts: s.likedPosts.includes(postId)
            ? s.likedPosts.filter((l) => l !== postId)
            : [...s.likedPosts, postId],
          posts: s.posts.map((p) =>
            p.id === postId
              ? { ...p, likes: s.likedPosts.includes(postId) ? p.likes - 1 : p.likes + 1 }
              : p,
          ),
        })),

      addComment: (postId, text) =>
        set((s) => ({
          posts: s.posts.map((p) =>
            p.id === postId
              ? {
                  ...p,
                  comments: [
                    ...p.comments,
                    { id: `c-${Date.now()}`, userId: "me", text, createdAt: "now" },
                  ],
                }
              : p,
          ),
        })),

      markStoryViewed: (storyId) =>
        set((s) => ({
          stories: s.stories.map((st) =>
            st.id === storyId ? { ...st, viewed: true } : st,
          ),
        })),

      markNotificationRead: (notificationId) =>
        set((s) => ({
          notifications: s.notifications.map((n) =>
            n.id === notificationId ? { ...n, read: true } : n,
          ),
        })),

      unreadCount: () => get().notifications.filter((n) => !n.read).length,
    }),
    {
      name: "globeid:social-store",
      version: 1,
      storage: createJSONStorage(() => localStorage),
      // Only persist mutable user state — sample fixtures stay
      // canonical so a schema bump doesn't ship stale data.
      partialize: (s) => ({
        following: s.following,
        likedPosts: s.likedPosts,
        notifications: s.notifications.map((n) => ({ id: n.id, read: n.read })),
        stories: s.stories.map((st) => ({ id: st.id, viewed: st.viewed })),
      }),
      merge: (persisted, current) => {
        const p = (persisted ?? {}) as Partial<{
          following: string[];
          likedPosts: string[];
          notifications: Array<{ id: string; read: boolean }>;
          stories: Array<{ id: string; viewed: boolean }>;
        }>;
        return {
          ...current,
          following: p.following ?? current.following,
          likedPosts: p.likedPosts ?? current.likedPosts,
          notifications: current.notifications.map((n) => {
            const hit = p.notifications?.find((x) => x.id === n.id);
            return hit ? { ...n, read: hit.read } : n;
          }),
          stories: current.stories.map((st) => {
            const hit = p.stories?.find((x) => x.id === st.id);
            return hit ? { ...st, viewed: hit.viewed } : st;
          }),
        };
      },
    },
  ),
);
