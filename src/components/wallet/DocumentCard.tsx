import React from "react";
import { FileText, Plane, ShieldCheck, CreditCard, Clock } from "lucide-react";
import { Surface, Pill, Text } from "@/components/ui/v2";
import type { TravelDocument } from "@/store/userStore";
import { cn } from "@/lib/utils";

interface DocumentCardProps {
  doc: TravelDocument;
  className?: string;
}

const TYPE_CONFIG = {
  passport: { icon: FileText, label: "Passport" },
  visa: { icon: ShieldCheck, label: "Visa" },
  boarding_pass: { icon: Plane, label: "Boarding Pass" },
  travel_insurance: { icon: CreditCard, label: "Insurance" },
} as const;

const STATUS_TONE = {
  active: "accent",
  expired: "critical",
  pending: "brand",
} as const satisfies Record<TravelDocument["status"], "accent" | "critical" | "brand">;

const DocumentCard: React.FC<DocumentCardProps> = ({ doc, className }) => {
  const config = TYPE_CONFIG[doc.type];
  const Icon = config.icon;

  return (
    <Surface
      variant="elevated"
      radius="surface"
      className={cn("p-3.5 cursor-pointer transition-transform active:scale-[0.99]", className)}
    >
      <div className="flex items-center gap-3">
        <div className="w-11 h-11 rounded-p7-input bg-brand-soft flex items-center justify-center shrink-0">
          <Icon className="w-5 h-5 text-brand" strokeWidth={1.8} />
        </div>
        <div className="flex-1 min-w-0">
          <Text variant="body-em" tone="primary" truncate>
            {doc.label}
          </Text>
          <Text variant="caption-1" tone="tertiary" truncate>
            {doc.countryFlag} {doc.country} · {doc.number}
          </Text>
        </div>
        <Pill tone={STATUS_TONE[doc.status]} weight="tinted">
          {doc.status}
        </Pill>
      </div>
      <div className="mt-3 pt-3 border-t border-surface-hairline grid grid-cols-2 gap-2">
        <div>
          <Text variant="caption-2" tone="tertiary">
            Type
          </Text>
          <Text variant="caption-1" tone="primary" className="font-medium">
            {config.label}
          </Text>
        </div>
        <div>
          <Text variant="caption-2" tone="tertiary">
            Expires
          </Text>
          <Text variant="caption-1" tone="primary" className="font-medium flex items-center gap-1">
            <Clock className="w-3 h-3" />
            {doc.expiryDate}
          </Text>
        </div>
      </div>
    </Surface>
  );
};

export default DocumentCard;
