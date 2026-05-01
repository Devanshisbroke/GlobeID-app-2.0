import React, { useState, useMemo } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { detectCurrentLocation, getLocalizedServices } from "@/lib/locationEngine";
import { useServiceFavoritesStore } from "@/store/serviceFavorites";
import { useWalletStore } from "@/store/walletStore";
import { getIcon } from "@/lib/iconMap";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import {
  MapPin, Search, Hotel, Car, UtensilsCrossed, Compass, Train, ShoppingBag,
  ChevronRight, Star, Heart, Clock, History, Sparkles, ArrowLeft,
} from "lucide-react";

const categoryIcons: Record<string, React.ElementType> = {
  ride: Car, food: UtensilsCrossed, activity: Compass, transport: Train, shopping: ShoppingBag,
};

const ServicesHub: React.FC = () => {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const isRootHub = pathname === "/services";
  const location = useMemo(() => detectCurrentLocation(), []);
  const localServices = useMemo(() => getLocalizedServices(location.country), [location.country]);
  const { history, favorites, toggleFavorite } = useServiceFavoritesStore();
  const setActiveCountry = useWalletStore((s) => s.setActiveCountry);
  React.useEffect(() => {
    void setActiveCountry(location.country);
  }, [location.country, setActiveCountry]);
  const [search, setSearch] = useState("");

  const quickLinks = [
    { label: "Super", icon: Sparkles, route: "/services/super", gradient: "bg-gradient-brand" },
    { label: "Hotels", icon: Hotel, route: "/services/hotels", gradient: "bg-gradient-brand" },
    { label: "Rides", icon: Car, route: "/services/rides", gradient: "bg-gradient-brand" },
    { label: "Food", icon: UtensilsCrossed, route: "/services/food", gradient: "bg-gradient-brand" },
    { label: "Activities", icon: Compass, route: "/services/activities", gradient: "bg-gradient-brand" },
    { label: "Transport", icon: Train, route: "/services/transport", gradient: "bg-gradient-brand" },
  ];

  const filteredLocal = search
    ? localServices.filter((s) => s.name.toLowerCase().includes(search.toLowerCase()) || s.category.includes(search.toLowerCase()))
    : localServices;

  const routeForCategory = (category: string): string => {
    if (category === "ride") return "/services/rides";
    if (category === "food") return "/services/food";
    if (category === "activity" || category === "shopping") return "/services/activities";
    if (category === "transport") return "/services/transport";
    return "/services/super";
  };

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          {!isRootHub ? (
            <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center shrink-0">
              <ArrowLeft className="w-4 h-4 text-foreground" />
            </button>
          ) : null}
          <div className="flex-1">
            <h1 className="text-xl font-bold text-foreground">Services</h1>
            <p className="text-xs text-muted-foreground flex items-center gap-1">
              <MapPin className="w-3 h-3 text-accent" /> {location.city}, {location.country}
            </p>
          </div>
        </div>
      </AnimatedPage>

      {/* Search */}
      <AnimatedPage staggerIndex={0}>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search services…"
            className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border/40 text-sm bg-transparent focus:outline-none focus:ring-2 focus:ring-primary/30 placeholder:text-muted-foreground"
          />
        </div>
      </AnimatedPage>

      {/* Quick links grid */}
      <AnimatedPage staggerIndex={1}>
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-2">
          {quickLinks.map((link) => {
            const Icon = link.icon;
            return (
              <button
                key={link.label}
                onClick={() => { navigate(link.route); haptics.selection(); }}
                className="flex flex-col items-center gap-1.5 py-3"
              >
                <div className={cn("w-12 h-12 rounded-2xl flex items-center justify-center shadow-depth-sm", link.gradient)}>
                  <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                </div>
                <span className="text-[10px] font-medium text-foreground">{link.label}</span>
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {/* Localized services */}
      <div className="space-y-2">
        <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest flex items-center gap-1.5">
          <Sparkles className="w-3 h-3 text-primary" /> Local in {location.city}
        </h3>
        {filteredLocal.map((svc, i) => {
          const Icon = categoryIcons[svc.category] || Compass;
          const isFav = favorites.includes(svc.id);
          return (
            <AnimatedPage key={svc.id} staggerIndex={i + 2}>
              <GlassCard
                className="flex items-center gap-3 cursor-pointer"
                depth="md"
                onClick={() => {
                  navigate(routeForCategory(svc.category));
                  haptics.selection();
                }}
              >
                <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm", svc.gradient)}>
                  <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-foreground">{svc.name}</p>
                  <p className="text-xs text-muted-foreground">{svc.description}</p>
                </div>
                <button
                  onClick={(e) => { e.stopPropagation(); toggleFavorite(svc.id); haptics.selection(); }}
                  className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-primary/5 transition-colors"
                  aria-label={isFav ? `Remove ${svc.name} from favorites` : `Favorite ${svc.name}`}
                >
                  <Heart className={cn("w-4 h-4", isFav ? "fill-destructive text-destructive" : "text-muted-foreground")} />
                </button>
                <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
              </GlassCard>
            </AnimatedPage>
          );
        })}
      </div>

      {/* Recent history */}
      {history.length > 0 && (
        <div className="space-y-2">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest flex items-center gap-1.5">
            <History className="w-3 h-3" /> Recent
          </h3>
          {history.slice(0, 4).map((entry, i) => (
            <AnimatedPage key={entry.id} staggerIndex={i + 6}>
              <GlassCard interactive={false} className="flex items-center gap-3 py-3">
                <div className="w-8 h-8 rounded-lg bg-secondary/50 flex items-center justify-center">
                  <Clock className="w-3.5 h-3.5 text-muted-foreground" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground truncate">{entry.name}</p>
                  <p className="text-[10px] text-muted-foreground">{entry.type} · {entry.date}</p>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}
    </div>
  );
};

export default ServicesHub;
