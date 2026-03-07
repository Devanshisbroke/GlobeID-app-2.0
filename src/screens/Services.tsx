/**
 * Services screen — local ecosystem hub for rides, food, and local services.
 * Backend replacement: integrate real provider APIs via edge functions.
 */
import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { staggerDelay } from "@/hooks/useMotion";
import {
  demoRideProviders,
  demoRestaurants,
  demoLocalServices,
  demoEmergencyContacts,
  simulateRideRequest,
  type RideRequest,
} from "@/lib/demoServices";
import { Car, UtensilsCrossed, MapPin, Shield, ChevronRight, Star, Clock, Check, Phone } from "lucide-react";
import { cn } from "@/lib/utils";

type Tab = "rides" | "food" | "local" | "safety";

const Services: React.FC = () => {
  const [tab, setTab] = useState<Tab>("rides");
  const [activeRide, setActiveRide] = useState<RideRequest | null>(null);
  const [pickup] = useState("Marina Bay Sands");
  const [dropoff] = useState("Changi Airport T3");

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: "rides", label: "Rides", icon: Car },
    { key: "food", label: "Food", icon: UtensilsCrossed },
    { key: "local", label: "Local", icon: MapPin },
    { key: "safety", label: "Safety", icon: Shield },
  ];

  const handleRequestRide = (providerId: string) => {
    const ride = simulateRideRequest(providerId, pickup, dropoff);
    setActiveRide(ride);
  };

  return (
    <div className="px-4 py-6 space-y-6">
      <AnimatedPage>
        <h1 className="text-xl font-bold text-foreground mb-1">Services</h1>
        <p className="text-xs text-muted-foreground">📍 Singapore — Local services available</p>
      </AnimatedPage>

      {/* Tab Switcher */}
      <AnimatedPage>
        <div className="flex gap-1 p-1 rounded-2xl glass border border-border">
          {tabs.map((t) => {
            const Icon = t.icon;
            const active = tab === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={cn(
                  "flex-1 flex items-center justify-center gap-1 py-2.5 rounded-xl text-xs font-medium transition-all duration-[var(--motion-small)] min-h-[44px]",
                  active
                    ? "bg-accent text-accent-foreground shadow-[0_0_12px_hsl(var(--neon-cyan)/0.3)]"
                    : "text-muted-foreground"
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
          {/* Active ride */}
          {activeRide && (
            <AnimatedPage>
              <GlassCard neonBorder>
                <div className="flex items-center gap-2 mb-3">
                  <Check className="w-4 h-4 text-accent" />
                  <span className="text-sm font-semibold text-accent">Ride Confirmed</span>
                </div>
                <div className="space-y-2 text-xs">
                  <div className="flex justify-between"><span className="text-muted-foreground">Driver</span><span className="text-foreground">{activeRide.driver?.name}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">Vehicle</span><span className="text-foreground">{activeRide.driver?.vehicle} · {activeRide.driver?.plate}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">ETA</span><span className="text-foreground">{activeRide.eta}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">Price</span><span className="text-foreground font-semibold">{activeRide.currency} {activeRide.price}</span></div>
                </div>
              </GlassCard>
            </AnimatedPage>
          )}

          {/* Route */}
          <AnimatedPage>
            <GlassCard>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-accent" />
                  <span className="text-xs text-foreground">{pickup}</span>
                </div>
                <div className="ml-1 border-l border-dashed border-border h-4" />
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-destructive" />
                  <span className="text-xs text-foreground">{dropoff}</span>
                </div>
              </div>
            </GlassCard>
          </AnimatedPage>

          {/* Providers */}
          {demoRideProviders.map((provider, i) => (
            <AnimatedPage key={provider.id} staggerIndex={i}>
              <GlassCard
                className={cn(
                  "flex items-center gap-3 cursor-pointer active:scale-[0.98] transition-transform",
                  !provider.available && "opacity-50"
                )}
                onClick={() => provider.available && handleRequestRide(provider.id)}
              >
                <span className="text-2xl">{provider.icon}</span>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-foreground">{provider.name}</p>
                    <span className="text-[10px] text-muted-foreground">{provider.vehicleType}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <Clock className="w-3 h-3" />
                    <span>{provider.eta}</span>
                    <Star className="w-3 h-3" />
                    <span>{provider.rating}</span>
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
              <GlassCard className="overflow-hidden p-0 cursor-pointer active:scale-[0.98] transition-transform">
                <img src={r.image} alt={r.name} className="w-full h-32 object-cover" loading="lazy" />
                <div className="p-4">
                  <div className="flex items-center justify-between mb-1">
                    <p className="text-sm font-semibold text-foreground">{r.icon} {r.name}</p>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-accent/20 text-accent">{r.provider}</span>
                  </div>
                  <p className="text-xs text-muted-foreground">{r.cuisine}</p>
                  <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1"><Star className="w-3 h-3 text-accent" />{r.rating}</span>
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

      {/* Local Services */}
      {tab === "local" && (
        <div className="space-y-2">
          {demoLocalServices.map((s, i) => (
            <AnimatedPage key={s.id} staggerIndex={i}>
              <GlassCard className="flex items-center gap-3 cursor-pointer active:scale-[0.98] transition-transform">
                <span className="text-xl">{s.icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground">{s.name}</p>
                  <p className="text-xs text-muted-foreground">{s.description}</p>
                </div>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Safety */}
      {tab === "safety" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard neonBorder>
              <h3 className="text-sm font-semibold text-foreground mb-2 flex items-center gap-2">
                <Shield className="w-4 h-4 text-accent" />
                Emergency Contacts — Singapore
              </h3>
              <div className="space-y-2">
                {demoEmergencyContacts.map((c) => (
                  <div key={c.id} className="flex items-center gap-3 py-2">
                    <span className="text-lg">{c.icon}</span>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-foreground">{c.name}</p>
                    </div>
                    <a
                      href={`tel:${c.number}`}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-accent/20 text-accent text-xs font-medium min-h-[36px]"
                    >
                      <Phone className="w-3 h-3" />
                      {c.number}
                    </a>
                  </div>
                ))}
              </div>
            </GlassCard>
          </AnimatedPage>

          <AnimatedPage staggerIndex={1}>
            <GlassCard>
              <button className="w-full py-3 rounded-xl bg-destructive text-destructive-foreground text-sm font-medium active:scale-95 transition-transform min-h-[44px]">
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
