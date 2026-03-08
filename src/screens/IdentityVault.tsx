import React from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import PassportBook from "@/components/identity/PassportBook";
import BorderEntrySimulation from "@/components/identity/BorderEntrySimulation";
import PassportScanner from "@/components/identity/PassportScanner";
import VerificationFlow from "@/components/identity/VerificationFlow";
import { AnimatedPage } from "@/components/layout/AnimatedPage";

const IdentityVault: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="px-4 py-6 space-y-6 pb-24">
      <AnimatedPage>
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(-1)} className="w-9 h-9 rounded-xl glass flex items-center justify-center active:scale-90 transition-transform">
            <ArrowLeft className="w-4.5 h-4.5 text-foreground" />
          </button>
          <h1 className="text-lg font-bold text-foreground">Passport Book & Tools</h1>
        </div>
      </AnimatedPage>

      <AnimatedPage staggerIndex={0}>
        <PassportBook />
      </AnimatedPage>

      <AnimatedPage staggerIndex={1}>
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1">Passport Scanner</p>
        <PassportScanner />
      </AnimatedPage>

      <AnimatedPage staggerIndex={2}>
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest px-1 mb-3">Verification Flow</p>
        <VerificationFlow />
      </AnimatedPage>

      <AnimatedPage staggerIndex={3}>
        <BorderEntrySimulation />
      </AnimatedPage>
    </div>
  );
};

export default IdentityVault;
