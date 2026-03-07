import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoBookings } from "@/lib/demoData";
import { staggerDelay } from "@/hooks/useMotion";
import { Plane, Hotel, Car, UtensilsCrossed, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

type Tab = "flights" | "hotels" | "services";

const Travel: React.FC = () => {
  const [tab, setTab] = useState<Tab>("flights");

  const flights = demoBookings.filter((b) => b.type === "flight");
  const hotels = demoBookings.filter((b) => b.type === "hotel");

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: "flights", label: "Flights", icon: Plane },
    { key: "hotels", label: "Hotels", icon: Hotel },
    { key: "services", label: "Services", icon: Car },
  ];

  return (
    <div className="px-4 py-6 space-y-6">
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
                  "flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-[var(--motion-small)] min-h-[44px]",
                  active
                    ? "bg-accent text-accent-foreground shadow-[0_0_12px_hsl(var(--neon-cyan)/0.3)]"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                <Icon className="w-4 h-4" />
                {t.label}
              </button>
            );
          })}
        </div>
      </AnimatedPage>

      {/* Flights */}
      {tab === "flights" && (
        <div className="space-y-3">
          {flights.map((bk, i) => (
            <AnimatedPage key={bk.id} staggerIndex={i}>
              <GlassCard className="cursor-pointer active:scale-[0.98] transition-transform">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-neon-indigo to-neon-cyan flex items-center justify-center shrink-0">
                    <Plane className="w-5 h-5 text-primary-foreground" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-foreground">{bk.title}</p>
                    <p className="text-xs text-muted-foreground">{bk.subtitle}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
                </div>
                <div className="mt-3 pt-3 border-t border-border grid grid-cols-3 gap-2">
                  {Object.entries(bk.details).map(([k, v]) => (
                    <div key={k}>
                      <p className="text-[10px] text-muted-foreground capitalize">{k}</p>
                      <p className="text-xs font-medium text-foreground">{v}</p>
                    </div>
                  ))}
                </div>
                <div className="mt-2 flex items-center justify-between">
                  <span className="text-[10px] text-muted-foreground">{bk.code}</span>
                  <span className={cn(
                    "text-[10px] px-2 py-0.5 rounded-full font-medium",
                    bk.status === "confirmed" ? "bg-accent/20 text-accent" :
                    bk.status === "upcoming" ? "bg-primary/20 text-primary" :
                    "bg-muted text-muted-foreground"
                  )}>
                    {bk.status}
                  </span>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Hotels */}
      {tab === "hotels" && (
        <div className="space-y-3">
          {hotels.map((bk, i) => (
            <AnimatedPage key={bk.id} staggerIndex={i}>
              <GlassCard className="overflow-hidden cursor-pointer active:scale-[0.98] transition-transform p-0">
                {bk.image && (
                  <img
                    src={bk.image}
                    alt={bk.title}
                    className="w-full h-36 object-cover"
                    loading="lazy"
                  />
                )}
                <div className="p-4">
                  <p className="text-sm font-semibold text-foreground">{bk.title}</p>
                  <p className="text-xs text-muted-foreground">{bk.subtitle}</p>
                  <div className="mt-3 grid grid-cols-2 gap-2">
                    {Object.entries(bk.details).map(([k, v]) => (
                      <div key={k}>
                        <p className="text-[10px] text-muted-foreground capitalize">{k}</p>
                        <p className="text-xs font-medium text-foreground">{v}</p>
                      </div>
                    ))}
                  </div>
                  <div className="mt-2 flex items-center justify-between">
                    <span className="text-[10px] text-muted-foreground">{bk.code}</span>
                    <span className="text-[10px] px-2 py-0.5 rounded-full font-medium bg-accent/20 text-accent">
                      {bk.status}
                    </span>
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Services */}
      {tab === "services" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard className="flex items-center gap-4 cursor-pointer active:scale-[0.98] transition-transform">
              <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center">
                <Car className="w-6 h-6 text-accent" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-foreground">Request a Ride</p>
                <p className="text-xs text-muted-foreground">
                  Book from multiple providers
                </p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </GlassCard>
          </AnimatedPage>

          <AnimatedPage staggerIndex={1}>
            <GlassCard className="flex items-center gap-4 cursor-pointer active:scale-[0.98] transition-transform">
              <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center">
                <UtensilsCrossed className="w-6 h-6 text-accent" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-foreground">Order Food</p>
                <p className="text-xs text-muted-foreground">
                  Restaurants & hotel room delivery
                </p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </GlassCard>
          </AnimatedPage>
        </div>
      )}
    </div>
  );
};

export default Travel;
