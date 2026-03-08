import React, { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { detectCurrentLocation, getHotels } from "@/lib/locationEngine";
import { useServiceFavoritesStore } from "@/store/serviceFavorites";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { ArrowLeft, Star, Heart, MapPin, Wifi, Waves, Dumbbell, UtensilsCrossed } from "lucide-react";

const amenityIcons: Record<string, React.ElementType> = {
  Pool: Waves, Spa: Waves, Gym: Dumbbell, Restaurant: UtensilsCrossed, "Infinity Pool": Waves,
  WiFi: Wifi, Bar: UtensilsCrossed, Beach: Waves, Casino: Star, Nature: MapPin,
};

const HotelBooking: React.FC = () => {
  const navigate = useNavigate();
  const location = useMemo(() => detectCurrentLocation(), []);
  const hotels = useMemo(() => getHotels(location.country), [location.country]);
  const { favorites, toggleFavorite, addHistory } = useServiceFavoritesStore();

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Hotels</h1>
            <p className="text-xs text-muted-foreground">{location.city} · {hotels.length} properties</p>
          </div>
        </div>
      </AnimatedPage>

      {hotels.map((hotel, i) => {
        const isFav = favorites.includes(hotel.id);
        return (
          <AnimatedPage key={hotel.id} staggerIndex={i}>
            <GlassCard interactive={false} className="overflow-hidden p-0" depth="md">
              <div className="relative">
                <img src={hotel.image} alt={hotel.name} className="w-full h-40 object-cover" loading="lazy" />
                <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                <button
                  onClick={() => { toggleFavorite(hotel.id); haptics.selection(); }}
                  className="absolute top-3 right-3 w-8 h-8 rounded-full glass flex items-center justify-center border border-border/30"
                >
                  <Heart className={cn("w-4 h-4", isFav ? "fill-destructive text-destructive" : "text-primary-foreground")} />
                </button>
                <div className="absolute bottom-3 left-3 flex items-center gap-1">
                  {Array.from({ length: hotel.stars }).map((_, j) => (
                    <Star key={j} className="w-3 h-3 fill-neon-amber text-neon-amber" />
                  ))}
                </div>
              </div>
              <div className="p-4 space-y-2">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="text-sm font-bold text-foreground">{hotel.name}</h3>
                    <p className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5">
                      <MapPin className="w-3 h-3" /> {hotel.location}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-bold text-foreground">{hotel.currency} {hotel.price}</p>
                    <p className="text-[10px] text-muted-foreground">/night</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="px-1.5 py-0.5 rounded-md bg-accent/15 text-accent text-[10px] font-bold">{hotel.rating}</span>
                  <span className="text-[10px] text-muted-foreground">Excellent</span>
                </div>
                <div className="flex flex-wrap gap-1.5 pt-1">
                  {hotel.amenities.map((a) => {
                    const Icon = amenityIcons[a] || MapPin;
                    return (
                      <span key={a} className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-secondary/50 text-[10px] text-muted-foreground">
                        <Icon className="w-2.5 h-2.5" /> {a}
                      </span>
                    );
                  })}
                </div>
                <button
                  onClick={() => { addHistory({ id: hotel.id, type: "hotel", name: `${hotel.name} — booked` }); haptics.success(); }}
                  className="w-full mt-2 py-2.5 rounded-xl bg-primary text-primary-foreground text-xs font-semibold"
                >
                  Book Now
                </button>
              </div>
            </GlassCard>
          </AnimatedPage>
        );
      })}
    </div>
  );
};

export default HotelBooking;
