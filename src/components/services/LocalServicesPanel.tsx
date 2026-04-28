import React, { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Phone, MapPin } from "lucide-react";
import { api, ApiError } from "@/lib/apiClient";
import type { LocalService, ServiceKind } from "@shared/data/localServicesCatalog";

const KINDS: ServiceKind[] = [
  "embassy",
  "hospital",
  "pharmacy",
  "laundry",
  "sim_store",
  "atm",
  "police",
  "tourism_info",
  "lost_property",
];

const LocalServicesPanel: React.FC = () => {
  const [country, setCountry] = useState("SG");
  const [kind, setKind] = useState<ServiceKind | "">("");
  const [results, setResults] = useState<LocalService[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const search = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.local.services({
        country: country || undefined,
        kind: kind || undefined,
      });
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
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Local services</p>
        <div className="grid grid-cols-2 gap-2">
          <Input
            value={country}
            onChange={(e) => setCountry(e.target.value.toUpperCase().slice(0, 2))}
            placeholder="ISO-2 (e.g. SG)"
            className="text-xs font-mono uppercase"
          />
          <select
            value={kind}
            onChange={(e) => setKind(e.target.value as ServiceKind | "")}
            className="rounded-md border border-input bg-background text-xs px-2 capitalize"
          >
            <option value="">All kinds</option>
            {KINDS.map((k) => (
              <option key={k} value={k}>
                {k.replace("_", " ")}
              </option>
            ))}
          </select>
        </div>
        <Button size="sm" onClick={search} disabled={loading} className="w-full">
          {loading ? <Loader2 className="w-3 h-3 animate-spin mr-1" /> : null} Find services
        </Button>
        {error && <p className="text-[11px] text-destructive">{error}</p>}
      </GlassCard>

      {results.map((s) => (
        <GlassCard key={s.id} className="p-3">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-xl bg-secondary/50 flex items-center justify-center shrink-0">
              <MapPin className="w-5 h-5 text-foreground" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-foreground">{s.name}</p>
              <p className="text-[11px] text-muted-foreground capitalize">
                {s.kind.replace("_", " ")} · {s.cityIata} · {s.languages.join(", ")}
              </p>
              <p className="text-[11px] text-muted-foreground">{s.address}</p>
              <p className="text-[10px] text-muted-foreground">
                {s.hours247 ? "Open 24/7" : (s.hours ?? "Hours: see source")} · {s.free ? "Free" : "Paid"}
              </p>
            </div>
            <div className="flex flex-col gap-1.5 items-end">
              {s.phoneE164 && (
                <a
                  href={`tel:${s.phoneE164}`}
                  className="text-[11px] text-primary hover:underline flex items-center gap-1"
                >
                  <Phone className="w-3 h-3" /> Call
                </a>
              )}
              <a
                href={`https://www.google.com/maps?q=${s.lat},${s.lng}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[11px] text-primary hover:underline flex items-center gap-1"
              >
                <MapPin className="w-3 h-3" /> Map
              </a>
            </div>
          </div>
        </GlassCard>
      ))}
    </div>
  );
};

export default React.memo(LocalServicesPanel);
