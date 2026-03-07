import React, { useState, useEffect } from "react";

interface SplashScreenProps {
  onComplete: () => void;
}

const SplashScreen: React.FC<SplashScreenProps> = ({ onComplete }) => {
  const [phase, setPhase] = useState<"logo" | "sweep" | "exit">("logo");

  useEffect(() => {
    const t1 = setTimeout(() => setPhase("sweep"), 1200);
    const t2 = setTimeout(() => setPhase("exit"), 2200);
    const t3 = setTimeout(() => onComplete(), 2800);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, [onComplete]);

  return (
    <div
      className="fixed inset-0 z-[100] flex flex-col items-center justify-center"
      style={{
        background: "linear-gradient(135deg, hsl(228 20% 6%) 0%, hsl(228 18% 10%) 50%, hsl(228 20% 6%) 100%)",
        opacity: phase === "exit" ? 0 : 1,
        transition: "opacity 600ms ease-out",
      }}
    >
      {/* Gradient mesh background */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div
          className="absolute w-[400px] h-[400px] rounded-full blur-[120px] opacity-30"
          style={{
            background: "radial-gradient(circle, hsl(220 85% 62%) 0%, transparent 70%)",
            top: "20%",
            left: "10%",
            animation: "orb-drift 8s ease-in-out infinite",
          }}
        />
        <div
          className="absolute w-[350px] h-[350px] rounded-full blur-[100px] opacity-20"
          style={{
            background: "radial-gradient(circle, hsl(258 65% 65%) 0%, transparent 70%)",
            bottom: "10%",
            right: "5%",
            animation: "orb-drift 8s ease-in-out infinite reverse",
          }}
        />
        <div
          className="absolute w-[250px] h-[250px] rounded-full blur-[80px] opacity-15"
          style={{
            background: "radial-gradient(circle, hsl(168 70% 48%) 0%, transparent 70%)",
            top: "50%",
            right: "30%",
            animation: "orb-drift 10s ease-in-out infinite",
            animationDelay: "2s",
          }}
        />
      </div>

      {/* Globe SVG */}
      <div className="relative mb-8" style={{ perspective: "600px" }}>
        <svg
          viewBox="0 0 120 120"
          className="w-28 h-28"
          style={{
            filter: "drop-shadow(0 0 30px hsl(220 85% 62% / 0.4))",
          }}
        >
          {/* Outer ring */}
          <circle
            cx="60" cy="60" r="50"
            fill="none"
            stroke="url(#globe-gradient)"
            strokeWidth="2"
            strokeDasharray="314"
            strokeDashoffset={phase === "logo" ? "0" : "0"}
            style={{
              animation: "globe-spin 3s linear infinite",
              transformOrigin: "60px 60px",
            }}
          />
          {/* Latitude lines */}
          <ellipse cx="60" cy="60" rx="50" ry="20" fill="none" stroke="hsl(200 90% 60% / 0.3)" strokeWidth="1" />
          <ellipse cx="60" cy="60" rx="50" ry="35" fill="none" stroke="hsl(200 90% 60% / 0.2)" strokeWidth="1" />
          {/* Meridian */}
          <ellipse cx="60" cy="60" rx="20" ry="50" fill="none" stroke="hsl(258 65% 65% / 0.3)" strokeWidth="1" />
          {/* Connection dots */}
          {[
            { cx: 35, cy: 35 }, { cx: 85, cy: 40 }, { cx: 50, cy: 80 },
            { cx: 75, cy: 70 }, { cx: 40, cy: 55 }, { cx: 80, cy: 55 },
          ].map((dot, i) => (
            <circle
              key={i}
              cx={dot.cx}
              cy={dot.cy}
              r="2.5"
              fill={`hsl(${[220, 168, 258, 25, 200, 310][i]} ${[85, 70, 65, 95, 90, 70][i]}% ${[62, 48, 65, 58, 60, 58][i]}%)`}
              style={{
                opacity: phase !== "logo" ? 1 : 0,
                animation: `pulse-ring 2s ease-in-out ${i * 0.2}s infinite`,
                transition: "opacity 400ms ease",
              }}
            />
          ))}
          {/* Connection lines */}
          <line x1="35" y1="35" x2="85" y2="40" stroke="hsl(220 85% 62% / 0.2)" strokeWidth="0.5" strokeDasharray="4 4" />
          <line x1="85" y1="40" x2="75" y2="70" stroke="hsl(168 70% 48% / 0.2)" strokeWidth="0.5" strokeDasharray="4 4" />
          <line x1="40" y1="55" x2="80" y2="55" stroke="hsl(258 65% 65% / 0.2)" strokeWidth="0.5" strokeDasharray="4 4" />
          <defs>
            <linearGradient id="globe-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="hsl(220 85% 62%)" />
              <stop offset="50%" stopColor="hsl(200 90% 60%)" />
              <stop offset="100%" stopColor="hsl(168 70% 48%)" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      {/* Logo text */}
      <div
        className="text-center"
        style={{
          opacity: phase === "logo" ? 0 : 1,
          transform: phase === "logo" ? "translateY(10px)" : "translateY(0)",
          transition: "all 500ms cubic-bezier(0.16, 1, 0.3, 1)",
        }}
      >
        <h1
          className="text-3xl font-bold tracking-tight"
          style={{
            background: "linear-gradient(135deg, hsl(220 85% 70%), hsl(200 90% 65%), hsl(168 70% 55%))",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          GlobeID
        </h1>
        <p className="text-sm text-muted-foreground mt-1 tracking-widest uppercase">
          Travel · Identity · Payments
        </p>
      </div>

      {/* Light sweep across bottom */}
      {phase === "sweep" && (
        <div
          className="absolute bottom-0 left-0 right-0 h-1"
          style={{
            background: "linear-gradient(90deg, transparent, hsl(220 85% 62%), hsl(168 70% 48%), transparent)",
            animation: "shimmer 1.5s linear forwards",
          }}
        />
      )}
    </div>
  );
};

export default SplashScreen;
