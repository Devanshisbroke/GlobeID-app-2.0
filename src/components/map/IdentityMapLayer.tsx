import React from "react";
import { motion } from "framer-motion";
import { MapPin, ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

interface EntryMarker {
  id: string;
  country: string;
  flag: string;
  port: string;
  lat: number;
  lng: number;
  date: string;
}

const entryMarkers: EntryMarker[] = [
  { id: "uk", country: "United Kingdom", flag: "🇬🇧", port: "LHR", lat: 51.47, lng: -0.46, date: "Feb 12" },
  { id: "fr", country: "France", flag: "🇫🇷", port: "CDG", lat: 49.0, lng: 2.55, date: "Feb 15" },
  { id: "ae", country: "UAE", flag: "🇦🇪", port: "DXB", lat: 25.25, lng: 55.36, date: "Feb 18" },
  { id: "in", country: "India", flag: "🇮🇳", port: "BOM", lat: 19.09, lng: 72.87, date: "Feb 25" },
  { id: "sg", country: "Singapore", flag: "🇸🇬", port: "SIN", lat: 1.36, lng: 103.99, date: "Mar 10" },
];

const IdentityMapLayer: React.FC<{ className?: string }> = ({ className }) => (
  <div className={cn("space-y-3", className)}>
    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1">Verified Entry Points</p>
    <div className="grid gap-2">
      {entryMarkers.map((marker, i) => (
        <motion.div
          key={marker.id}
          initial={{ opacity: 0, x: -12 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: i * 0.06, duration: 0.35, ease: cinematicEase }}
          className="glass rounded-lg p-2.5 flex items-center gap-3"
        >
          <span className="text-lg">{marker.flag}</span>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-foreground">{marker.country}</p>
            <p className="text-[10px] text-muted-foreground">{marker.port} · {marker.date}</p>
          </div>
          <ShieldCheck className="w-3.5 h-3.5 text-accent shrink-0" />
        </motion.div>
      ))}
    </div>
  </div>
);

export default IdentityMapLayer;
