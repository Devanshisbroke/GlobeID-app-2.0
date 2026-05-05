import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate, useLocation, useNavigate } from "react-router-dom";
import React, { lazy, Suspense, useState, useCallback, useEffect } from "react";
import { AppChromeV2, SplashV2 } from "@/components/layout/v2";
import NativeBackButton from "@/components/system/NativeBackButton";
import EdgeSwipeBack from "@/components/system/EdgeSwipeBack";
import RouteErrorBoundary from "@/components/system/RouteErrorBoundary";
import KeyboardShortcuts from "@/components/ui/KeyboardShortcuts";
import {
  applyNativeChrome,
  deepLinkToPath,
  wireAppStateListener,
  wireNetworkListener,
  wireUrlOpenListener,
} from "@/lib/nativeBridge";
import { useUserStore } from "@/store/userStore";
import { useAlertsStore } from "@/store/alertsStore";
import { useInsightsStore } from "@/store/insightsStore";
import { useRecommendationsStore } from "@/store/recommendationsStore";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { useCopilotStore } from "@/store/copilotStore";
import { useContextStore } from "@/store/contextStore";
import { useLifecycleStore } from "@/store/lifecycleStore";
import { useWalletStore } from "@/store/walletStore";

// ── Core tab screens ──
// Home is eager so first paint is instant. The other tabs are lazy-
// loaded — on Capacitor the chunks are local so the tab switch still
// feels native, while the initial JS bundle is materially smaller
// (~250 KB shaved off the legacy index-OG0Q6BSC.js entry).
import Home from "@/screens/Home";
const Identity = lazy(() => import("@/screens/Identity"));
const Wallet = lazy(() => import("@/screens/Wallet"));
const Travel = lazy(() => import("@/screens/Travel"));
const ServicesHub = lazy(() => import("@/screens/ServicesHub"));
const GlobalMap = lazy(() => import("@/screens/GlobalMap"));

// ── Secondary screens: lazy loaded ──
const LockScreen = lazy(() => import("@/screens/LockScreen"));
const Profile = lazy(() => import("@/screens/Profile"));
const KioskSimulator = lazy(() => import("@/screens/KioskSimulator"));
const EntryReceipt = lazy(() => import("@/screens/EntryReceipt"));
const TravelTimeline = lazy(() => import("@/screens/TravelTimeline"));
const TripPlanner = lazy(() => import("@/screens/TripPlanner"));
const AICopilot = lazy(() => import("@/components/ai/TravelCopilot"));
const SuperServicesHub = lazy(() => import("@/screens/SuperServicesHub"));
const HotelBooking = lazy(() => import("@/screens/services/HotelBooking"));
const RideBooking = lazy(() => import("@/screens/services/RideBooking"));
const FoodDiscovery = lazy(() => import("@/screens/services/FoodDiscovery"));
const ActivitiesScreen = lazy(() => import("@/screens/services/Activities"));
const TransportScreen = lazy(() => import("@/screens/services/Transport"));
const SocialFeed = lazy(() => import("@/screens/SocialFeed"));
const Explore = lazy(() => import("@/screens/Explore"));
const UserProfile = lazy(() => import("@/screens/UserProfile"));
const IdentityVault = lazy(() => import("@/screens/IdentityVault"));
const TravelIntelligence = lazy(() => import("@/screens/TravelIntelligence"));
const PlanetExplorer = lazy(() => import("@/screens/PlanetExplorer"));
const TripDetail = lazy(() => import("@/screens/TripDetail"));
// Slice-D: OCR-powered encrypted document vault.
const DocumentVault = lazy(() => import("@/screens/DocumentVault"));
// Slice-E: Real social feed v2 (IndexedDB-backed CRUD).
const SocialFeedV2 = lazy(() => import("@/screens/SocialFeedV2"));
// Slice-C: recharts analytics dashboard.
const AnalyticsDashboard = lazy(() => import("@/screens/AnalyticsDashboard"));
// Slice-F: multi-currency portfolio + best-route conversion.
const MultiCurrency = lazy(() => import("@/screens/MultiCurrency"));
// Slice-F: hybrid QR + document scanner.
const HybridScanner = lazy(() => import("@/screens/HybridScanner"));
// Slice-G: first-run onboarding.
const Onboarding = lazy(() => import("@/screens/Onboarding"));

// Slice-G – redirect cold launches to /onboarding if the user has
// never completed it. `/onboarding` and `/lock` are allowlisted so we
// don't trap users in a redirect loop.
const FirstRunGate: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();
  useEffect(() => {
    const onboarded = (() => {
      try {
        return localStorage.getItem("globeid:onboarded") === "1";
      } catch {
        return true;
      }
    })();
    const pass = ["/onboarding", "/lock"];
    if (!onboarded && !pass.includes(location.pathname)) {
      navigate("/onboarding", { replace: true });
    }
  }, [location.pathname, navigate]);
  return <>{children}</>;
};

// Phase 7 PR-β — dev-only smoke route for v2 component primitives.
// Tree-shaken out of production builds via the `import.meta.env.DEV`
// guard at the route registration site below.
const V2Showcase = lazy(() => import("@/components/ui/v2/__showcase"));

// ── Preload secondary screens ──
//
// Phase 9-α bug-fix #2: AI Copilot is reachable from a card on the Travel
// screen, and the lazy chunk load on first nav was visibly blank for ~600 ms
// (Suspense fallback rendered while the chunk fetched). Preloading after
// splash dismisses gets the chunk into the browser cache before the user
// taps in, eliminating the perceived "blank screen on nav".
//
// Slice-A tightening: also kick this off DURING the splash window (alongside
// `hydrateAll()`) so the 0.9 s splash isn't network-idle. `import()` is
// idempotent — calling twice resolves to the same cached module — so the
// post-splash `requestIdleCallback` invocation is now a no-op fallback for
// hardware where the splash dismissed before any chunk finished fetching.
const preloadScreens = () => {
  void import("@/screens/Profile");
  void import("@/screens/SocialFeed");
  void import("@/screens/TravelTimeline");
  void import("@/screens/TripPlanner");
  void import("@/screens/TravelIntelligence");
  void import("@/screens/PlanetExplorer");
  void import("@/components/ai/TravelCopilot");
};

const queryClient = new QueryClient();

/** Minimal inline fallback — no heavy spinner, just a soft fade placeholder */
const PageLoader = () => (
  <div className="flex items-center justify-center min-h-[40dvh]">
    <div className="w-2 h-2 rounded-full bg-primary/40 animate-pulse" />
  </div>
);

const App = () => {
  const [showSplash, setShowSplash] = useState(true);
  const handleSplashComplete = useCallback(() => {
    setShowSplash(false);
    // Slice-F: play the GSAP hero reveal once the chrome mounts. One frame
    // of delay so newly-rendered `[data-reveal]` nodes exist when the
    // timeline scans.
    if (typeof window !== "undefined") {
      requestAnimationFrame(() => {
        void import("@/cinematic/motionOrchestrator").then(({ playHeroReveal }) => {
          playHeroReveal();
        });
      });
    }
    // Preload secondary screens after splash dismisses. `requestIdleCallback`
    // is undefined in older Android WebViews, so feature-detect rather than
    // relying on a truthy global reference.
    if (typeof requestIdleCallback === "function") {
      requestIdleCallback(preloadScreens);
    } else {
      setTimeout(preloadScreens, 500);
    }
  }, []);

  useEffect(() => {
    const saved = localStorage.getItem("globe-theme");
    if (saved === "dark" || (!saved && window.matchMedia("(prefers-color-scheme: dark)").matches)) {
      document.documentElement.classList.add("dark");
    }
  }, []);

  // Hydrate canonical state from the backend once on app boot, then
  // again any time we transition online so any queued offline mutations
  // get drained.
  //
  // Order matters: userStore.hydrate() must complete BEFORE insights /
  // recommendations / alerts hydrate so the derived endpoints see the
  // freshly-synced travel_records, not stale cache. Phase 4.5 derived
  // endpoints are read-only — no pendingMutations interaction.
  //
  // Phase 6 PR-α: the network listener now routes through `nativeBridge`
  // so on Capacitor we use `@capacitor/network` (Doze + battery-saver
  // aware) and on the browser we keep using `window.online`. Both code
  // paths share the same callback shape.
  useEffect(() => {
    const hydrateAll = async (): Promise<void> => {
      await useUserStore.getState().hydrate();
      await Promise.allSettled([
        useAlertsStore.getState().hydrate(),
        useInsightsStore.getState().hydrate(),
        useRecommendationsStore.getState().hydrate(),
        useTripPlannerStore.getState().hydrate(),
        useCopilotStore.getState().hydrate(),
        // Phase 9-β: context engine + trip lifecycles. Both depend on the
        // primary user/trip rows, so hydrate them after `userStore.hydrate()`.
        useContextStore.getState().hydrate(),
        useLifecycleStore.getState().hydrate(),
        // Slice-A: pull authoritative wallet snapshot from the server. The
        // store keeps a localStorage read-cache so the UI doesn't flash
        // empty before this resolves on cold launch.
        useWalletStore.getState().hydrate(),
      ]);
    };
    void hydrateAll();
    void applyNativeChrome();
    // Slice-A: warm secondary chunks during the splash window so first-tap
    // nav has them in cache. Idempotent with the post-splash idle callback.
    preloadScreens();

    let cancelled = false;
    let unsubscribe: (() => void) | null = null;
    let unsubAppState: (() => void) | null = null;
    let unsubUrlOpen: (() => void) | null = null;
    void wireNetworkListener((online) => {
      if (online) void hydrateAll();
    }).then((un) => {
      if (cancelled) {
        un();
        return;
      }
      unsubscribe = un;
    });
    // B 20 — re-hydrate stores when the app returns to foreground.
    void wireAppStateListener(() => {
      void hydrateAll();
    }).then((un) => {
      if (cancelled) {
        un();
        return;
      }
      unsubAppState = un;
    });
    // B 21 — handle deep links emitted by the OS when the user taps a
    // `globeid://...` link or a universal-link banner.
    void wireUrlOpenListener((url) => {
      const target = deepLinkToPath(url);
      if (target && typeof window !== "undefined") {
        // Use the History API directly so we don't have to plumb the
        // Router context up to App.tsx.
        window.history.pushState({}, "", target);
        // Fire popstate so React Router (in nested route) reacts.
        window.dispatchEvent(new PopStateEvent("popstate"));
      }
    }).then((un) => {
      if (cancelled) {
        un();
        return;
      }
      unsubUrlOpen = un;
    });
    return () => {
      cancelled = true;
      unsubscribe?.();
      unsubAppState?.();
      unsubUrlOpen?.();
    };
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        {showSplash && <SplashV2 onComplete={handleSplashComplete} />}
        <BrowserRouter>
          <NativeBackButton />
          <EdgeSwipeBack />
          <KeyboardShortcuts />
          <FirstRunGate>
          <Routes>
            <Route path="/lock" element={
              <Suspense fallback={<PageLoader />}>
                <LockScreen />
              </Suspense>
            } />
            <Route path="/onboarding" element={
              <Suspense fallback={<PageLoader />}>
                <Onboarding />
              </Suspense>
            } />
            {import.meta.env.DEV ? (
              <Route path="/__v2" element={
                <Suspense fallback={<PageLoader />}>
                  <V2Showcase />
                </Suspense>
              } />
            ) : null}
            <Route
              path="/*"
              element={
                <AppChromeV2>
                  <RouteErrorBoundary>
                    <Suspense fallback={<PageLoader />}>
                      <Routes>
                        {/* Core tabs — eagerly loaded, instant switch */}
                        <Route path="/" element={<Home />} />
                        <Route path="/identity" element={<Identity />} />
                        <Route path="/wallet" element={<Wallet />} />
                        <Route path="/travel" element={<Travel />} />
                        <Route path="/services" element={<ServicesHub />} />
                        <Route path="/map" element={<GlobalMap />} />
                        {/* Secondary screens */}
                        <Route path="/profile" element={<Profile />} />
                        <Route path="/kiosk-sim" element={<KioskSimulator />} />
                        <Route path="/receipt" element={<EntryReceipt />} />
                        <Route path="/timeline" element={<TravelTimeline />} />
                        <Route path="/planner" element={<TripPlanner />} />
                        <Route path="/copilot" element={<AICopilot />} />
                        <Route path="/services/hub" element={<Navigate to="/services" replace />} />
                        <Route path="/services/super" element={<SuperServicesHub />} />
                        <Route path="/services/hotels" element={<HotelBooking />} />
                        <Route path="/services/rides" element={<RideBooking />} />
                        <Route path="/services/food" element={<FoodDiscovery />} />
                        <Route path="/services/activities" element={<ActivitiesScreen />} />
                        <Route path="/services/transport" element={<TransportScreen />} />
                        <Route path="/social" element={<SocialFeed />} />
                        <Route path="/explore" element={<Explore />} />
                        <Route path="/profile/:userId" element={<UserProfile />} />
                        <Route path="/passport-book" element={<IdentityVault />} />
                        <Route path="/intelligence" element={<TravelIntelligence />} />
                        <Route path="/explorer" element={<PlanetExplorer />} />
                        <Route path="/trip/:tripId" element={<TripDetail />} />
                        <Route path="/vault" element={<DocumentVault />} />
                        <Route path="/feed" element={<SocialFeedV2 />} />
                        <Route path="/multi-currency" element={<MultiCurrency />} />
                        <Route path="/scan" element={<HybridScanner />} />
                        <Route path="/analytics" element={<AnalyticsDashboard />} />
                        <Route path="*" element={<Navigate to="/" replace />} />
                      </Routes>
                    </Suspense>
                  </RouteErrorBoundary>
                </AppChromeV2>
              }
            />
          </Routes>
          </FirstRunGate>
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  );
};

export default App;
