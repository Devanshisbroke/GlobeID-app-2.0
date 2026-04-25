import React, { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoRideProviders, simulateRideRequest, type RideRequest } from "@/lib/demoServices";
import { detectCurrentLocation } from "@/lib/locationEngine";
import { useServiceFavoritesStore } from "@/store/serviceFavorites";
import { getIcon } from "@/lib/iconMap";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { ArrowLeft, MapPin, Star, Clock, Check, Car } from "lucide-react";

const RideBooking: React.FC = () => {
  const navigate = useNavigate();
  const location = useMemo(() => detectCurrentLocation(), []);
  const { addHistory } = useServiceFavoritesStore();
  const [pickup] = useState("Marina Bay Sands");
  const [dropoff] = useState("Changi Airport T3");
  const [activeRide, setActiveRide] = useState<RideRequest | null>(null);

  const handleRequest = (id: string) => {
    const ride = simulateRideRequest(id, pickup, dropoff);
    setActiveRide(ride);
    addHistory({ id: ride.id, type: "ride", name: `${ride.provider} to ${dropoff}` });
    haptics.success();
  };

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Rides</h1>
            <p className="text-xs text-muted-foreground">{location.city} · {demoRideProviders.length} providers</p>
          </div>
        </div>
      </AnimatedPage>

      {/* Route */}
      <AnimatedPage staggerIndex={0}>
        <GlassCard interactive={false}>
          <div className="space-y-2">
            <div className="flex items-center gap-2.5">
              <div className="w-2.5 h-2.5 rounded-full bg-primary shadow-glow-sm" />
              <span className="text-xs font-medium text-foreground">{pickup}</span>
            </div>
            <div className="ml-[5px] border-l border-dashed border-border/40 h-5" />
            <div className="flex items-center gap-2.5">
              <div className="w-2.5 h-2.5 rounded-full bg-destructive" />
              <span className="text-xs font-medium text-foreground">{dropoff}</span>
            </div>
          </div>
        </GlassCard>
      </AnimatedPage>

      {activeRide && (
        <AnimatedPage>
          <GlassCard neonBorder variant="premium" depth="lg">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-6 h-6 rounded-full bg-accent/15 flex items-center justify-center"><Check className="w-3.5 h-3.5 text-accent" /></div>
              <span className="text-sm font-bold text-accent">Ride Confirmed</span>
            </div>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between"><span className="text-muted-foreground">Driver</span><span className="font-medium text-foreground">{activeRide.driver?.name}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Vehicle</span><span className="font-medium text-foreground">{activeRide.driver?.vehicle} · {activeRide.driver?.plate}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">ETA</span><span className="font-medium text-foreground">{activeRide.eta}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Price</span><span className="font-bold text-foreground">{activeRide.currency} {activeRide.price}</span></div>
            </div>
          </GlassCard>
        </AnimatedPage>
      )}

      {demoRideProviders.map((p, i) => {
        const PIcon = getIcon(p.icon);
        return (
          <AnimatedPage key={p.id} staggerIndex={i + 1}>
            <GlassCard
              className={cn("flex items-center gap-3", !p.available && "opacity-40")}
              onClick={() => p.available && handleRequest(p.id)}
            >
              <div className="w-10 h-10 rounded-xl bg-gradient-brand flex items-center justify-center shrink-0 shadow-depth-sm">
                <PIcon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-bold text-foreground">{p.name}</p>
                  <span className="text-[10px] text-muted-foreground">{p.vehicleType}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                  <Clock className="w-3 h-3" /><span>{p.eta}</span>
                  <Star className="w-3 h-3 text-warning" /><span>{p.rating}</span>
                </div>
              </div>
              <p className="text-sm font-bold text-foreground">{p.currency} {p.price}</p>
            </GlassCard>
          </AnimatedPage>
        );
      })}
    </div>
  );
};

export default RideBooking;
