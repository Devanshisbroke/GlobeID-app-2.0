/** Tiny in-memory TTL cache keyed by `userId:bucket`.
 *  Used by /insights/* and /recommendations to avoid recomputing on every
 *  hit during the same render cycle. Default TTL 5s — long enough to
 *  collapse a screen-mount burst, short enough that fresh state is visible
 *  on the next interaction. */

interface Entry<T> {
  expiresAt: number;
  value: T;
}

const store = new Map<string, Entry<unknown>>();

export function cacheGet<T>(key: string): T | undefined {
  const entry = store.get(key);
  if (!entry) return undefined;
  if (entry.expiresAt < Date.now()) {
    store.delete(key);
    return undefined;
  }
  return entry.value as T;
}

export function cacheSet<T>(key: string, value: T, ttlMs = 5000): void {
  store.set(key, { value, expiresAt: Date.now() + ttlMs });
}

export function cacheInvalidate(prefix: string): void {
  for (const k of store.keys()) {
    if (k.startsWith(prefix)) store.delete(k);
  }
}
