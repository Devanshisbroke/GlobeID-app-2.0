import React, { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { detectCurrentLocation, getTransportOptions } from "@/lib/locationEngine";
import { getIcon } from "@/lib/iconMap";
import { cn } from "@/lib/utils";
import { ArrowLeft, Clock } from "lucide-react";

const typeGradients: Record<string, string> = {
  metro: "bg-gradient-cosmic",
  bus: "bg-gradient-forest",
  shuttle: "bg-gradient-ocean",
  bike: "bg-gradient-aurora",
  ferry: "bg-gradient-sunset",
};

const Transport: React.FC = () => {
  const navigate = useNavigate();
  const location = useMemo(() => detectCurrentLocation(), []);
  const options = useMemo(() => getTransportOptions(location.country), [location.country]);

  return (
    <div className="px-4 py-6 pb-28 space-y-5">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center">
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Transport</h1>
            <p className="text-xs text-muted-foreground">{location.city} · City transit options</p>
          </div>
        </div>
      </AnimatedPage>

      {options.map((opt, i) => {
        const Icon = getIcon(opt.icon);
        return (
          <AnimatedPage key={opt.id} staggerIndex={i}>
            <GlassCard className="flex items-center gap-3" depth="md">
              <div className={cn("w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-depth-sm", typeGradients[opt.type] || "bg-gradient-ocean")}>
                <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-foreground">{opt.name}</p>
                <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                  <Clock className="w-3 h-3" />
                  <span>{opt.frequency}</span>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm font-bold text-foreground">{opt.price}</p>
                <p className="text-[10px] text-muted-foreground capitalize">{opt.type}</p>
              </div>
            </GlassCard>
          </AnimatedPage>
        );
      })}
    </div>
  );
};

export default Transport;
