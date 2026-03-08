import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useLocation } from "react-router-dom";
import { cinematicEase, cinematicDuration } from "@/cinematic/motionEngine";

interface PageTransitionProps {
  children: React.ReactNode;
}

const variants = {
  initial: {
    opacity: 0,
    y: 18,
    scale: 0.97,
    filter: "blur(6px)",
  },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    filter: "blur(0px)",
  },
  exit: {
    opacity: 0,
    y: -10,
    scale: 1.01,
    filter: "blur(4px)",
  },
};

const PageTransition: React.FC<PageTransitionProps> = ({ children }) => {
  const location = useLocation();

  return (
    <AnimatePresence mode="wait" initial={false}>
      <motion.div
        key={location.pathname}
        variants={variants}
        initial="initial"
        animate="animate"
        exit="exit"
        transition={{
          duration: cinematicDuration.cinematic * 0.7,
          ease: cinematicEase,
          filter: { duration: cinematicDuration.medium, ease: cinematicEase },
        }}
        className="will-change-transform"
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
};

export { PageTransition };
