import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

interface EntryStampProps {
  country: string;
  flag: string;
  date: string;
  port: string;
  type?: "entry" | "exit";
  index?: number;
  className?: string;
}

const EntryStamp: React.FC<EntryStampProps> = ({ country, flag, date, port, type = "entry", index = 0, className }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.7, rotate: -8 }}
    animate={{ opacity: 1, scale: 1, rotate: (index % 2 === 0 ? -2 : 3) }}
    transition={{ delay: index * 0.12, duration: 0.5, ease: cinematicEase }}
    className={cn(
      "relative inline-flex flex-col items-center justify-center w-28 h-28 rounded-full border-2 border-dashed p-2 text-center",
      type === "entry" ? "border-accent/40 text-accent" : "border-destructive/40 text-destructive",
      className
    )}
  >
    <span className="text-2xl leading-none">{flag}</span>
    <span className="text-[9px] font-bold uppercase tracking-wider mt-1">{country}</span>
    <span className="text-[8px] opacity-70">{port}</span>
    <span className="text-[8px] font-mono opacity-60">{date}</span>
    <span className={cn(
      "absolute -bottom-1 text-[7px] font-bold uppercase px-2 py-0.5 rounded-full",
      type === "entry" ? "bg-accent/15 text-accent" : "bg-destructive/15 text-destructive"
    )}>
      {type}
    </span>
  </motion.div>
);

export default EntryStamp;
