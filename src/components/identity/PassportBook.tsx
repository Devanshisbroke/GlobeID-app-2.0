import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronLeft, ChevronRight } from "lucide-react";
import EntryStamp from "./EntryStamp";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

interface StampData {
  country: string;
  flag: string;
  date: string;
  port: string;
  type: "entry" | "exit";
}

const stamps: StampData[] = [
  { country: "United Kingdom", flag: "🇬🇧", date: "Feb 12, 2026", port: "LHR", type: "entry" },
  { country: "United Kingdom", flag: "🇬🇧", date: "Feb 15, 2026", port: "LHR", type: "exit" },
  { country: "France", flag: "🇫🇷", date: "Feb 15, 2026", port: "CDG", type: "entry" },
  { country: "France", flag: "🇫🇷", date: "Feb 18, 2026", port: "CDG", type: "exit" },
  { country: "UAE", flag: "🇦🇪", date: "Feb 18, 2026", port: "DXB", type: "entry" },
  { country: "UAE", flag: "🇦🇪", date: "Feb 24, 2026", port: "DXB", type: "exit" },
  { country: "Singapore", flag: "🇸🇬", date: "Mar 10, 2026", port: "SIN", type: "entry" },
  { country: "Japan", flag: "🇯🇵", date: "Mar 20, 2026", port: "NRT", type: "entry" },
];

const STAMPS_PER_PAGE = 4;
const totalPages = Math.ceil(stamps.length / STAMPS_PER_PAGE);

const PassportBook: React.FC<{ className?: string }> = ({ className }) => {
  const [page, setPage] = useState(0);
  const pageStamps = stamps.slice(page * STAMPS_PER_PAGE, (page + 1) * STAMPS_PER_PAGE);

  return (
    <div className={cn("space-y-4", className)}>
      <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1">Passport Book</p>

      <div className="relative glass rounded-2xl overflow-hidden min-h-[240px]">
        {/* Page texture */}
        <div className="absolute inset-0 opacity-[0.03] bg-[repeating-linear-gradient(0deg,transparent,transparent_20px,hsl(var(--foreground))_20px,hsl(var(--foreground))_21px)]" />

        <AnimatePresence mode="wait">
          <motion.div
            key={page}
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
            transition={{ duration: 0.35, ease: cinematicEase }}
            className="p-5"
          >
            <div className="flex items-center justify-between mb-3">
              <span className="text-[10px] text-muted-foreground font-mono">Page {page + 1} of {totalPages}</span>
            </div>
            <div className="grid grid-cols-2 gap-3 place-items-center">
              {pageStamps.map((stamp, i) => (
                <EntryStamp key={`${stamp.country}-${stamp.type}-${stamp.date}`} {...stamp} index={i} />
              ))}
            </div>
          </motion.div>
        </AnimatePresence>

        {/* Navigation */}
        <div className="absolute bottom-3 left-0 right-0 flex items-center justify-center gap-3">
          <button
            onClick={() => setPage(Math.max(0, page - 1))}
            disabled={page === 0}
            className="w-8 h-8 rounded-full glass flex items-center justify-center disabled:opacity-30 active:scale-90 transition-transform"
          >
            <ChevronLeft className="w-4 h-4 text-foreground" />
          </button>
          {Array.from({ length: totalPages }).map((_, i) => (
            <div key={i} className={cn("w-1.5 h-1.5 rounded-full transition-colors", i === page ? "bg-primary" : "bg-muted-foreground/30")} />
          ))}
          <button
            onClick={() => setPage(Math.min(totalPages - 1, page + 1))}
            disabled={page >= totalPages - 1}
            className="w-8 h-8 rounded-full glass flex items-center justify-center disabled:opacity-30 active:scale-90 transition-transform"
          >
            <ChevronRight className="w-4 h-4 text-foreground" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default PassportBook;
