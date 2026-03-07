import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { staggerDelay } from "@/hooks/useMotion";
import {
  demoRideProviders, demoRestaurants, demoLocalServices, demoEmergencyContacts,
  simulateRideRequest, type RideRequest,
} from "@/lib/demoServices";
import { Car, UtensilsCrossed, MapPin, Shield, ChevronRight, Star, Clock, Check, Phone } from "lucide-react";
import { cn } from "@/lib/utils";

type Tab = "rides" | "food" | "local" | "safety";

const Services: React.FC = () => {
  const [tab, setTab] = useState<Tab>("rides");
  const [activeRide, setActiveRide] = useState<RideRequest | null>(null);
  const [pickup] = useState("Marina Bay Sands");
  const [dropoff] = useState("Changi Airport T3");

  const tabs: { key: Tab; label: string; icon: React.ElementType; color: string }[] = [
    { key: "rides", label: "Rides", icon: Car, color: "bg-gradient-warm" },
    { key: "food", label: "Food", icon: UtensilsCrossed, color: "bg-gradient-magenta" },
    { key: "local", label: "Local", icon: MapPin, color: "bg-gradient-blue" },
    { key: "safety", label: "Safety", icon: Shield, color: "bg-gradient-tropical" },
  ];

  const handleRequestRide = (providerId: string) => {
    const ride = simulateRideRequest(providerId, pickup, dropoff);
    setActiveRide(ride);
  };

  return (
    <div className="px-4 py-6 space-y-6">
      <AnimatedPage>
        <h1 className="text-xl font-bold text-foreground mb-1">Services</h1>
        <p className="text-xs text-muted-foreground flex items-center gap-1.5">
          <MapPin className="w-3 h-3 text-accent" />
          Singapore — Local services available
        </p>
      </AnimatedPage>

      {/* Tab Switcher — colorful */}
      <AnimatedPage>
        <div className="flex gap-1.5 p-1 rounded-2xl glass border border-border/40">
          {tabs.map((t) => {
            const Icon = t.icon;
            const active = tab === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={cn(
                  "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-semibold transition-all duration-[var(--motion-small)] min-h-[44px]",
                  active
                    ? `${t.color} text-primary-foreground shadow-depth-sm`
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                <Icon className="w-3.5 h-3.5" />
                {t.label}
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {/* Rides */}
      {tab === "rides" && (
        <div className="space-y-3">
          {activeRide && (
            <AnimatedPage>
              <GlassCard neonBorder depth="lg">
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-6 h-6 rounded-full bg-accent/15 flex items-center justify-center">
                    <Check className="w-3.5 h-3.5 text-accent" />
                  </div>
                  <span className="text-sm font-bold text-accent">Ride Confirmed</span>
                </div>
                <div className="space-y-2.5 text-xs">
                  <div className="flex justify-between"><span className="text-muted-foreground">Driver</span><span className="text-foreground font-medium">{activeRide.driver?.name}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">Vehicle</span><span className="text-foreground font-medium">{activeRide.driver?.vehicle} · {activeRide.driver?.plate}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">ETA</span><span className="text-foreground font-medium">{activeRide.eta}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">Price</span><span className="text-foreground font-bold">{activeRide.currency} {activeRide.price}</span></div>
                </div>
              </GlassCard>
            </AnimatedPage>
          )}

          <AnimatedPage>
            <GlassCard>
              <div className="space-y-2">
                <div className="flex items-center gap-2.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-primary shadow-glow-sm" />
                  <span className="text-xs text-foreground font-medium">{pickup}</span>
                </div>
                <div className="ml-[5px] border-l border-dashed border-border/40 h-5" />
                <div className="flex items-center gap-2.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-destructive" />
                  <span className="text-xs text-foreground font-medium">{dropoff}</span>
                </div>
              </div>
            </GlassCard>
          </AnimatedPage>

          {demoRideProviders.map((provider, i) => (
            <AnimatedPage key={provider.id} staggerIndex={i}>
              <GlassCard
                className={cn("flex items-center gap-3 cursor-pointer", !provider.available && "opacity-40")}
                onClick={() => provider.available && handleRequestRide(provider.id)}
              >
                <span className="text-2xl">{provider.icon}</span>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold text-foreground">{provider.name}</p>
                    <span className="text-[10px] text-muted-foreground">{provider.vehicleType}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                    <Clock className="w-3 h-3" /><span>{provider.eta}</span>
                    <Star className="w-3 h-3 text-neon-amber" /><span>{provider.rating}</span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold text-foreground">{provider.currency} {provider.price}</p>
                  {!provider.available && <p className="text-[10px] text-muted-foreground">Unavailable</p>}
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Food */}
      {tab === "food" && (
        <div className="space-y-3">
          {demoRestaurants.map((r, i) => (
            <AnimatedPage key={r.id} staggerIndex={i}>
              <GlassCard className="overflow-hidden p-0 cursor-pointer" depth="md">
                <div className="relative">
                  <img src={r.image} alt={r.name} className="w-full h-36 object-cover" loading="lazy" />
                  <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                  <span className="absolute top-3 right-3 text-[10px] px-2.5 py-1 rounded-full glass font-semibold text-foreground">{r.provider}</span>
                </div>
                <div className="p-4">
                  <p className="text-sm font-bold text-foreground">{r.icon} {r.name}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">{r.cuisine}</p>
                  <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1"><Star className="w-3 h-3 text-neon-amber" />{r.rating}</span>
                    <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{r.deliveryTime}</span>
                    <span>{r.deliveryFee}</span>
                    <span>{r.priceRange}</span>
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Local */}
      {tab === "local" && (
        <div className="space-y-2">
          {demoLocalServices.map((s, i) => (
            <AnimatedPage key={s.id} staggerIndex={i}>
              <GlassCard className="flex items-center gap-3 cursor-pointer">
                <span className="text-xl">{s.icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground">{s.name}</p>
                  <p className="text-xs text-muted-foreground">{s.description}</p>
                </div>
                <ChevronRight className="w-4 h-4 text-muted-foreground/60" />
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Safety */}
      {tab === "safety" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard neonBorder depth="md">
              <h3 className="text-sm font-bold text-foreground mb-3 flex items-center gap-2">
                <Shield className="w-4 h-4 text-accent" />
                Emergency Contacts — Singapore
              </h3>
              <div className="space-y-2">
                {demoEmergencyContacts.map((c) => (
                  <div key={c.id} className="flex items-center gap-3 py-2.5 border-b border-border/20 last:border-0">
                    <span className="text-lg">{c.icon}</span>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-foreground">{c.name}</p>
                    </div>
                    <a
                      href={`tel:${c.number}`}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-accent/10 text-accent text-xs font-semibold min-h-[36px] hover:bg-accent/20 transition-colors"
                    >
                      <Phone className="w-3 h-3" />{c.number}
                    </a>
                  </div>
                ))}
              </div>
            </GlassCard>
          </AnimatedPage>
          <AnimatedPage staggerIndex={1}>
            <GlassCard>
              <button className="w-full py-3.5 rounded-xl bg-gradient-to-r from-destructive to-destructive/80 text-destructive-foreground text-sm font-bold active:scale-95 transition-transform min-h-[44px] shadow-depth-md btn-ripple">
                🆘 Share Live Location
              </button>
              <p className="text-[10px] text-muted-foreground text-center mt-2">
                Shares your location with trusted contacts for 1 hour
              </p>
            </GlassCard>
          </AnimatedPage>
        </div>
      )}
    </div>
  );
};

export default Services;
