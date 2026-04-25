import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { lazy, Suspense, useState, useCallback, useEffect } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { PageTransition } from "@/components/layout/PageTransition";
import SplashScreen from "@/components/SplashScreen";

// ── Core tab screens: eagerly imported for instant switching ──
import Home from "@/screens/Home";
import Identity from "@/screens/Identity";
import Wallet from "@/screens/Wallet";
import Travel from "@/screens/Travel";
import Services from "@/screens/Services";
import GlobalMap from "@/screens/GlobalMap";

// ── Secondary screens: lazy loaded ──
const LockScreen = lazy(() => import("@/screens/LockScreen"));
const Profile = lazy(() => import("@/screens/Profile"));
const KioskSimulator = lazy(() => import("@/screens/KioskSimulator"));
const EntryReceipt = lazy(() => import("@/screens/EntryReceipt"));
const TravelTimeline = lazy(() => import("@/screens/TravelTimeline"));
const TripPlanner = lazy(() => import("@/screens/TripPlanner"));
const AICopilot = lazy(() => import("@/components/ai/TravelCopilot"));
const ServicesHub = lazy(() => import("@/screens/ServicesHub"));
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

// ── Preload secondary screens after initial load ──
const preloadScreens = () => {
  import("@/screens/Profile");
  import("@/screens/SocialFeed");
  import("@/screens/TravelTimeline");
  import("@/screens/TripPlanner");
  import("@/screens/TravelIntelligence");
  import("@/screens/PlanetExplorer");
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

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        {showSplash && <SplashScreen onComplete={handleSplashComplete} />}
        <BrowserRouter>
          <Routes>
            <Route path="/lock" element={
              <Suspense fallback={<PageLoader />}>
                <LockScreen />
              </Suspense>
            } />
            <Route
              path="/*"
              element={
                <AppShell>
                  <PageTransition>
                    <Suspense fallback={<PageLoader />}>
                      <Routes>
                        {/* Core tabs — eagerly loaded, instant switch */}
                        <Route path="/" element={<Home />} />
                        <Route path="/identity" element={<Identity />} />
                        <Route path="/wallet" element={<Wallet />} />
                        <Route path="/travel" element={<Travel />} />
                        <Route path="/services" element={<Services />} />
                        <Route path="/map" element={<GlobalMap />} />
                        {/* Secondary screens */}
                        <Route path="/profile" element={<Profile />} />
                        <Route path="/kiosk-sim" element={<KioskSimulator />} />
                        <Route path="/receipt" element={<EntryReceipt />} />
                        <Route path="/timeline" element={<TravelTimeline />} />
                        <Route path="/planner" element={<TripPlanner />} />
                        <Route path="/copilot" element={<AICopilot />} />
                        <Route path="/services/hub" element={<ServicesHub />} />
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
                        <Route path="*" element={<Navigate to="/" replace />} />
                      </Routes>
                    </Suspense>
                  </PageTransition>
                </AppShell>
              }
            />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  );
};

export default App;
