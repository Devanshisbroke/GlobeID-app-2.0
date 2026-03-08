import React from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { ScanLine, FileText, Globe, PlusCircle, BrainCircuit, Compass } from "lucide-react";
import { cn } from "@/lib/utils";
import { springs } from "@/hooks/useMotion";

const actions = [
  { icon: PlusCircle, label: "Add Trip", route: "/travel", gradient: "bg-gradient-ocean" },
  { icon: ScanLine, label: "Scan ID", route: "/identity", gradient: "bg-gradient-cosmic" },
  { icon: BrainCircuit, label: "Intel", route: "/intelligence", gradient: "bg-gradient-to-br from-accent to-primary" },
  { icon: Compass, label: "Explorer", route: "/explorer", gradient: "bg-gradient-aurora" },
  { icon: FileText, label: "Docs", route: "/wallet", gradient: "bg-gradient-sunset" },
  { icon: Globe, label: "Map", route: "/map", gradient: "bg-gradient-forest" },
];

const container = { animate: { transition: { staggerChildren: 0.04 } } };
const item = { initial: { opacity: 0, y: 10, scale: 0.97 }, animate: { opacity: 1, y: 0, scale: 1 } };

const QuickActions: React.FC = () => {
  const navigate = useNavigate();

  return (
    <motion.div className="grid grid-cols-5 gap-2" variants={container} initial="initial" animate="animate">
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
              "hover:border-primary/20 hover:shadow-glow-sm",
              "active:scale-95 transition-transform btn-ripple"
            )}
          >
            <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center shadow-depth-sm", action.gradient)}>
              <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
            </div>
            <span className="text-[10px] font-medium text-muted-foreground text-center leading-tight">{action.label}</span>
          </motion.button>
        );
      })}
    </motion.div>
  );
};

export default QuickActions;
