import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { useRecommendationsStore } from "@/store/recommendationsStore";
import { getTravelSuggestions } from "@/lib/travelSuggestions";
import { useUserStore, selectVisitedCountries } from "@/store/userStore";
import { getIcon } from "@/lib/iconMap";
import { ChevronRight, Plane, Wallet, Compass, ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Recommendation } from "@shared/types/insights";

const KIND_ICON: Record<Recommendation["kind"], React.ComponentType<{ className?: string; strokeWidth?: number }>> = {
  trip_continuation: Plane,
  next_destination: Compass,
  currency_action: Wallet,
  readiness: ShieldCheck,
};

const KIND_GRADIENT: Record<Recommendation["kind"], string> = {
  trip_continuation: "bg-gradient-to-br from-accent to-primary",
  next_destination: "bg-gradient-to-br from-primary to-neon-amber",
  currency_action: "bg-gradient-to-br from-neon-amber to-primary",
  readiness: "bg-gradient-to-br from-primary to-accent",
};

const Suggestions: React.FC = () => {
  const navigate = useNavigate();
  const recommendations = useRecommendationsStore((s) => s.items);
  const recsStatus = useRecommendationsStore((s) => s.status);

  // Fallback to local catalog while backend hydrates or in offline mode.
  const travelHistory = useUserStore((s) => s.travelHistory);
  const nationality = useUserStore((s) => s.profile.nationality);
  const fallback = React.useMemo(
    () => getTravelSuggestions(nationality, selectVisitedCountries(travelHistory)),
    [nationality, travelHistory]
  );

  const handleAction = (rec: Recommendation) => {
    if (rec.kind === "currency_action") navigate("/wallet");
    else navigate("/map");
  };

  // Backend ready & has items → use them. Otherwise fall back so we never
  // render an empty card on cold boot.
  if (recsStatus === "ready" && recommendations.length > 0) {
    return (
      <div className="space-y-2.5">
        {recommendations.slice(0, 3).map((rec) => {
          const Icon = KIND_ICON[rec.kind];
          return (
            <GlassCard
              key={rec.id}
              className="cursor-pointer touch-bounce"
              onClick={() => handleAction(rec)}
            >
              <div className="flex items-center gap-3">
                <div
                  className={cn(
                    "w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm",
                    KIND_GRADIENT[rec.kind]
                  )}
                >
                  <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-foreground">{rec.title}</p>
                  <p className="text-xs text-muted-foreground line-clamp-2">{rec.description}</p>
                </div>
                <ChevronRight className="w-4 h-4 text-muted-foreground/50 shrink-0" />
              </div>
            </GlassCard>
          );
        })}
      </div>
    );
  }

  return (
    <div className="space-y-2.5">
      {fallback.slice(0, 3).map((sug) => {
        const SugIcon = getIcon(sug.icon);
        return (
          <GlassCard key={sug.id} className="cursor-pointer touch-bounce" onClick={() => navigate("/map")}>
            <div className="flex items-center gap-3">
              <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm", sug.gradient)}>
                <SugIcon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-foreground">{sug.title}</p>
                <p className="text-xs text-muted-foreground">{sug.description}</p>
                {sug.countries.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-1.5">
                    {sug.countries.slice(0, 3).map((c) => (
                      <span key={c} className="text-[9px] px-1.5 py-0.5 rounded-full bg-secondary/50 text-muted-foreground border border-border/20">{c}</span>
                    ))}
                    {sug.countries.length > 3 && (
                      <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-secondary/50 text-muted-foreground">+{sug.countries.length - 3}</span>
                    )}
                  </div>
                )}
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground/50 shrink-0" />
            </div>
          </GlassCard>
        );
      })}
    </div>
  );
};

export default Suggestions;
