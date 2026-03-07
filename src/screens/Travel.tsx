import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoBookings } from "@/lib/demoData";
import { demoFlightResults, demoHotelResults } from "@/lib/demoServices";
import { getIcon } from "@/lib/iconMap";
import { staggerDelay } from "@/hooks/useMotion";
import { Plane, Hotel, Search, Star, Clock, ChevronRight, QrCode } from "lucide-react";
import { cn } from "@/lib/utils";

type Tab = "bookings" | "flights" | "hotels" | "pass";

const Travel: React.FC = () => {
  const [tab, setTab] = useState<Tab>("bookings");
  const flights = demoBookings.filter((b) => b.type === "flight");
  const hotels = demoBookings.filter((b) => b.type === "hotel");

  const tabs: { key: Tab; label: string; icon: React.ElementType; gradient: string }[] = [
    { key: "bookings", label: "My Trips", icon: Plane, gradient: "bg-gradient-ocean" },
    { key: "flights", label: "Flights", icon: Search, gradient: "bg-gradient-cosmic" },
    { key: "hotels", label: "Hotels", icon: Hotel, gradient: "bg-gradient-sunset" },
    { key: "pass", label: "Pass", icon: QrCode, gradient: "bg-gradient-forest" },
  ];

  return (
    <div className="px-4 py-6 space-y-5">
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

      {tab === "bookings" && (
        <div className="space-y-3">
          <h3 className="text-xs font-semibold text-muted-foreground px-1 uppercase tracking-widest">Upcoming Flights</h3>
          {flights.map((bk, i) => (
            <AnimatedPage key={bk.id} staggerIndex={i}>
              <GlassCard className="cursor-pointer touch-bounce" depth="md">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-xl bg-gradient-ocean flex items-center justify-center shrink-0 shadow-glow-sm">
                    <Plane className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold text-foreground">{bk.title}</p>
                    <p className="text-xs text-muted-foreground">{bk.subtitle}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground/60 shrink-0" />
                </div>
                <div className="mt-3 pt-3 border-t border-border/30 grid grid-cols-3 gap-2">
                  {Object.entries(bk.details).map(([k, v]) => (
                    <div key={k}><p className="text-[10px] text-muted-foreground capitalize">{k}</p><p className="text-xs font-semibold text-foreground">{v}</p></div>
                  ))}
                </div>
                <div className="mt-2 flex items-center justify-between">
                  <span className="text-[10px] text-muted-foreground font-mono">{bk.code}</span>
                  <span className={cn("text-[10px] px-2 py-0.5 rounded-full font-semibold",
                    bk.status === "confirmed" ? "bg-accent/15 text-accent" : bk.status === "upcoming" ? "bg-primary/15 text-primary" : "bg-muted text-muted-foreground"
                  )}>{bk.status}</span>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}

          <h3 className="text-xs font-semibold text-muted-foreground px-1 mt-4 uppercase tracking-widest">Hotels</h3>
          {hotels.map((bk, i) => (
            <AnimatedPage key={bk.id} staggerIndex={i + flights.length}>
              <GlassCard className="overflow-hidden cursor-pointer p-0 touch-bounce" depth="md">
                {bk.image && (
                  <div className="relative">
                    <img src={bk.image} alt={bk.title} className="w-full h-36 object-cover" loading="lazy" />
                    <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                  </div>
                )}
                <div className="p-4">
                  <p className="text-sm font-bold text-foreground">{bk.title}</p>
                  <p className="text-xs text-muted-foreground">{bk.subtitle}</p>
                  <div className="mt-3 grid grid-cols-2 gap-2">
                    {Object.entries(bk.details).map(([k, v]) => (
                      <div key={k}><p className="text-[10px] text-muted-foreground capitalize">{k}</p><p className="text-xs font-semibold text-foreground">{v}</p></div>
                    ))}
                  </div>
                  <div className="mt-2 flex items-center justify-between">
                    <span className="text-[10px] text-muted-foreground font-mono">{bk.code}</span>
                    <span className="text-[10px] px-2 py-0.5 rounded-full font-semibold bg-accent/15 text-accent">{bk.status}</span>
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {tab === "flights" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard variant="premium" depth="md">
              <h3 className="text-sm font-bold text-foreground mb-3">Search Flights</h3>
              <div className="grid grid-cols-2 gap-2 mb-3">
                <div className="px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/20"><p className="text-[10px] text-muted-foreground">From</p><p className="text-sm font-bold text-foreground">SIN</p></div>
                <div className="px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/20"><p className="text-[10px] text-muted-foreground">To</p><p className="text-sm font-bold text-foreground">BOM</p></div>
              </div>
              <div className="px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/20 mb-3"><p className="text-[10px] text-muted-foreground">Date</p><p className="text-sm font-bold text-foreground">Mar 15, 2026</p></div>
            </GlassCard>
          </AnimatedPage>

          {demoFlightResults.map((fl, i) => {
            const FlIcon = getIcon(fl.icon);
            return (
              <AnimatedPage key={fl.id} staggerIndex={i}>
                <GlassCard className="cursor-pointer touch-bounce">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-gradient-ocean flex items-center justify-center shadow-depth-sm">
                        <FlIcon className="w-4 h-4 text-primary-foreground" strokeWidth={1.8} />
                      </div>
                      <div><p className="text-sm font-bold text-foreground">{fl.airline}</p><p className="text-[10px] text-muted-foreground">{fl.airlineCode} · {fl.class}</p></div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold text-gradient-blue">${fl.price}</p>
                      <p className="text-[10px] text-muted-foreground">{fl.currency}</p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-xs mt-1">
                    <div className="text-center"><p className="font-bold text-foreground">{fl.departure}</p><p className="text-[10px] text-muted-foreground">{fl.from}</p></div>
                    <div className="flex-1 mx-3 flex flex-col items-center">
                      <p className="text-[10px] text-muted-foreground flex items-center gap-1"><Clock className="w-3 h-3" />{fl.duration}</p>
                      <div className="w-full h-px bg-gradient-to-r from-primary/40 via-primary to-primary/40 relative my-1.5">
                        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-primary shadow-glow-sm" />
                        <div className="absolute right-0 top-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-primary shadow-glow-sm" />
                      </div>
                      <p className="text-[10px] text-muted-foreground">{fl.stops === 0 ? "Direct" : `${fl.stops} stop`}</p>
                    </div>
                    <div className="text-center"><p className="font-bold text-foreground">{fl.arrival}</p><p className="text-[10px] text-muted-foreground">{fl.to}</p></div>
                  </div>
                </GlassCard>
              </AnimatedPage>
            );
          })}
        </div>
      )}

      {tab === "hotels" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard variant="premium" depth="md">
              <h3 className="text-sm font-bold text-foreground mb-3">Search Hotels</h3>
              <div className="px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/20 mb-2"><p className="text-[10px] text-muted-foreground">Destination</p><p className="text-sm font-bold text-foreground">Mumbai, India</p></div>
              <div className="grid grid-cols-2 gap-2 mb-3">
                <div className="px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/20"><p className="text-[10px] text-muted-foreground">Check-in</p><p className="text-sm font-bold text-foreground">Mar 15</p></div>
                <div className="px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/20"><p className="text-[10px] text-muted-foreground">Check-out</p><p className="text-sm font-bold text-foreground">Mar 18</p></div>
              </div>
            </GlassCard>
          </AnimatedPage>

          {demoHotelResults.map((h, i) => (
            <AnimatedPage key={h.id} staggerIndex={i}>
              <GlassCard className={cn("overflow-hidden p-0 cursor-pointer touch-bounce", !h.available && "opacity-50")} depth="md">
                <div className="relative">
                  <img src={h.image} alt={h.name} className="w-full h-36 object-cover" loading="lazy" />
                  <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent" />
                  <div className="absolute top-3 right-3 flex items-center gap-1 px-2 py-1 rounded-full glass border border-border/30">
                    <Star className="w-3 h-3 text-neon-amber" /><span className="text-xs font-bold text-foreground">{h.rating}</span>
                  </div>
                </div>
                <div className="p-4">
                  <p className="text-sm font-bold text-foreground">{h.name}</p>
                  <p className="text-xs text-muted-foreground">{h.location}</p>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {h.amenities.map((a) => <span key={a} className="text-[10px] px-2 py-0.5 rounded-full bg-secondary/50 text-muted-foreground border border-border/20">{a}</span>)}
                  </div>
                  <div className="flex items-center justify-between mt-3">
                    <div><span className="text-xl font-bold text-foreground">${h.price}</span><span className="text-xs text-muted-foreground"> /night</span></div>
                    {h.available ? (
                      <button className="px-4 py-2 rounded-xl bg-gradient-ocean text-primary-foreground text-xs font-semibold active:scale-95 transition-transform min-h-[36px] shadow-glow-sm btn-ripple">Book Now</button>
                    ) : <span className="text-xs text-muted-foreground">Sold out</span>}
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {tab === "pass" && (
        <div className="space-y-4">
          <AnimatedPage>
            <GlassCard neonBorder className="text-center py-8 light-sweep" variant="premium" depth="lg">
              <div className="w-14 h-14 rounded-2xl bg-gradient-forest flex items-center justify-center mx-auto mb-4 shadow-glow-md">
                <QrCode className="w-7 h-7 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <h3 className="text-sm font-bold text-foreground mb-1">Travel Pass</h3>
              <p className="text-xs text-muted-foreground mb-5">Your unified boarding pass & hotel reservation</p>
              <div className="bg-secondary/30 rounded-xl p-4 mx-4 mb-3 border border-border/20">
                <p className="text-[10px] text-muted-foreground uppercase tracking-widest mb-2 font-medium">Next Flight</p>
                <p className="text-xl font-bold text-foreground tracking-tight">SFO → SIN</p>
                <p className="text-xs text-muted-foreground mt-1">SQ31 · Mar 10, 2026 · 10:35 AM</p>
                <p className="text-xs text-accent mt-1 font-semibold">Seat 12A · Business</p>
              </div>
              <div className="bg-secondary/30 rounded-xl p-4 mx-4 border border-border/20">
                <p className="text-[10px] text-muted-foreground uppercase tracking-widest mb-2 font-medium">Hotel</p>
                <p className="text-xl font-bold text-foreground tracking-tight">Marina Bay Sands</p>
                <p className="text-xs text-muted-foreground mt-1">Room 4012 · Mar 10–14</p>
                <p className="text-xs text-accent mt-1 font-semibold">Confirmed</p>
              </div>
            </GlassCard>
          </AnimatedPage>
        </div>
      )}
    </div>
  );
};

export default Travel;
