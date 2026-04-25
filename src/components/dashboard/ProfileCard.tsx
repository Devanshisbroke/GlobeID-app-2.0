import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { useUserStore, selectVisitedCountries, selectCurrentLocation } from "@/store/userStore";
import { calculateTravelScore } from "@/lib/travelSuggestions";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { ShieldCheck, User, Trophy, Sparkles, MapPin } from "lucide-react";
import { cn } from "@/lib/utils";
import { motion } from "framer-motion";
import { springs } from "@/hooks/useMotion";

const ProfileCard: React.FC = () => {
  const navigate = useNavigate();
  const { profile, travelHistory } = useUserStore();
  const visitedCount = React.useMemo(
    () => selectVisitedCountries(travelHistory).length,
    [travelHistory]
  );
  const location = React.useMemo(
    () =>
      selectCurrentLocation(travelHistory, {
        country: profile.nationality,
      }),
    [travelHistory, profile.nationality]
  );
  const travelScore = calculateTravelScore(visitedCount, 45000, 3);

  return (
    <GlassCard className="relative overflow-hidden p-5" variant="premium" glow depth="lg" onClick={() => navigate("/profile")}>
      <div className="absolute inset-0 overflow-hidden rounded-2xl pointer-events-none">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/[0.03] to-transparent animate-shimmer" />
      </div>
      <div className="relative">
        {/* Greeting */}
        <div className="flex items-center gap-2 mb-2">
          <Sparkles className="w-3.5 h-3.5 text-neon-amber" strokeWidth={1.8} />
          <p className="text-xs text-muted-foreground font-medium">
            {new Date().getHours() < 12 ? "Good morning" : new Date().getHours() < 18 ? "Good afternoon" : "Good evening"},
          </p>
        </div>
        <h2 className="text-2xl font-bold text-foreground mb-1 tracking-tight">{profile.name}</h2>

        {/* Identity row */}
        <div className="flex items-center gap-4 mt-3">
          <motion.div
            className="w-14 h-14 rounded-2xl bg-gradient-cosmic flex items-center justify-center shrink-0 shadow-glow-sm cursor-pointer"
            whileTap={{ scale: 0.9 }}
            transition={springs.bounce}
          >
            {profile.avatarUrl ? (
              <img src={profile.avatarUrl} alt={profile.name} className="w-full h-full rounded-2xl object-cover" />
            ) : (
              <User className="w-6 h-6 text-primary-foreground" />
            )}
          </motion.div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-1.5 mb-1">
              <span className="text-[10px] px-2 py-0.5 rounded-full bg-primary/15 text-primary font-semibold tracking-wide capitalize">
                {profile.verifiedStatus}
              </span>
              {profile.verifiedStatus === "verified" && (
                <ShieldCheck className="w-3.5 h-3.5 text-accent" />
              )}
            </div>
            <p className="text-xs text-muted-foreground">
              {profile.nationalityFlag} {profile.nationality} · Passport Linked
            </p>
          </div>
          <IdentityScore score={profile.identityScore} size={64} strokeWidth={5} />
        </div>

        {/* Travel Score + Location */}
        <div className="mt-4 grid grid-cols-2 gap-2">
          <div className="flex items-center gap-2.5 px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/30">
            <Trophy className="w-4 h-4 text-neon-amber" />
            <div>
              <p className="text-[10px] text-muted-foreground">Travel Score</p>
              <p className="text-sm font-bold text-foreground">{travelScore.score}<span className="text-[10px] text-muted-foreground font-normal"> / 100</span></p>
            </div>
          </div>
          <div className="flex items-center gap-2.5 px-3 py-2.5 rounded-xl bg-secondary/40 border border-border/30">
            <MapPin className="w-4 h-4 text-accent" />
            <div>
              <p className="text-[10px] text-muted-foreground">Currently in</p>
              <p className="text-sm font-bold text-foreground">{location.countryFlag} {location.country}</p>
            </div>
          </div>
        </div>
      </div>
    </GlassCard>
  );
};

export default ProfileCard;
