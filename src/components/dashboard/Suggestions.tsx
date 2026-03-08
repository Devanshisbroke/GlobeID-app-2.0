import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { getTravelSuggestions } from "@/lib/travelSuggestions";
import { visitedCountries } from "@/lib/airports";
import { getIcon } from "@/lib/iconMap";
import { ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

const Suggestions: React.FC = () => {
  const navigate = useNavigate();
  const suggestions = getTravelSuggestions("India", visitedCountries);

  return (
    <div className="space-y-2.5">
      {suggestions.slice(0, 3).map((sug) => {
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
