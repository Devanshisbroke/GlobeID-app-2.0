import React from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { ScanLine, FileText, Globe, PlusCircle, BrainCircuit, Compass } from "lucide-react";
import { cn } from "@/lib/utils";
import { springs } from "@/hooks/useMotion";

const actions = [
  { icon: PlusCircle, label: "Add Trip", route: "/travel" },
  { icon: ScanLine, label: "Scan ID", route: "/identity" },
  { icon: BrainCircuit, label: "Intel", route: "/intelligence" },
  { icon: Compass, label: "Explorer", route: "/explorer" },
  { icon: FileText, label: "Docs", route: "/wallet" },
  { icon: Globe, label: "Map", route: "/map" },
];

const container = { animate: { transition: { staggerChildren: 0.04 } } };
const item = { initial: { opacity: 0, y: 10, scale: 0.97 }, animate: { opacity: 1, y: 0, scale: 1 } };

const QuickActions: React.FC = () => {
  const navigate = useNavigate();

  return (
    <motion.div className="grid grid-cols-3 gap-2" variants={container} initial="initial" animate="animate">
      {actions.map((action) => {
        const Icon = action.icon;
        return (
          <motion.button
            key={action.label}
            variants={item}
            transition={springs.snappy}
            whileTap={{ scale: 0.92 }}
            onClick={() => navigate(action.route)}
            className={cn(
              "flex flex-col items-center gap-2 p-3 rounded-2xl min-h-[84px]",
              "glass border border-border/30",
              "hover:border-primary/20",
              "active:scale-95 transition-transform btn-ripple"
            )}
          >
            <div className="w-10 h-10 rounded-xl flex items-center justify-center bg-secondary/60">
              <Icon className="w-5 h-5 text-accent" strokeWidth={1.8} />
            </div>
            <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">{action.label}</span>
          </motion.button>
        );
      })}
    </motion.div>
  );
};

export default QuickActions;
