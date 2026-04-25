import React, { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoRestaurants } from "@/lib/demoServices";
import { detectCurrentLocation } from "@/lib/locationEngine";
import { useServiceFavoritesStore } from "@/store/serviceFavorites";
import { getIcon } from "@/lib/iconMap";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { ArrowLeft, Star, Clock, Heart } from "lucide-react";

const FoodDiscovery: React.FC = () => {
  const navigate = useNavigate();
  const location = useMemo(() => detectCurrentLocation(), []);
  const { favorites, toggleFavorite } = useServiceFavoritesStore();

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Food</h1>
            <p className="text-xs text-muted-foreground">{location.city} · {demoRestaurants.length} restaurants</p>
          </div>
        </div>
      </AnimatedPage>

      {demoRestaurants.map((r, i) => {
        const isFav = favorites.includes(r.id);
        return (
          <AnimatedPage key={r.id} staggerIndex={i}>
            <GlassCard interactive={false} className="overflow-hidden p-0" depth="md">
              <div className="relative">
                <img src={r.image} alt={r.name} className="w-full h-36 object-cover" loading="lazy" />
                <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                <span className="absolute top-3 left-3 text-[10px] px-2.5 py-1 rounded-full glass font-semibold text-foreground border border-border/30">{r.provider}</span>
                <button
                  onClick={() => { toggleFavorite(r.id); haptics.selection(); }}
                  className="absolute top-3 right-3 w-8 h-8 rounded-full glass flex items-center justify-center border border-border/30"
                >
                  <Heart className={cn("w-4 h-4", isFav ? "fill-destructive text-destructive" : "text-primary-foreground")} />
                </button>
              </div>
              <div className="p-4">
                <h3 className="text-sm font-bold text-foreground">{r.name}</h3>
                <p className="text-xs text-muted-foreground mt-0.5">{r.cuisine}</p>
                <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1"><Star className="w-3 h-3 text-warning" />{r.rating}</span>
                  <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{r.deliveryTime}</span>
                  <span>{r.deliveryFee}</span>
                  <span>{r.priceRange}</span>
                </div>
              </div>
            </GlassCard>
          </AnimatedPage>
        );
      })}
    </div>
  );
};

export default FoodDiscovery;
