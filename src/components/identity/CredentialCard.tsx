import React from "react";
import { motion } from "framer-motion";
import { FileText, Shield, Syringe, Plane, Clock, ShieldCheck, AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";
import { TravelDocument } from "@/store/userStore";
import { cinematicEase } from "@/cinematic/motionEngine";

const typeConfig: Record<string, { icon: React.ElementType; gradient: string; label: string }> = {
  passport: { icon: Shield, gradient: "from-[hsl(var(--ocean-deep))] to-[hsl(var(--ocean-blue))]", label: "Passport" },
  visa: { icon: FileText, gradient: "from-[hsl(var(--primary))] to-[hsl(var(--ocean-aqua))]", label: "Visa" },
  boarding_pass: { icon: Plane, gradient: "from-[hsl(var(--accent))] to-[hsl(var(--ocean-turquoise))]", label: "Boarding Pass" },
  travel_insurance: { icon: ShieldCheck, gradient: "from-[hsl(185,72%,48%)] to-[hsl(168,70%,45%)]", label: "Insurance" },
  vaccination: { icon: Syringe, gradient: "from-[hsl(var(--accent))] to-[hsl(168,70%,45%)]", label: "Vaccination" },
};

const statusConfig: Record<string, { color: string; label: string; icon: React.ElementType }> = {
  active: { color: "text-accent bg-accent/10", label: "Active", icon: ShieldCheck },
  expired: { color: "text-destructive bg-destructive/10", label: "Expired", icon: AlertTriangle },
  pending: { color: "text-primary bg-primary/10", label: "Pending", icon: Clock },
};

interface CredentialCardProps {
  doc: TravelDocument;
  index?: number;
  onTap?: () => void;
  className?: string;
}

const CredentialCard: React.FC<CredentialCardProps> = ({ doc, index = 0, onTap, className }) => {
  const type = typeConfig[doc.type] ?? typeConfig.passport;
  const status = statusConfig[doc.status] ?? statusConfig.active;
  const Icon = type.icon;
  const StatusIcon = status.icon;

  return (
    <motion.div
      initial={{ opacity: 0, y: 16, filter: "blur(4px)" }}
      animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
      transition={{ duration: 0.4, delay: index * 0.06, ease: cinematicEase }}
      onClick={onTap}
      className={cn(
        "glass rounded-xl p-3.5 cursor-pointer active:scale-[0.98] transition-transform",
        className
      )}
    >
      <div className="flex items-center gap-3">
        <div className={cn("w-10 h-10 rounded-xl bg-gradient-to-br flex items-center justify-center shrink-0", type.gradient)}>
          <Icon className="w-4.5 h-4.5 text-primary-foreground" strokeWidth={1.8} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-semibold text-foreground truncate">{doc.label}</p>
          <p className="text-xs text-muted-foreground">{doc.countryFlag} {doc.country} · {doc.number}</p>
        </div>
        <div className={cn("flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold", status.color)}>
          <StatusIcon className="w-3 h-3" />
          {status.label}
        </div>
      </div>
    </motion.div>
  );
};

export default CredentialCard;
