import React from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ScanLine, FileText, Globe, PlusCircle, BrainCircuit, Compass } from "lucide-react";
import { Surface, Text, spring } from "@/components/ui/v2";

const actions = [
  { icon: PlusCircle, label: "Add Trip", route: "/travel" },
  { icon: ScanLine, label: "Scan ID", route: "/identity" },
  { icon: BrainCircuit, label: "Intel", route: "/intelligence" },
  { icon: Compass, label: "Explorer", route: "/explorer" },
  { icon: FileText, label: "Docs", route: "/wallet" },
  { icon: Globe, label: "Map", route: "/map" },
];

const container = { animate: { transition: { staggerChildren: 0.04 } } };
const item = {
  initial: { opacity: 0, y: 8, scale: 0.97 },
  animate: { opacity: 1, y: 0, scale: 1 },
};

const QuickActions: React.FC = () => {
  const navigate = useNavigate();

  return (
    <motion.div
      className="grid grid-cols-3 gap-2"
      variants={container}
      initial="initial"
      animate="animate"
    >
      {actions.map((action) => {
        const Icon = action.icon;
        return (
          <motion.div
            key={action.label}
            variants={item}
            transition={spring.snap}
            whileTap={{ scale: 0.95 }}
          >
            <Surface
              variant="plain"
              radius="surface"
              asChild
              className="flex flex-col items-center justify-center gap-2 p-3 min-h-[84px] w-full cursor-pointer transition-colors hover:border-brand/40"
            >
              <button type="button" onClick={() => navigate(action.route)}>
                <span className="w-10 h-10 rounded-p7-input flex items-center justify-center bg-state-accent-soft">
                  <Icon className="w-5 h-5 text-state-accent" strokeWidth={1.8} />
                </span>
                <Text variant="caption-2" tone="secondary" className="text-center leading-tight">
                  {action.label}
                </Text>
              </button>
            </Surface>
          </motion.div>
        );
      })}
    </motion.div>
  );
};

export default QuickActions;
