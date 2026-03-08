import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { lazy, Suspense, useState, useCallback, useEffect } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { PageTransition } from "@/components/layout/PageTransition";
import SplashScreen from "@/components/SplashScreen";

const LockScreen = lazy(() => import("@/screens/LockScreen"));
const Home = lazy(() => import("@/screens/Home"));
const Identity = lazy(() => import("@/screens/Identity"));
const Wallet = lazy(() => import("@/screens/Wallet"));
const Travel = lazy(() => import("@/screens/Travel"));
const Services = lazy(() => import("@/screens/Services"));
const Profile = lazy(() => import("@/screens/Profile"));
const GlobalMap = lazy(() => import("@/screens/GlobalMap"));
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

const queryClient = new QueryClient();

const PageLoader = () => (
  <div className="flex items-center justify-center min-h-[60dvh]">
    <div className="w-6 h-6 rounded-full border-2 border-primary border-t-transparent animate-spin" />
  </div>
);

const App = () => {
  const [showSplash, setShowSplash] = useState(true);
  const handleSplashComplete = useCallback(() => setShowSplash(false), []);

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
          <Suspense fallback={<PageLoader />}>
            <Routes>
              <Route path="/lock" element={<LockScreen />} />
              <Route
                path="/*"
                element={
                  <AppShell>
                    <PageTransition>
                      <Suspense fallback={<PageLoader />}>
                        <Routes>
                          <Route path="/" element={<Home />} />
                          <Route path="/identity" element={<Identity />} />
                          <Route path="/wallet" element={<Wallet />} />
                          <Route path="/travel" element={<Travel />} />
                          <Route path="/services" element={<Services />} />
                          <Route path="/profile" element={<Profile />} />
                          <Route path="/map" element={<GlobalMap />} />
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
                          <Route path="*" element={<Navigate to="/" replace />} />
                        </Routes>
                      </Suspense>
                    </PageTransition>
                  </AppShell>
                }
              />
            </Routes>
          </Suspense>
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  );
};

export default App;
