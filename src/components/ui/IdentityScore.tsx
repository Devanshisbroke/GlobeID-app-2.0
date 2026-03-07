import React, { useMemo } from "react";

interface IdentityScoreProps {
  score: number; // 0-100
  size?: number;
  strokeWidth?: number;
  className?: string;
}

const IdentityScore: React.FC<IdentityScoreProps> = ({
  score,
  size = 80,
  strokeWidth = 6,
  className,
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (score / 100) * circumference;
  const gradientId = useMemo(() => `score-grad-${Math.random().toString(36).slice(2, 8)}`, []);

  return (
    <div className={className} style={{ width: size, height: size }} role="meter" aria-valuenow={score} aria-valuemin={0} aria-valuemax={100} aria-label={`Identity score: ${score} out of 100`}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <defs>
          <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="hsl(225, 73%, 57%)" />
            <stop offset="50%" stopColor="hsl(185, 72%, 48%)" />
            <stop offset="100%" stopColor="hsl(168, 70%, 45%)" />
          </linearGradient>
        </defs>
        {/* Background track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="hsl(240, 6%, 15%)"
          strokeWidth={strokeWidth}
        />
        {/* Score arc */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={`url(#${gradientId})`}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={
            {
              "--score-offset": String(offset),
              transform: "rotate(-90deg)",
              transformOrigin: "50% 50%",
            } as React.CSSProperties
          }
          className="animate-score-fill"
        />
        {/* Center text */}
        <text
          x="50%"
          y="50%"
          textAnchor="middle"
          dominantBaseline="central"
          className="fill-foreground"
          style={{ fontSize: size * 0.28, fontWeight: 700 }}
        >
          {score}
        </text>
      </svg>
    </div>
  );
};

export { IdentityScore };
