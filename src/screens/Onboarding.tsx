/**
 * Slice-G – First-run onboarding.
 *
 * Three steps:
 *   1. Welcome — brand intro, single CTA.
 *   2. Permissions — camera / microphone / notifications / geolocation.
 *      Each toggle triggers a real platform prompt via `usePermissions`.
 *   3. Profile — name + email seed. Writes to `userStore.setUser`.
 *
 * Completion is recorded in localStorage (`globeid:onboarded = "1"`).
 * The screen is skippable — `Skip` at any point marks onboarding done
 * and navigates to `/`. Idempotent: hitting the route again after
 * completion just redirects to home.
 */
import React, { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowRight,
  Camera,
  Mic,
  Bell,
  MapPin,
  Check,
  Sparkles,
  ChevronLeft,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { usePermissions, type PermissionKind } from "@/hooks/usePermissions";
import { useUserStore } from "@/store/userStore";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";
import { markOnboardingComplete, hasCompletedOnboarding } from "@/lib/onboarding";

const PERM_META: Record<
  PermissionKind,
  { label: string; desc: string; icon: React.ComponentType<{ className?: string }> }
> = {
  camera: {
    label: "Camera",
    desc: "Scan passports, boarding passes, and QR codes in-app.",
    icon: Camera,
  },
  microphone: {
    label: "Microphone",
    desc: "Voice commands — \"show balance\", \"open scanner\", etc.",
    icon: Mic,
  },
  notifications: {
    label: "Notifications",
    desc: "Boarding alerts, delay alerts, and context nudges.",
    icon: Bell,
  },
  geolocation: {
    label: "Location",
    desc: "Airport suggestions, arrival auto-detection, local services.",
    icon: MapPin,
  },
};

const Onboarding: React.FC = () => {
  const navigate = useNavigate();
  const [step, setStep] = useState<0 | 1 | 2>(0);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const { permissions, request } = usePermissions();
  const setUser = useUserStore((s) => s.setUser);

  useEffect(() => {
    if (hasCompletedOnboarding()) {
      navigate("/", { replace: true });
    }
  }, [navigate]);

  const finish = useCallback(() => {
    if (name.trim() || email.trim()) {
      setUser({
        ...(name.trim() ? { name: name.trim() } : {}),
        ...(email.trim() ? { email: email.trim() } : {}),
      });
    }
    markOnboardingComplete();
    haptics.success();
    navigate("/", { replace: true });
  }, [name, email, setUser, navigate]);

  const next = () => {
    haptics.light();
    setStep((s) => (s === 2 ? s : ((s + 1) as 0 | 1 | 2)));
  };

  const back = () => {
    haptics.selection();
    setStep((s) => (s === 0 ? s : ((s - 1) as 0 | 1 | 2)));
  };

  const skip = () => {
    markOnboardingComplete();
    navigate("/", { replace: true });
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-background">
      <div className="flex items-center justify-between px-5 pt-[env(safe-area-inset-top)] pb-3 pt-3">
        <button
          type="button"
          aria-label="Back"
          onClick={back}
          disabled={step === 0}
          className={cn(
            "flex h-9 w-9 items-center justify-center rounded-full bg-muted text-muted-foreground",
            step === 0 && "opacity-0 pointer-events-none",
          )}
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <StepDots step={step} />
        <button
          type="button"
          onClick={skip}
          className="text-xs uppercase tracking-widest text-muted-foreground hover:text-foreground"
        >
          Skip
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-6 pb-8">
        <AnimatePresence mode="wait">
          {step === 0 && (
            <Step key="welcome">
              <WelcomeStep onContinue={next} />
            </Step>
          )}
          {step === 1 && (
            <Step key="permissions">
              <PermissionsStep permissions={permissions} request={request} onContinue={next} />
            </Step>
          )}
          {step === 2 && (
            <Step key="profile">
              <ProfileStep
                name={name}
                email={email}
                setName={setName}
                setEmail={setEmail}
                onFinish={finish}
              />
            </Step>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
};

const Step: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <motion.div
    initial={{ opacity: 0, y: 16, filter: "blur(6px)" }}
    animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
    exit={{ opacity: 0, y: -16, filter: "blur(4px)" }}
    transition={{ duration: 0.34, ease: [0.22, 1, 0.36, 1] }}
    className="h-full"
  >
    {children}
  </motion.div>
);

const StepDots: React.FC<{ step: number }> = ({ step }) => (
  <div className="flex items-center gap-1.5">
    {[0, 1, 2].map((i) => (
      <span
        key={i}
        className={cn(
          "h-1.5 rounded-full transition-all duration-300",
          step === i ? "w-6 bg-foreground" : "w-1.5 bg-muted-foreground/40",
        )}
      />
    ))}
  </div>
);

const WelcomeStep: React.FC<{ onContinue: () => void }> = ({ onContinue }) => (
  <div className="flex h-full flex-col items-center justify-center text-center">
    <div className="mb-6 flex h-20 w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-indigo-500 via-sky-500 to-emerald-500 shadow-[0_18px_40px_-18px_rgba(79,70,229,0.55)]">
      <Sparkles className="h-10 w-10 text-white" strokeWidth={1.5} />
    </div>
    <h1 className="text-3xl font-semibold leading-tight text-foreground">
      Welcome to GlobeID
    </h1>
    <p className="mt-3 max-w-sm text-sm leading-relaxed text-muted-foreground">
      Your passport, wallet, trips, and travel assistant — in one place.
      Let's set you up in two quick steps.
    </p>
    <Button className="mt-10 h-12 w-full max-w-sm" onClick={onContinue}>
      Get started
      <ArrowRight className="ml-2 h-4 w-4" />
    </Button>
  </div>
);

interface PermissionsStepProps {
  permissions: Record<PermissionKind, string>;
  request: (kind: PermissionKind) => Promise<string>;
  onContinue: () => void;
}

const PermissionsStep: React.FC<PermissionsStepProps> = ({
  permissions,
  request,
  onContinue,
}) => {
  const [busy, setBusy] = useState<PermissionKind | null>(null);

  const handleRequest = async (kind: PermissionKind) => {
    setBusy(kind);
    try {
      await request(kind);
    } finally {
      setBusy(null);
    }
  };

  const kinds: PermissionKind[] = ["camera", "microphone", "notifications", "geolocation"];

  return (
    <div className="flex h-full flex-col">
      <h2 className="mt-4 text-2xl font-semibold text-foreground">
        Enable device access
      </h2>
      <p className="mt-2 text-sm text-muted-foreground">
        Each one opens the native permission prompt. You can change these
        later in Settings.
      </p>

      <div className="mt-6 space-y-3">
        {kinds.map((kind) => {
          const meta = PERM_META[kind];
          const state = permissions[kind];
          const Icon = meta.icon;
          const granted = state === "granted";
          return (
            <button
              key={kind}
              type="button"
              disabled={busy === kind}
              onClick={() => handleRequest(kind)}
              className={cn(
                "flex w-full items-center gap-3 rounded-2xl border p-3.5 text-left transition",
                granted
                  ? "border-emerald-400/40 bg-emerald-400/10"
                  : "border-border/60 bg-muted/40 hover:border-border",
              )}
            >
              <div
                className={cn(
                  "flex h-11 w-11 shrink-0 items-center justify-center rounded-xl",
                  granted ? "bg-emerald-500/20" : "bg-muted",
                )}
              >
                <Icon
                  className={cn(
                    "h-5 w-5",
                    granted ? "text-emerald-600 dark:text-emerald-400" : "text-foreground",
                  )}
                />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground">
                  {meta.label}
                </p>
                <p className="mt-0.5 text-[11px] leading-tight text-muted-foreground">
                  {meta.desc}
                </p>
              </div>
              {granted ? (
                <Check className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
              ) : (
                <span className="text-[10px] uppercase tracking-widest text-muted-foreground">
                  {busy === kind ? "..." : state === "denied" ? "Denied" : "Allow"}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <Button className="mt-8 h-12 w-full" onClick={onContinue}>
        Continue
        <ArrowRight className="ml-2 h-4 w-4" />
      </Button>
    </div>
  );
};

interface ProfileStepProps {
  name: string;
  email: string;
  setName: (s: string) => void;
  setEmail: (s: string) => void;
  onFinish: () => void;
}

const ProfileStep: React.FC<ProfileStepProps> = ({
  name,
  email,
  setName,
  setEmail,
  onFinish,
}) => (
  <div className="flex h-full flex-col">
    <h2 className="mt-4 text-2xl font-semibold text-foreground">
      Who are you?
    </h2>
    <p className="mt-2 text-sm text-muted-foreground">
      We&apos;ll use this to personalize boarding passes and receipts. Both
      fields are optional.
    </p>

    <div className="mt-6 space-y-3">
      <LabeledInput label="Name" value={name} onChange={setName} placeholder="Ada Lovelace" />
      <LabeledInput
        label="Email"
        value={email}
        onChange={setEmail}
        placeholder="ada@example.com"
        type="email"
      />
    </div>

    <Button className="mt-8 h-12 w-full" onClick={onFinish}>
      Finish
      <Check className="ml-2 h-4 w-4" />
    </Button>
  </div>
);

const LabeledInput: React.FC<{
  label: string;
  value: string;
  onChange: (s: string) => void;
  placeholder?: string;
  type?: string;
}> = ({ label, value, onChange, placeholder, type = "text" }) => (
  <label className="block">
    <span className="mb-1 block text-[11px] uppercase tracking-widest text-muted-foreground">
      {label}
    </span>
    <Input
      type={type}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      className="h-11"
    />
  </label>
);

export default Onboarding;
