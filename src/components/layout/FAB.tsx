import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Scan, CreditCard, Plus, Plane, FileText, X } from "lucide-react";
import { haptics } from "@/utils/haptics";
import { spring } from "@/motion/motionConfig";

const actions = [
  { icon: CreditCard, label: "Quick Pay", path: "/wallet", color: "bg-gradient-ocean" },
  { icon: Scan, label: "Scan ID", path: "/identity", color: "bg-gradient-cosmic" },
  { icon: Plane, label: "Add Trip", path: "/travel", color: "bg-gradient-sunset" },
  { icon: FileText, label: "Add Doc", path: "/wallet", color: "bg-gradient-forest" },
];

const FAB: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);

  if (location.pathname === "/lock") return null;

  return (
    <>
      {/* Backdrop */}
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-40 bg-background/40 backdrop-blur-sm"
            onClick={() => setOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Action buttons */}
      <AnimatePresence>
        {open && (
          <div className="fixed z-50 right-4 bottom-[152px] flex flex-col-reverse gap-3 items-end">
            {actions.map((action, i) => {
              const Icon = action.icon;
              return (
                <motion.button
                  key={action.label}
                  initial={{ opacity: 0, scale: 0.3, y: 20 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.3, y: 20 }}
                  transition={{ ...spring.fab, delay: i * 0.05 }}
                  onClick={() => {
                    haptics.tap();
                    setOpen(false);
                    navigate(action.path);
                  }}
                  className="flex items-center gap-2.5"
                >
                  <span className="text-xs font-semibold text-foreground glass px-3 py-1.5 rounded-lg shadow-depth-sm whitespace-nowrap">
                    {action.label}
                  </span>
                  <span className={cn("w-11 h-11 rounded-full flex items-center justify-center shadow-depth-md", action.color)}>
                    <Icon className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
                  </span>
                </motion.button>
              );
            })}
          </div>
        )}
      </AnimatePresence>

      {/* Main FAB */}
      <motion.button
        aria-label={open ? "Close menu" : "Quick actions"}
        onClick={() => {
          haptics.medium();
          setOpen((v) => !v);
        }}
        animate={{ rotate: open ? 135 : 0 }}
        whileTap={{ scale: 0.94 }}
        transition={spring.fab}
        className={cn(
          "fixed z-50 right-4 bottom-[88px] w-14 h-14 rounded-full",
          "flex items-center justify-center",
          "bg-gradient-cosmic shadow-glow-lg",
          "will-change-transform"
        )}
      >
        <Plus className="w-6 h-6 text-primary-foreground" strokeWidth={2} />
      </motion.button>
    </>
  );
};

export { FAB };
