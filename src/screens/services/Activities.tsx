import React, { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { detectCurrentLocation, getActivities } from "@/lib/locationEngine";
import { useServiceFavoritesStore } from "@/store/serviceFavorites";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { ArrowLeft, Star, Clock, MapPin, Heart } from "lucide-react";

const Activities: React.FC = () => {
  const navigate = useNavigate();
  const location = useMemo(() => detectCurrentLocation(), []);
  const activities = useMemo(() => getActivities(location.country), [location.country]);
  const { favorites, toggleFavorite, addHistory } = useServiceFavoritesStore();

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Activities</h1>
            <p className="text-xs text-muted-foreground">{location.city} · {activities.length} experiences</p>
          </div>
        </div>
      </AnimatedPage>

      {activities.map((act, i) => {
        const isFav = favorites.includes(act.id);
        return (
          <AnimatedPage key={act.id} staggerIndex={i}>
            <GlassCard interactive={false} className="overflow-hidden p-0" depth="md">
              <div className="relative">
                <img src={act.image} alt={act.name} className="w-full h-36 object-cover" loading="lazy" />
                <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                <span className="absolute top-3 left-3 text-[10px] px-2.5 py-1 rounded-full glass font-semibold text-foreground border border-border/30">{act.category}</span>
                <button
                  onClick={() => { toggleFavorite(act.id); haptics.selection(); }}
                  className="absolute top-3 right-3 w-8 h-8 rounded-full glass flex items-center justify-center border border-border/30"
                >
                  <Heart className={cn("w-4 h-4", isFav ? "fill-destructive text-destructive" : "text-primary-foreground")} />
                </button>
              </div>
              <div className="p-4 space-y-2">
                <h3 className="text-sm font-bold text-foreground">{act.name}</h3>
                <div className="flex items-center gap-3 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1"><Star className="w-3 h-3 text-warning" />{act.rating}</span>
                  <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{act.duration}</span>
                  <span className="flex items-center gap-1"><MapPin className="w-3 h-3" />{act.location}</span>
                </div>
                <div className="flex items-center justify-between pt-1">
                  <p className="text-lg font-bold text-foreground">{act.currency} {act.price}</p>
                  <button
                    onClick={() => { addHistory({ id: act.id, type: "activity", name: act.name }); haptics.success(); }}
                    className="px-4 py-2 rounded-xl bg-primary text-primary-foreground text-xs font-semibold"
                  >
                    Book
                  </button>
                </div>
              </div>
            </GlassCard>
          </AnimatedPage>
        );
      })}
    </div>
  );
};

export default Activities;
