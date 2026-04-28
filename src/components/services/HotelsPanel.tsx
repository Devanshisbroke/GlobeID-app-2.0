import React, { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Hotel as HotelIcon, Star } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";
import type { Hotel } from "@shared/data/hotelsCatalog";

interface HotelHit extends Hotel {
  totalUsd: number | null;
  nights: number | null;
}

type Sort = "price_asc" | "price_desc" | "rating_desc" | "stars_desc" | "distance_asc";

const SORTS: Array<{ key: Sort; label: string }> = [
  { key: "rating_desc", label: "Top rated" },
  { key: "price_asc", label: "Cheapest" },
  { key: "price_desc", label: "Premium" },
  { key: "stars_desc", label: "5 stars first" },
  { key: "distance_asc", label: "Closest to centre" },
];

const HotelsPanel: React.FC = () => {
  const [city, setCity] = useState("SIN");
  const [minStar, setMinStar] = useState(3);
  const [maxPrice, setMaxPrice] = useState(2000);
  const [sort, setSort] = useState<Sort>("rating_desc");
  const [results, setResults] = useState<HotelHit[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const search = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.hotels.search({ city, minStar, maxPrice, sort });
      setResults(r.results);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Search failed");
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void search();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="space-y-3">
      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Hotel search</p>
        <div className="grid grid-cols-3 gap-2">
          <Input
            value={city}
            onChange={(e) => setCity(e.target.value.toUpperCase().slice(0, 3))}
            placeholder="city IATA (e.g. SIN)"
            className="text-xs font-mono uppercase"
          />
          <Input
            type="number"
            min={3}
            max={5}
            value={minStar}
            onChange={(e) => setMinStar(Number(e.target.value))}
            placeholder="min stars"
            className="text-xs"
          />
          <Input
            type="number"
            min={50}
            value={maxPrice}
            onChange={(e) => setMaxPrice(Number(e.target.value))}
            placeholder="max $/night"
            className="text-xs"
          />
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {SORTS.map((s) => (
            <button
              key={s.key}
              onClick={() => setSort(s.key)}
              className={`text-[10px] px-2 py-1 rounded-full border whitespace-nowrap ${
                sort === s.key ? "bg-primary text-primary-foreground border-primary" : "border-border/40 text-muted-foreground"
              }`}
            >
              {s.label}
            </button>
          ))}
        </div>
        <Button size="sm" onClick={search} disabled={loading} className="w-full">
          {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null} Search hotels
        </Button>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {results.map((h) => (
        <GlassCard key={h.id} className="p-3 flex items-start gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
            <HotelIcon className="w-5 h-5 text-primary" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-foreground truncate">{h.name}</p>
            <div className="flex items-center gap-2 text-[11px] text-muted-foreground">
              <span className="flex items-center gap-0.5">
                {Array.from({ length: h.starRating }).map((_, i) => (
                  <Star key={i} className="w-3 h-3 fill-amber-400 text-amber-400" />
                ))}
              </span>
              <span>· {h.rating.toFixed(1)} ({h.reviews.toLocaleString()})</span>
              <span>· {h.cityCentreKm} km from centre</span>
            </div>
            <p className="text-[10px] text-muted-foreground mt-0.5">{h.amenities.slice(0, 4).join(" · ")}</p>
          </div>
          <div className="text-right">
            <p className="text-sm font-bold text-foreground">${h.pricePerNightUsd}</p>
            <p className="text-[10px] text-muted-foreground">/night</p>
          </div>
        </GlassCard>
      ))}
    </div>
  );
};

export default React.memo(HotelsPanel);
