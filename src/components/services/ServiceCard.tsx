import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

interface ServiceCardProps {
  title: string;
  description: string;
  icon: React.ReactNode;
  gradient?: string;
  onAction?: () => void;
  className?: string;
}

const ServiceCard: React.FC<ServiceCardProps> = ({ title, description, icon, gradient = "bg-gradient-brand", onAction, className }) => {
  return (
    <GlassCard className={cn("flex items-center gap-3 cursor-pointer touch-bounce", className)} onClick={onAction}>
      <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm", gradient)}>
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-foreground">{title}</p>
        <p className="text-xs text-muted-foreground">{description}</p>
      </div>
      <ChevronRight className="w-4 h-4 text-muted-foreground/60 shrink-0" />
    </GlassCard>
  );
};

export default ServiceCard;
