import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { VitePWA } from "vite-plugin-pwa";

/**
 * Vite config.
 *
 * Phase 6 PR-α:
 *  - Dropped `lovable-tagger` (Lovable scaffold leftover; not used in app code).
 *  - PWA service worker is registered only in browser builds; the Capacitor
 *    Android shell sets `VITE_NATIVE_BUILD=true` at build time which strips
 *    the SW (see `src/main.tsx` for the runtime guard). The plugin still
 *    runs at build time so browser-served PWAs continue to install.
 */
export default defineConfig(({ mode }) => {
  // Phase 8 — production build guard.
  // VITE_API_BASE_URL is required for any non-dev build that will be served
  // off the local dev box (PWA upload, Capacitor APK, deployed bundle, etc.).
  // Without it the client falls back to http://localhost:4000 which devices
  // cannot reach. Warn loudly during build so the regression is visible.
  if (mode === "production" && !process.env.VITE_API_BASE_URL) {
    console.warn(
      "\n[vite] WARNING: VITE_API_BASE_URL is not set for the production build.\n" +
        "       The bundled client will fall back to http://localhost:4000/api/v1,\n" +
        "       which is unreachable from devices. Copy .env.production.example to\n" +
        ".env.production and set VITE_API_BASE_URL before rebuilding.\n",
    );
  }
  return {
  server: {
    host: "::",
    port: 8080,
    hmr: {
      overlay: false,
    },
  },
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.ico"],
      manifest: false, // use public/manifest.json
      workbox: {
        globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2}"],
        // Heavy NASA/Earth textures are loaded on demand by the Globe
        // scene and shouldn't bloat the precache manifest. Match them
        // here and let the runtimeCaching rule below pull them in on
        // first request and persist for offline reuse.
        globIgnores: ["**/textures/earth-clouds*"],
        // Default 2 MiB; bump to 6 MiB so the 4K diffuse texture
        // (~1.4 MB) and bundled Tesseract eng pack (~2.3 MB) get
        // precached for offline first-load.
        maximumFileSizeToCacheInBytes: 6 * 1024 * 1024,
        navigateFallbackDenylist: [/^\/~oauth/],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/images\.unsplash\.com\/.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "unsplash-images",
              expiration: { maxEntries: 50, maxAgeSeconds: 60 * 60 * 24 * 7 },
            },
          },
          {
            // Lazy-cache the 4.9 MB cloud layer on first request.
            urlPattern: /\/textures\/earth-clouds.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "earth-textures",
              expiration: { maxEntries: 4, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
    }),
  ].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      "@shared": path.resolve(__dirname, "./shared"),
    },
    dedupe: ["react", "react-dom", "react/jsx-runtime", "three", "@react-three/fiber", "@react-three/drei"],
  },
  build: {
    // The 3D / charts / motion libraries are large and only used on
    // specific routes. Splitting them into vendor chunks lets the
    // initial app shell ship without them and keeps the lazy GlobeScene
    // chunk down to GlobeID's own scene code.
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes("node_modules")) return undefined;
          if (id.includes("three") || id.includes("@react-three")) return "vendor-three";
          if (id.includes("framer-motion")) return "vendor-motion";
          if (id.includes("recharts") || id.includes("d3-")) return "vendor-charts";
          if (id.includes("@radix-ui")) return "vendor-radix";
          if (id.includes("lucide-react")) return "vendor-icons";
          return undefined;
        },
      },
    },
    chunkSizeWarningLimit: 900,
  },
  };
});
