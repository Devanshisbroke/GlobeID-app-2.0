import React from "react";
import { motion } from "motion/react";
import {
  FileText,
  Shield,
  Syringe,
  Plane,
  Clock,
  ShieldCheck,
  AlertTriangle,
} from "lucide-react";
import { Surface, Pill, Text, ease, duration } from "@/components/ui/v2";
import type { TravelDocument } from "@/store/userStore";
import { cn } from "@/lib/utils";

type DocType = TravelDocument["type"];
type DocStatus = TravelDocument["status"];

const TYPE_CONFIG: Record<
  DocType,
  { icon: React.ElementType; label: string; halo: string }
> = {
  passport: {
    icon: Shield,
    label: "Passport",
    halo: "bg-brand-soft text-brand",
  },
  visa: {
    icon: FileText,
    label: "Visa",
    halo: "bg-state-accent-soft text-state-accent",
  },
  boarding_pass: {
    icon: Plane,
    label: "Boarding Pass",
    halo: "bg-brand-soft text-brand",
  },
  travel_insurance: {
    icon: ShieldCheck,
    label: "Insurance",
    halo: "bg-state-accent-soft text-state-accent",
  },
  vaccination: {
    icon: Syringe,
    label: "Vaccination",
    halo: "bg-state-accent-soft text-state-accent",
  },
};

const STATUS_CONFIG: Record<
  DocStatus,
  { tone: "accent" | "critical" | "brand"; label: string; icon: React.ElementType }
> = {
  active: { tone: "accent", label: "Active", icon: ShieldCheck },
  expired: { tone: "critical", label: "Expired", icon: AlertTriangle },
  pending: { tone: "brand", label: "Pending", icon: Clock },
};

interface CredentialCardProps {
  doc: TravelDocument;
  index?: number;
  onTap?: () => void;
  className?: string;
}

const CredentialCard: React.FC<CredentialCardProps> = ({
  doc,
  index = 0,
  onTap,
  className,
}) => {
  const type = TYPE_CONFIG[doc.type] ?? TYPE_CONFIG.passport;
  const status = STATUS_CONFIG[doc.status] ?? STATUS_CONFIG.active;
  const Icon = type.icon;
  const StatusIcon = status.icon;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10, filter: "blur(2px)" }}
      animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
      transition={{ duration: duration.page, delay: index * 0.05, ease: ease.standard }}
    >
      <Surface
        variant="elevated"
        radius="surface"
        onClick={onTap}
        className={cn(
          "p-3.5 cursor-pointer transition-transform active:scale-[0.99]",
          className,
        )}
      >
        <div className="flex items-center gap-3">
          <div
            className={cn(
              "w-10 h-10 rounded-p7-input flex items-center justify-center shrink-0",
              type.halo,
            )}
          >
            <Icon className="w-4 h-4" strokeWidth={1.8} />
          </div>
          <div className="flex-1 min-w-0">
            <Text variant="body-em" tone="primary" truncate>
              {doc.label}
            </Text>
            <Text variant="caption-1" tone="tertiary" truncate>
              {doc.countryFlag} {doc.country} · {doc.number}
            </Text>
          </div>
          <Pill tone={status.tone} weight="tinted">
            <StatusIcon className="w-3 h-3" />
            {status.label}
          </Pill>
        </div>
      </Surface>
    </motion.div>
  );
};

export default CredentialCard;
