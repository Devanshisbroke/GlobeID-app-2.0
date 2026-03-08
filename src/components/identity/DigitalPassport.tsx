import React from "react";
import { motion } from "framer-motion";
import { Shield, ShieldCheck, Fingerprint } from "lucide-react";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

const DigitalPassport: React.FC<{ className?: string; onFlip?: () => void }> = ({ className, onFlip }) => {
  const { profile } = useUserStore();
  const [flipped, setFlipped] = React.useState(false);

  const handleFlip = () => {
    setFlipped(!flipped);
    onFlip?.();
  };

  return (
    <motion.div
      className={cn("relative w-full perspective-1000", className)}
      style={{ perspective: 1000 }}
      initial={{ opacity: 0, y: 20, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ duration: 0.6, ease: cinematicEase }}
    >
      <motion.div
        className="relative w-full cursor-pointer"
        style={{ transformStyle: "preserve-3d" }}
        animate={{ rotateY: flipped ? 180 : 0 }}
        transition={{ duration: 0.7, ease: cinematicEase }}
        onClick={handleFlip}
      >
        {/* Front */}
        <div
          className="relative w-full rounded-2xl overflow-hidden border border-border/20"
          style={{ backfaceVisibility: "hidden" }}
        >
          {/* Holographic background */}
          <div className="absolute inset-0 bg-gradient-to-br from-[hsl(var(--ocean-deep))] via-[hsl(var(--primary))] to-[hsl(var(--ocean-turquoise))]" />
          <div className="absolute inset-0 opacity-20 bg-[repeating-linear-gradient(45deg,transparent,transparent_8px,rgba(255,255,255,0.05)_8px,rgba(255,255,255,0.05)_16px)]" />

          {/* Animated holographic sweep */}
          <motion.div
            className="absolute inset-0 opacity-30"
            style={{
              background: "linear-gradient(105deg, transparent 30%, rgba(255,255,255,0.4) 45%, transparent 60%)",
            }}
            animate={{ x: ["-100%", "200%"] }}
            transition={{ duration: 3, repeat: Infinity, repeatDelay: 2, ease: "easeInOut" }}
          />

          {/* Glow edge */}
          <div className="absolute inset-0 rounded-2xl ring-1 ring-inset ring-white/10" />
          <div className="absolute -inset-px rounded-2xl" style={{ boxShadow: "0 0 20px hsl(var(--primary) / 0.3), inset 0 1px 0 rgba(255,255,255,0.15)" }} />

          <div className="relative p-5 pb-4 text-primary-foreground">
            {/* Header */}
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Shield className="w-5 h-5" />
                <span className="text-[10px] font-bold tracking-[0.2em] uppercase opacity-80">GlobeID Digital Passport</span>
              </div>
              <span className="text-lg">{profile.nationalityFlag}</span>
            </div>

            {/* Photo placeholder + info */}
            <div className="flex gap-4">
              <div className="w-20 h-24 rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 flex items-center justify-center shrink-0">
                <ShieldCheck className="w-8 h-8 opacity-60" />
              </div>
              <div className="flex-1 space-y-2 text-xs">
                <div>
                  <span className="text-[9px] uppercase tracking-wider opacity-60">Full Name</span>
                  <p className="font-bold text-sm">{profile.name}</p>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <span className="text-[9px] uppercase tracking-wider opacity-60">Nationality</span>
                    <p className="font-medium">{profile.nationality}</p>
                  </div>
                  <div>
                    <span className="text-[9px] uppercase tracking-wider opacity-60">Passport No.</span>
                    <p className="font-mono font-medium">{profile.passportNumber}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="mt-4 pt-3 border-t border-white/10 flex items-center justify-between">
              <div className="flex items-center gap-1.5 text-[10px] opacity-70">
                <Fingerprint className="w-3.5 h-3.5" />
                Biometric Verified
              </div>
              <span className="text-[10px] px-2 py-0.5 rounded-full bg-white/15 font-semibold uppercase tracking-wider">
                {profile.verifiedStatus}
              </span>
            </div>
          </div>
        </div>

        {/* Back */}
        <div
          className="absolute inset-0 w-full rounded-2xl overflow-hidden border border-border/20 bg-gradient-to-br from-[hsl(var(--ocean-deep))] via-[hsl(220,60%,25%)]/90 to-[hsl(var(--ocean-turquoise))]"
          style={{ backfaceVisibility: "hidden", transform: "rotateY(180deg)" }}
        >
          <div className="absolute inset-0 opacity-10 bg-[repeating-linear-gradient(-45deg,transparent,transparent_6px,rgba(255,255,255,0.03)_6px,rgba(255,255,255,0.03)_12px)]" />
          <div className="relative p-5 text-primary-foreground space-y-3">
            <p className="text-[10px] font-bold tracking-[0.2em] uppercase opacity-70">Machine Readable Zone</p>
            <div className="font-mono text-[11px] leading-relaxed opacity-80 bg-black/20 rounded-lg p-3 space-y-1">
              <p>P&lt;IND{profile.name.toUpperCase().replace(/\s/g, "&lt;")}&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;</p>
              <p>{profile.passportNumber.replace(/•/g, "*")}IND0000000M0000000&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;00</p>
            </div>
            <div className="flex items-center gap-2 text-[10px] opacity-60">
              <Shield className="w-3.5 h-3.5" />
              <span>Tap to flip · Member since {profile.memberSince}</span>
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
};

export default DigitalPassport;
