import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { FileText, Plane, ShieldCheck, CreditCard, Clock } from "lucide-react";
import { cn } from "@/lib/utils";
import type { TravelDocument } from "@/store/userStore";

interface DocumentCardProps {
  doc: TravelDocument;
  className?: string;
}

const typeConfig = {
  passport: { icon: FileText, gradient: "bg-gradient-brand", label: "Passport" },
  visa: { icon: ShieldCheck, gradient: "bg-gradient-brand", label: "Visa" },
  boarding_pass: { icon: Plane, gradient: "bg-gradient-brand", label: "Boarding Pass" },
  travel_insurance: { icon: CreditCard, gradient: "bg-gradient-brand", label: "Insurance" },
};

const statusColors = {
  active: "bg-accent/15 text-accent",
  expired: "bg-destructive/15 text-destructive",
  pending: "bg-primary/15 text-primary",
};

const DocumentCard: React.FC<DocumentCardProps> = ({ doc, className }) => {
  const config = typeConfig[doc.type];
  const Icon = config.icon;

  return (
    <GlassCard className={cn("cursor-pointer touch-bounce", className)} depth="md">
      <div className="flex items-center gap-3">
        <div className={cn("w-11 h-11 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm", config.gradient)}>
          <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-bold text-foreground">{doc.label}</p>
          <p className="text-xs text-muted-foreground">
            {doc.countryFlag} {doc.country} · {doc.number}
          </p>
        </div>
        <span className={cn("text-[10px] px-2 py-0.5 rounded-full font-semibold", statusColors[doc.status])}>
          {doc.status}
        </span>
      </div>
      <div className="mt-3 pt-3 border-t border-border/30 grid grid-cols-2 gap-2 text-xs">
        <div>
          <p className="text-muted-foreground">Type</p>
          <p className="text-foreground font-medium">{config.label}</p>
        </div>
        <div>
          <p className="text-muted-foreground">Expires</p>
          <p className="text-foreground font-medium flex items-center gap-1">
            <Clock className="w-3 h-3" />{doc.expiryDate}
          </p>
        </div>
      </div>
    </GlassCard>
  );
};

export default DocumentCard;
