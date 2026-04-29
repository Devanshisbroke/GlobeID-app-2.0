import "@testing-library/jest-dom";
// Slice-CDE: polyfill IndexedDB so Dexie / `idb` can open databases
// inside jsdom (which has no native IndexedDB implementation).
import "fake-indexeddb/auto";

Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => {},
  }),
});
