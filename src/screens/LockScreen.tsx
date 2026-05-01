import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { demoUser } from "@/lib/demoData";
import { Fingerprint, ScanLine, Lock } from "lucide-react";
import { toast } from "sonner";
import {
  isBiometricAvailable,
  requestBiometricAuth,
} from "@/lib/biometricAuth";
import { haptics } from "@/utils/haptics";

const LockScreen: React.FC = () => {
  const navigate = useNavigate();
  const [showBiometric, setShowBiometric] = useState(false);
  const [unlocking, setUnlocking] = useState(false);
  const [biometricSupported, setBiometricSupported] = useState<boolean | null>(null);
  const [showPin, setShowPin] = useState(false);
  const [pin, setPin] = useState("");

  useEffect(() => {
    let cancelled = false;
    void isBiometricAvailable().then((ok) => {
      if (!cancelled) setBiometricSupported(ok);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  const handleBiometric = async () => {
    setShowBiometric(true);
    setUnlocking(true);
    haptics.selection();
    const result = await requestBiometricAuth(
      "Unlock GlobeID",
      "Use your fingerprint or face",
    );
    if (result.ok) {
      haptics.success();
      navigate("/", { replace: true });
      return;
    }
    setUnlocking(false);
    setShowBiometric(false);
    if (result.code === "cancelled") return;
    if (result.code === "unsupported") {
      toast.error("Biometric auth unavailable on this device");
      setShowPin(true);
      return;
    }
    if (result.code === "unenrolled") {
      toast.error("No biometrics enrolled — using PIN");
      setShowPin(true);
      return;
    }
    if (result.code === "lockout") {
      toast.error("Biometrics locked. Try again later.");
      setShowPin(true);
      return;
    }
    toast.error("Authentication failed");
  };

  const handlePinEntry = (digit: string) => {
    const newPin = pin + digit;
    setPin(newPin);
    if (newPin.length >= 4) {
      setTimeout(() => navigate("/", { replace: true }), 400);
    }
  };

  return (
    <div className="fixed inset-0 bg-background flex flex-col items-center justify-center overflow-hidden">
      {/* Animated gradient orbs */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div
          className="absolute w-[300px] h-[300px] rounded-full opacity-20 blur-[100px] animate-orb-drift"
          style={{
            background: "radial-gradient(circle, hsl(225,73%,57%) 0%, transparent 70%)",
            top: "10%",
            left: "20%",
          }}
        />
        <div
          className="absolute w-[250px] h-[250px] rounded-full opacity-15 blur-[80px] animate-orb-drift"
          style={{
            background: "radial-gradient(circle, hsl(185,72%,48%) 0%, transparent 70%)",
            bottom: "20%",
            right: "10%",
            animationDelay: "4s",
          }}
        />
        <div
          className="absolute w-[200px] h-[200px] rounded-full opacity-10 blur-[60px] animate-orb-drift"
          style={{
            background: "radial-gradient(circle, hsl(168,70%,45%) 0%, transparent 70%)",
            top: "50%",
            left: "60%",
            animationDelay: "8s",
          }}
        />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center gap-6 px-8 animate-fade-in">
        {/* Avatar */}
        <div className="relative">
          <div className="w-24 h-24 rounded-full overflow-hidden ring-2 ring-border shadow-[0_0_30px_hsl(var(--neon-indigo)/0.3)]">
            <img
              src={demoUser.avatar}
              alt="User avatar"
              className="w-full h-full object-cover"
              style={{ filter: "blur(2px) brightness(0.8)" }}
            />
          </div>
          <div className="absolute -bottom-1 -right-1 w-8 h-8 rounded-full bg-accent flex items-center justify-center">
            <Lock className="w-4 h-4 text-accent-foreground" />
          </div>
        </div>

        {/* Masked name */}
        <div className="text-center">
          <p className="text-lg font-semibold text-foreground">{demoUser.maskedName}</p>
          <p className="text-xs text-muted-foreground mt-1">GlobeID Protected</p>
        </div>

        {/* Scan Passport CTA */}
        <button
          onClick={() => navigate("/scan")}
          className={cn(
            "relative mt-4 px-8 py-4 rounded-2xl font-semibold text-primary-foreground",
            "bg-gradient-to-r from-primary via-primary to-accent",
            "shadow-[0_0_30px_hsl(var(--neon-cyan)/0.4)]",
            "transition-all duration-300 ease-out",
            "active:scale-95 hover:shadow-[0_0_40px_hsl(var(--neon-cyan)/0.6)]",
            "flex items-center gap-3 min-h-[52px]"
          )}
        >
          <ScanLine className="w-5 h-5" />
          Scan Passport
        </button>

        {/* Biometric */}
        <button
          onClick={handleBiometric}
          className="mt-2 flex flex-col items-center gap-2 text-muted-foreground hover:text-foreground transition-colors active:scale-95 min-h-[44px] justify-center"
        >
          <Fingerprint className={cn("w-10 h-10", unlocking && "text-accent animate-glow-pulse")} />
          <span className="text-xs">
            {unlocking
              ? "Verifying…"
              : biometricSupported === false
                ? "Biometrics unavailable"
                : "Use Biometrics"}
          </span>
        </button>

        {/* PIN fallback */}
        {!showPin && !showBiometric && (
          <button
            onClick={() => setShowPin(true)}
            className="text-xs text-muted-foreground underline underline-offset-2 mt-2"
          >
            Use PIN instead
          </button>
        )}

        {showPin && (
          <div className="mt-2 animate-scale-in">
            <div className="flex gap-3 mb-4 justify-center">
              {[0, 1, 2, 3].map((i) => (
                <div
                  key={i}
                  className={cn(
                    "w-3 h-3 rounded-full border border-border transition-colors duration-300",
                    i < pin.length ? "bg-accent" : "bg-transparent"
                  )}
                />
              ))}
            </div>
            <div className="grid grid-cols-3 gap-3">
              {["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "←"].map(
                (d) =>
                  d !== "" ? (
                    <button
                      key={d}
                      onClick={() =>
                        d === "←"
                          ? setPin((p) => p.slice(0, -1))
                          : handlePinEntry(d)
                      }
                      className="w-14 h-14 rounded-full glass flex items-center justify-center text-lg font-medium text-foreground active:scale-90 transition-transform"
                    >
                      {d}
                    </button>
                  ) : (
                    <div key="empty" />
                  )
              )}
            </div>
          </div>
        )}
      </div>

      {/* Biometric overlay */}
      {showBiometric && (
        <div className="absolute inset-0 z-20 flex items-center justify-center bg-background/90 backdrop-blur-md animate-fade-in">
          <div className="flex flex-col items-center gap-4 animate-scale-in">
            <Fingerprint className="w-20 h-20 text-accent animate-glow-pulse" />
            <p className="text-foreground font-medium">
              {unlocking ? "Identity Confirmed" : "Touch to Verify"}
            </p>
            {unlocking && (
              <div className="flex items-center gap-2 text-accent text-sm animate-fade-in">
                <span>✓</span>
                <span>Welcome back, {demoUser.name.split(" ")[0]}</span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default LockScreen;
