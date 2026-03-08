import React from "react";
import { motion } from "framer-motion";
import { Shield, FileCheck, Plane, Globe, Stamp } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

interface TimelineEvent {
  id: string;
  icon: React.ElementType;
  title: string;
  description: string;
  date: string;
  color: string;
}

const events: TimelineEvent[] = [
  { id: "1", icon: Shield, title: "Passport Verified", description: "Indian passport scanned and verified", date: "Mar 8, 2026", color: "text-primary bg-primary/10" },
  { id: "2", icon: FileCheck, title: "US Visa Approved", description: "B1/B2 visa validated", date: "Mar 5, 2026", color: "text-accent bg-accent/10" },
  { id: "3", icon: Plane, title: "Boarding Pass Issued", description: "SQ31 SFO → SIN", date: "Mar 8, 2026", color: "text-primary bg-primary/10" },
  { id: "4", icon: Globe, title: "UAE Entry Granted", description: "Dubai immigration clearance", date: "Feb 20, 2026", color: "text-accent bg-accent/10" },
  { id: "5", icon: Stamp, title: "UK Entry Stamp", description: "London Heathrow arrival", date: "Feb 12, 2026", color: "text-primary bg-primary/10" },
];

const IdentityTimeline: React.FC<{ className?: string }> = ({ className }) => (
  <div className={cn("space-y-1", className)}>
    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1 mb-3">Identity Timeline</p>
    <div className="relative pl-6">
      {/* Vertical line */}
      <div className="absolute left-[11px] top-1 bottom-1 w-px bg-border" />
      {events.map((evt, i) => {
        const Icon = evt.icon;
        return (
          <motion.div
            key={evt.id}
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.08, duration: 0.4, ease: cinematicEase }}
            className="relative pb-4 last:pb-0"
          >
            {/* Dot */}
            <div className={cn("absolute -left-6 top-0.5 w-[22px] h-[22px] rounded-full flex items-center justify-center border-2 border-background", evt.color)}>
              <Icon className="w-3 h-3" />
            </div>
            <div>
              <p className="text-sm font-semibold text-foreground">{evt.title}</p>
              <p className="text-xs text-muted-foreground">{evt.description}</p>
              <p className="text-[10px] text-muted-foreground mt-0.5">{evt.date}</p>
            </div>
          </motion.div>
        );
      })}
    </div>
  </div>
);

export default IdentityTimeline;
