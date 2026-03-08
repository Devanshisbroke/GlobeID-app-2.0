import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { staggerDelay } from "@/hooks/useMotion";
import { getIcon } from "@/lib/iconMap";
import {
  demoRideProviders, demoRestaurants, demoEmergencyContacts,
  simulateRideRequest, type RideRequest,
} from "@/lib/demoServices";
import { Car, UtensilsCrossed, MapPin, Shield, ChevronRight, Star, Clock, Check, Phone, Globe, Wifi, CreditCard, Umbrella, ArrowLeftRight, Hotel, Compass, Train, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";
import ServiceCard from "@/components/services/ServiceCard";

type Tab = "rides" | "food" | "services" | "safety";

const travelServices = [
  { id: "ts-1", title: "Visa Assistance", description: "Apply for e-visas and track applications", icon: <Globe className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />, gradient: "bg-gradient-ocean" },
  { id: "ts-2", title: "Travel Insurance", description: "Compare and purchase travel coverage", icon: <Umbrella className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />, gradient: "bg-gradient-forest" },
  { id: "ts-3", title: "Airport Lounge Access", description: "Book premium lounge passes worldwide", icon: <CreditCard className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />, gradient: "bg-gradient-cosmic" },
  { id: "ts-4", title: "Global SIM", description: "eSIM data plans for 190+ countries", icon: <Wifi className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />, gradient: "bg-gradient-aurora" },
  { id: "ts-5", title: "Currency Exchange", description: "Real-time rates and instant conversion", icon: <ArrowLeftRight className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />, gradient: "bg-gradient-sunset" },
];

const Services: React.FC = () => {
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>("services");
  const [activeRide, setActiveRide] = useState<RideRequest | null>(null);
  const [pickup] = useState("Marina Bay Sands");
  const [dropoff] = useState("Changi Airport T3");

  const tabs: { key: Tab; label: string; icon: React.ElementType; gradient: string }[] = [
    { key: "services", label: "Services", icon: Globe, gradient: "bg-gradient-ocean" },
    { key: "rides", label: "Rides", icon: Car, gradient: "bg-gradient-sunset" },
    { key: "food", label: "Food", icon: UtensilsCrossed, gradient: "bg-gradient-aurora" },
    { key: "safety", label: "Safety", icon: Shield, gradient: "bg-gradient-forest" },
  ];

  const handleRequestRide = (providerId: string) => {
    const ride = simulateRideRequest(providerId, pickup, dropoff);
    setActiveRide(ride);
  };

  return (
    <div className="px-4 py-6 space-y-5">
      <AnimatedPage>
        <h1 className="text-xl font-bold text-foreground mb-1">Services</h1>
        <p className="text-xs text-muted-foreground flex items-center gap-1.5">
          <MapPin className="w-3 h-3 text-accent" /> Singapore — Local services available
        </p>
      </AnimatedPage>

      <AnimatedPage>
        <div className="flex gap-1.5 p-1 rounded-2xl glass border border-border/40">
          {tabs.map((t) => {
            const Icon = t.icon;
            const active = tab === t.key;
            return (
              <button key={t.key} onClick={() => setTab(t.key)} className={cn(
                "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-semibold transition-all duration-[var(--motion-small)] min-h-[44px]",
                active ? `${t.gradient} text-primary-foreground shadow-depth-sm` : "text-muted-foreground hover:text-foreground"
              )}>
                <Icon className="w-3.5 h-3.5" strokeWidth={1.8} />{t.label}
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {tab === "services" && (
        <div className="space-y-3">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Travel Services</h3>
          {travelServices.map((svc, i) => (
            <AnimatedPage key={svc.id} staggerIndex={i}>
              <ServiceCard
                title={svc.title}
                description={svc.description}
                icon={svc.icon}
                gradient={svc.gradient}
              />
            </AnimatedPage>
          ))}
        </div>
      )}

      {tab === "rides" && (
        <div className="space-y-3">
          {activeRide && (
            <AnimatedPage>
              <GlassCard neonBorder variant="premium" depth="lg">
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-6 h-6 rounded-full bg-accent/15 flex items-center justify-center"><Check className="w-3.5 h-3.5 text-accent" /></div>
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
                <div className="flex items-center gap-2.5"><div className="w-2.5 h-2.5 rounded-full bg-primary shadow-glow-sm" /><span className="text-xs text-foreground font-medium">{pickup}</span></div>
                <div className="ml-[5px] border-l border-dashed border-border/40 h-5" />
                <div className="flex items-center gap-2.5"><div className="w-2.5 h-2.5 rounded-full bg-destructive" /><span className="text-xs text-foreground font-medium">{dropoff}</span></div>
              </div>
            </GlassCard>
          </AnimatedPage>
          {demoRideProviders.map((provider, i) => {
            const PIcon = getIcon(provider.icon);
            return (
              <AnimatedPage key={provider.id} staggerIndex={i}>
                <GlassCard className={cn("flex items-center gap-3 cursor-pointer touch-bounce", !provider.available && "opacity-40")} onClick={() => provider.available && handleRequestRide(provider.id)}>
                  <div className="w-10 h-10 rounded-xl bg-gradient-sunset flex items-center justify-center shrink-0 shadow-depth-sm">
                    <PIcon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2"><p className="text-sm font-bold text-foreground">{provider.name}</p><span className="text-[10px] text-muted-foreground">{provider.vehicleType}</span></div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                      <Clock className="w-3 h-3" /><span>{provider.eta}</span><Star className="w-3 h-3 text-neon-amber" /><span>{provider.rating}</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-foreground">{provider.currency} {provider.price}</p>
                    {!provider.available && <p className="text-[10px] text-muted-foreground">Unavailable</p>}
                  </div>
                </GlassCard>
              </AnimatedPage>
            );
          })}
        </div>
      )}

      {tab === "food" && (
        <div className="space-y-3">
          {demoRestaurants.map((r, i) => {
            const RIcon = getIcon(r.icon);
            return (
              <AnimatedPage key={r.id} staggerIndex={i}>
                <GlassCard className="overflow-hidden p-0 cursor-pointer touch-bounce" depth="md">
                  <div className="relative">
                    <img src={r.image} alt={r.name} className="w-full h-36 object-cover" loading="lazy" />
                    <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                    <span className="absolute top-3 right-3 text-[10px] px-2.5 py-1 rounded-full glass font-semibold text-foreground border border-border/30">{r.provider}</span>
                  </div>
                  <div className="p-4">
                    <div className="flex items-center gap-2">
                      <RIcon className="w-4 h-4 text-muted-foreground" strokeWidth={1.8} />
                      <p className="text-sm font-bold text-foreground">{r.name}</p>
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">{r.cuisine}</p>
                    <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1"><Star className="w-3 h-3 text-neon-amber" />{r.rating}</span>
                      <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{r.deliveryTime}</span>
                      <span>{r.deliveryFee}</span><span>{r.priceRange}</span>
                    </div>
                  </div>
                </GlassCard>
              </AnimatedPage>
            );
          })}
        </div>
      )}

      {tab === "safety" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard neonBorder variant="premium" depth="md">
              <h3 className="text-sm font-bold text-foreground mb-3 flex items-center gap-2">
                <Shield className="w-4 h-4 text-accent" /> Emergency Contacts — Singapore
              </h3>
              <div className="space-y-2">
                {demoEmergencyContacts.map((c) => {
                  const CIcon = getIcon(c.icon);
                  return (
                    <div key={c.id} className="flex items-center gap-3 py-2.5 border-b border-border/20 last:border-0">
                      <div className="w-8 h-8 rounded-lg bg-secondary/60 flex items-center justify-center border border-border/20">
                        <CIcon className="w-4 h-4 text-muted-foreground" strokeWidth={1.8} />
                      </div>
                      <div className="flex-1"><p className="text-sm font-medium text-foreground">{c.name}</p></div>
                      <a href={`tel:${c.number}`} className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-accent/10 text-accent text-xs font-semibold min-h-[36px] hover:bg-accent/20 transition-colors touch-bounce">
                        <Phone className="w-3 h-3" />{c.number}
                      </a>
                    </div>
                  );
                })}
              </div>
            </GlassCard>
          </AnimatedPage>
          <AnimatedPage staggerIndex={1}>
            <GlassCard>
              <button className="w-full py-3.5 rounded-xl bg-gradient-to-r from-destructive to-destructive/80 text-destructive-foreground text-sm font-bold active:scale-95 transition-transform min-h-[44px] shadow-depth-md btn-ripple">
                Share Live Location
              </button>
              <p className="text-[10px] text-muted-foreground text-center mt-2">Shares your location with trusted contacts for 1 hour</p>
            </GlassCard>
          </AnimatedPage>
        </div>
      )}
    </div>
  );
};

export default Services;
