import React from "react";
import { motion } from "framer-motion";

interface Props {
  score: number;
  size?: number;
}

const PopularityIndicator: React.FC<Props> = ({ score, size = 40 }) => {
  const r = (size - 6) / 2;
  const circ = 2 * Math.PI * r;
  const offset = circ * (1 - score / 100);

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="hsl(var(--secondary))" strokeWidth={3} />
        <motion.circle
          cx={size / 2} cy={size / 2} r={r}
          fill="none" stroke="hsl(var(--accent))" strokeWidth={3} strokeLinecap="round"
          strokeDasharray={circ}
          initial={{ strokeDashoffset: circ }}
          animate={{ strokeDashoffset: offset }}
          transition={{ duration: 1, ease: [0.22, 1, 0.36, 1] }}
        />
      </svg>
      <span className="absolute inset-0 flex items-center justify-center text-[9px] font-bold text-foreground tabular-nums">
        {score}
      </span>
    </div>
  );
};

export default PopularityIndicator;
