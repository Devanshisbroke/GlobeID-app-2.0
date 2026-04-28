import React, { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Pizza, Star } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";
import type { Restaurant } from "@shared/data/foodCatalog";

const FoodPanel: React.FC = () => {
  const [city, setCity] = useState("SIN");
  const [cuisine, setCuisine] = useState("");
  const [results, setResults] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [activeQuote, setActiveQuote] = useState<{
    restaurantId: string;
    totalUsd: number;
    subtotalUsd: number;
    taxUsd: number;
    deliveryUsd: number;
    etaMinutes: number;
  } | null>(null);

  const search = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.food.restaurants({ city, cuisine: cuisine || undefined, sort: "rating_desc" });
      setResults(r.results);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Search failed");
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  const quoteSampler = async (r: Restaurant) => {
    const items = r.menu.slice(0, 2).map((m) => ({ menuItemId: m.id, qty: 1 }));
    if (items.length === 0) return;
    setActiveQuote(null);
    try {
      const q = await api.food.quote({ restaurantId: r.id, items });
      setActiveQuote({
        restaurantId: r.id,
        totalUsd: q.totalUsd,
        subtotalUsd: q.subtotalUsd,
        taxUsd: q.taxUsd,
        deliveryUsd: q.deliveryUsd,
        etaMinutes: q.etaMinutes,
      });
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Quote failed");
    }
  };

  useEffect(() => {
    void search();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Restaurants</p>
        <div className="grid grid-cols-2 gap-2">
          <Input
            value={city}
            onChange={(e) => setCity(e.target.value.toUpperCase().slice(0, 3))}
            placeholder="city IATA"
            className="text-xs font-mono uppercase"
          />
          <Input
            value={cuisine}
            onChange={(e) => setCuisine(e.target.value.toLowerCase())}
            placeholder="cuisine (e.g. thai)"
            className="text-xs"
          />
        </div>
        <Button size="sm" onClick={search} disabled={loading} className="w-full">
          {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null} Search
        </Button>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {results.map((r) => (
        <GlassCard key={r.id} className="p-3">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
              <Pizza className="w-5 h-5 text-primary" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-foreground truncate">{r.name}</p>
              <p className="text-[11px] text-muted-foreground capitalize">
                {r.cuisine} · {r.priceTier} · <Star className="inline w-3 h-3 fill-amber-400 text-amber-400" /> {r.rating.toFixed(1)} ({r.reviews})
              </p>
              <p className="text-[10px] text-muted-foreground">
                ETA {r.etaMinutes} min · delivery ${r.deliveryFeeUsd.toFixed(2)}
              </p>
            </div>
            <Button size="sm" variant="outline" onClick={() => quoteSampler(r)}>
              Sample cart
            </Button>
          </div>
          {activeQuote && activeQuote.restaurantId === r.id && (
            <div className="mt-2 pt-2 border-t border-border/30 text-[11px] text-foreground">
              <div className="flex justify-between">
                <span>Subtotal (2 items)</span>
                <span>${activeQuote.subtotalUsd.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-muted-foreground">
                <span>Tax</span>
                <span>${activeQuote.taxUsd.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-muted-foreground">
                <span>Delivery</span>
                <span>${activeQuote.deliveryUsd.toFixed(2)}</span>
              </div>
              <div className="flex justify-between font-bold mt-1">
                <span>Total</span>
                <span>${activeQuote.totalUsd.toFixed(2)}</span>
              </div>
            </div>
          )}
        </GlassCard>
      ))}
    </div>
  );
};

export default React.memo(FoodPanel);
