import React from "react";
import { useNavigate } from "react-router-dom";
import { ChevronRight, Plane, Wallet, Compass, ShieldCheck } from "lucide-react";
import { Surface, Pill, Text } from "@/components/ui/v2";
import { useRecommendationsStore } from "@/store/recommendationsStore";
import { getTravelSuggestions } from "@/lib/travelSuggestions";
import { useUserStore, selectVisitedCountries } from "@/store/userStore";
import { getIcon } from "@/lib/iconMap";
import { cn } from "@/lib/utils";
import type { Recommendation } from "@shared/types/insights";

const KIND_ICON: Record<
  Recommendation["kind"],
  React.ComponentType<{ className?: string; strokeWidth?: number }>
> = {
  trip_continuation: Plane,
  next_destination: Compass,
  currency_action: Wallet,
  readiness: ShieldCheck,
};

const KIND_HALO: Record<Recommendation["kind"], string> = {
  trip_continuation: "bg-state-accent-soft text-state-accent",
  next_destination: "bg-brand-soft text-brand",
  currency_action: "bg-[hsl(var(--p7-warning-soft))] text-[hsl(var(--p7-warning))]",
  readiness: "bg-brand-soft text-brand",
};

const Suggestions: React.FC = () => {
  const navigate = useNavigate();
  const recommendations = useRecommendationsStore((s) => s.items);
  const recsStatus = useRecommendationsStore((s) => s.status);

  const travelHistory = useUserStore((s) => s.travelHistory);
  const nationality = useUserStore((s) => s.profile.nationality);
  const fallback = React.useMemo(
    () => getTravelSuggestions(nationality, selectVisitedCountries(travelHistory)),
    [nationality, travelHistory],
  );

  const handleAction = (rec: Recommendation) => {
    if (rec.kind === "currency_action") navigate("/wallet");
    else navigate("/map");
  };

  if (recsStatus === "ready" && recommendations.length > 0) {
    return (
      <div className="space-y-2.5">
        {recommendations.slice(0, 3).map((rec) => {
          const Icon = KIND_ICON[rec.kind];
          return (
            <Surface
              key={rec.id}
              variant="elevated"
              radius="surface"
              className="p-3.5 cursor-pointer transition-transform active:scale-[0.99]"
              onClick={() => handleAction(rec)}
            >
              <div className="flex items-center gap-3">
                <div
                  className={cn(
                    "w-10 h-10 rounded-p7-input flex items-center justify-center shrink-0",
                    KIND_HALO[rec.kind],
                  )}
                >
                  <Icon className="w-5 h-5" strokeWidth={1.8} />
                </div>
                <div className="flex-1 min-w-0">
                  <Text variant="body-em" tone="primary" truncate>
                    {rec.title}
                  </Text>
                  <Text variant="caption-1" tone="tertiary" className="line-clamp-2">
                    {rec.description}
                  </Text>
                </div>
                <ChevronRight className="w-4 h-4 text-ink-tertiary shrink-0" />
              </div>
            </Surface>
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
          <Surface
            key={sug.id}
            variant="elevated"
            radius="surface"
            className="p-3.5 cursor-pointer transition-transform active:scale-[0.99]"
            onClick={() => navigate("/map")}
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-p7-input bg-brand-soft flex items-center justify-center shrink-0">
                <SugIcon className="w-5 h-5 text-brand" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <Text variant="body-em" tone="primary" truncate>
                  {sug.title}
                </Text>
                <Text variant="caption-1" tone="tertiary" truncate>
                  {sug.description}
                </Text>
                {sug.countries.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-1.5">
                    {sug.countries.slice(0, 3).map((c) => (
                      <Pill key={c} tone="neutral" weight="outline">
                        {c}
                      </Pill>
                    ))}
                    {sug.countries.length > 3 && (
                      <Pill tone="neutral" weight="outline">
                        +{sug.countries.length - 3}
                      </Pill>
                    )}
                  </div>
                )}
              </div>
              <ChevronRight className="w-4 h-4 text-ink-tertiary shrink-0" />
            </div>
          </Surface>
        );
      })}
    </div>
  );
};

export default Suggestions;
