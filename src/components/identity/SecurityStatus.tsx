import React from "react";
import { motion } from "framer-motion";
import { ShieldCheck, Lock, Fingerprint, Globe } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

interface SecurityItem {
  label: string;
  status: "verified" | "pending" | "warning";
  icon: React.ElementType;
}

const items: SecurityItem[] = [
  { label: "Identity Verified", status: "verified", icon: ShieldCheck },
  { label: "Documents Valid", status: "verified", icon: Lock },
  { label: "Biometric Enrolled", status: "verified", icon: Fingerprint },
  { label: "Travel Clearance", status: "verified", icon: Globe },
];

const statusColors: Record<string, string> = {
  verified: "text-accent bg-accent/10",
  pending: "text-primary bg-primary/10",
  warning: "text-destructive bg-destructive/10",
};

const SecurityStatus: React.FC<{ className?: string }> = ({ className }) => (
  <div className={cn("glass rounded-xl p-4 space-y-3", className)}>
    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Security Status</p>
    <div className="space-y-2">
      {items.map((item, i) => {
        const Icon = item.icon;
        return (
          <motion.div
            key={item.label}
            initial={{ opacity: 0, x: -12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.08, duration: 0.35, ease: cinematicEase }}
            className="flex items-center gap-3"
          >
            <div className={cn("w-7 h-7 rounded-lg flex items-center justify-center", statusColors[item.status])}>
              <Icon className="w-3.5 h-3.5" />
            </div>
            <span className="text-xs font-medium text-foreground flex-1">{item.label}</span>
            <span className={cn("text-[10px] font-semibold capitalize", item.status === "verified" ? "text-accent" : "text-muted-foreground")}>
              {item.status}
            </span>
          </motion.div>
        );
      })}
    </div>
  </div>
);

export default SecurityStatus;
