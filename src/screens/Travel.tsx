import React, { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { demoBookings } from "@/lib/demoData";
import { demoFlightResults, demoHotelResults } from "@/lib/demoServices";
import { staggerDelay } from "@/hooks/useMotion";
import { Plane, Hotel, Search, Star, Clock, ChevronRight, QrCode } from "lucide-react";
import { cn } from "@/lib/utils";

type Tab = "bookings" | "flights" | "hotels" | "pass";

const Travel: React.FC = () => {
  const [tab, setTab] = useState<Tab>("bookings");

  const flights = demoBookings.filter((b) => b.type === "flight");
  const hotels = demoBookings.filter((b) => b.type === "hotel");

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: "bookings", label: "My Trips", icon: Plane },
    { key: "flights", label: "Flights", icon: Search },
    { key: "hotels", label: "Hotels", icon: Hotel },
    { key: "pass", label: "Pass", icon: QrCode },
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

      {/* My Trips / Bookings */}
      {tab === "bookings" && (
        <div className="space-y-3">
          <h3 className="text-sm font-medium text-muted-foreground px-1">Upcoming Flights</h3>
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

          <h3 className="text-sm font-medium text-muted-foreground px-1 mt-4">Hotels</h3>
          {hotels.map((bk, i) => (
            <AnimatedPage key={bk.id} staggerIndex={i + flights.length}>
              <GlassCard className="overflow-hidden cursor-pointer active:scale-[0.98] transition-transform p-0">
                {bk.image && (
                  <img src={bk.image} alt={bk.title} className="w-full h-36 object-cover" loading="lazy" />
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

      {/* Flight Search */}
      {tab === "flights" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard>
              <h3 className="text-sm font-semibold text-foreground mb-3">Search Flights</h3>
              <div className="grid grid-cols-2 gap-2 mb-3">
                <div className="px-3 py-2.5 rounded-lg glass border border-border">
                  <p className="text-[10px] text-muted-foreground">From</p>
                  <p className="text-sm font-medium text-foreground">SIN</p>
                </div>
                <div className="px-3 py-2.5 rounded-lg glass border border-border">
                  <p className="text-[10px] text-muted-foreground">To</p>
                  <p className="text-sm font-medium text-foreground">BOM</p>
                </div>
              </div>
              <div className="px-3 py-2.5 rounded-lg glass border border-border mb-3">
                <p className="text-[10px] text-muted-foreground">Date</p>
                <p className="text-sm font-medium text-foreground">Mar 15, 2026</p>
              </div>
              <p className="text-[10px] text-muted-foreground mb-2">Powered by Skyscanner, Expedia, Airline APIs</p>
            </GlassCard>
          </AnimatedPage>

          {demoFlightResults.map((fl, i) => (
            <AnimatedPage key={fl.id} staggerIndex={i}>
              <GlassCard className="cursor-pointer active:scale-[0.98] transition-transform">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-lg">{fl.icon}</span>
                    <div>
                      <p className="text-sm font-semibold text-foreground">{fl.airline}</p>
                      <p className="text-[10px] text-muted-foreground">{fl.airlineCode} · {fl.class}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-foreground">${fl.price}</p>
                    <p className="text-[10px] text-muted-foreground">{fl.currency}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <div className="text-center">
                    <p className="font-semibold text-foreground">{fl.departure}</p>
                    <p className="text-[10px] text-muted-foreground">{fl.from}</p>
                  </div>
                  <div className="flex-1 mx-3 flex flex-col items-center">
                    <p className="text-[10px] text-muted-foreground flex items-center gap-1"><Clock className="w-3 h-3" />{fl.duration}</p>
                    <div className="w-full h-px bg-border relative my-1">
                      <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-accent" />
                      <div className="absolute right-0 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-accent" />
                    </div>
                    <p className="text-[10px] text-muted-foreground">{fl.stops === 0 ? "Direct" : `${fl.stops} stop`}</p>
                  </div>
                  <div className="text-center">
                    <p className="font-semibold text-foreground">{fl.arrival}</p>
                    <p className="text-[10px] text-muted-foreground">{fl.to}</p>
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Hotel Search */}
      {tab === "hotels" && (
        <div className="space-y-3">
          <AnimatedPage>
            <GlassCard>
              <h3 className="text-sm font-semibold text-foreground mb-3">Search Hotels</h3>
              <div className="px-3 py-2.5 rounded-lg glass border border-border mb-2">
                <p className="text-[10px] text-muted-foreground">Destination</p>
                <p className="text-sm font-medium text-foreground">Mumbai, India</p>
              </div>
              <div className="grid grid-cols-2 gap-2 mb-3">
                <div className="px-3 py-2.5 rounded-lg glass border border-border">
                  <p className="text-[10px] text-muted-foreground">Check-in</p>
                  <p className="text-sm font-medium text-foreground">Mar 15</p>
                </div>
                <div className="px-3 py-2.5 rounded-lg glass border border-border">
                  <p className="text-[10px] text-muted-foreground">Check-out</p>
                  <p className="text-sm font-medium text-foreground">Mar 18</p>
                </div>
              </div>
              <p className="text-[10px] text-muted-foreground">Powered by Booking.com, Expedia, Hotels.com</p>
            </GlassCard>
          </AnimatedPage>

          {demoHotelResults.map((h, i) => (
            <AnimatedPage key={h.id} staggerIndex={i}>
              <GlassCard className={cn("overflow-hidden p-0 cursor-pointer active:scale-[0.98] transition-transform", !h.available && "opacity-50")}>
                <img src={h.image} alt={h.name} className="w-full h-32 object-cover" loading="lazy" />
                <div className="p-4">
                  <div className="flex items-center justify-between mb-1">
                    <p className="text-sm font-semibold text-foreground">{h.name}</p>
                    <div className="flex items-center gap-1">
                      <Star className="w-3 h-3 text-accent" />
                      <span className="text-xs font-medium text-foreground">{h.rating}</span>
                    </div>
                  </div>
                  <p className="text-xs text-muted-foreground">{h.location}</p>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {h.amenities.map((a) => (
                      <span key={a} className="text-[10px] px-2 py-0.5 rounded-full glass text-muted-foreground">{a}</span>
                    ))}
                  </div>
                  <div className="flex items-center justify-between mt-3">
                    <div>
                      <span className="text-lg font-bold text-foreground">${h.price}</span>
                      <span className="text-xs text-muted-foreground"> /night</span>
                    </div>
                    {h.available ? (
                      <button className="px-3 py-1.5 rounded-lg bg-accent text-accent-foreground text-xs font-medium active:scale-95 transition-transform min-h-[32px]">
                        Book Now
                      </button>
                    ) : (
                      <span className="text-xs text-muted-foreground">Sold out</span>
                    )}
                  </div>
                </div>
              </GlassCard>
            </AnimatedPage>
          ))}
        </div>
      )}

      {/* Travel Pass */}
      {tab === "pass" && (
        <div className="space-y-4">
          <AnimatedPage>
            <GlassCard neonBorder className="text-center py-6">
              <QrCode className="w-12 h-12 mx-auto text-accent mb-3" />
              <h3 className="text-sm font-semibold text-foreground mb-1">Travel Pass</h3>
              <p className="text-xs text-muted-foreground mb-4">
                Your unified boarding pass & hotel reservation
              </p>
              <div className="bg-secondary/50 rounded-xl p-4 mx-4 mb-4">
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider mb-2">Next Flight</p>
                <p className="text-lg font-bold text-foreground">SFO → SIN</p>
                <p className="text-xs text-muted-foreground">SQ31 · Mar 10, 2026 · 10:35 AM</p>
                <p className="text-xs text-accent mt-1">Seat 12A · Business</p>
              </div>
              <div className="bg-secondary/50 rounded-xl p-4 mx-4">
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider mb-2">Hotel</p>
                <p className="text-lg font-bold text-foreground">Marina Bay Sands</p>
                <p className="text-xs text-muted-foreground">Room 4012 · Mar 10–14</p>
                <p className="text-xs text-accent mt-1">Confirmed ✓</p>
              </div>
            </GlassCard>
          </AnimatedPage>

          <AnimatedPage staggerIndex={1}>
            <GlassCard>
              <div className="flex items-center gap-2 mb-2">
                <span className="text-lg">🛂</span>
                <h3 className="text-sm font-semibold text-foreground">Entry Status</h3>
              </div>
              <div className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Singapore</span>
                  <span className="text-accent font-medium">Verified ✓</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">India (upcoming)</span>
                  <span className="text-muted-foreground">Pending</span>
                </div>
              </div>
            </GlassCard>
          </AnimatedPage>
        </div>
      )}
    </div>
  );
};

export default Travel;
