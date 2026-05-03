/**
 * Identity score factor explainer (BACKLOG E 58).
 *
 * Tap any factor on the IdentityScoreCard → opens a vaul-driven bottom
 * drawer with a description + concrete improvement tips. Static
 * metadata lives in `scoreFactorMeta.ts` to keep this file
 * components-only (HMR fast-refresh friendly).
 *
 * Vaul (Vercel) was chosen over Radix Dialog because the iOS-style
 * snap-points + drag-to-dismiss feel match the rest of the app's
 * Apple-Wallet-class motion language.
 */
import React from "react";
import { Drawer } from "vaul";
import { Lightbulb } from "lucide-react";
import type { ScoreFactorMeta } from "./scoreFactorMeta";

const ScoreFactorDrawer: React.FC<{
  factor: ScoreFactorMeta | null;
  onClose: () => void;
}> = ({ factor, onClose }) => (
  <Drawer.Root
    open={factor !== null}
    onOpenChange={(open) => {
      if (!open) onClose();
    }}
    shouldScaleBackground
  >
    <Drawer.Portal>
      <Drawer.Overlay className="fixed inset-0 z-[80] bg-black/40 backdrop-blur-sm" />
      <Drawer.Content
        className="fixed bottom-0 left-0 right-0 z-[81] mt-24 flex h-auto flex-col rounded-t-3xl border-t border-border bg-background pb-[env(safe-area-inset-bottom)] outline-none"
        aria-describedby={undefined}
      >
        <Drawer.Title className="sr-only">
          {factor?.label ?? "Score factor"}
        </Drawer.Title>
        <div className="mx-auto mt-2 mb-3 h-1.5 w-12 shrink-0 rounded-full bg-border" />
        {factor ? (
          <div className="px-5 pb-5">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-[hsl(var(--p7-brand))]/12 flex items-center justify-center">
                <factor.Icon className="w-5 h-5 text-[hsl(var(--p7-brand))]" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-foreground">
                  {factor.label}
                </h2>
                <p className="text-[11px] uppercase tracking-wider text-muted-foreground">
                  Identity score factor
                </p>
              </div>
            </div>
            <p className="text-sm text-foreground/85 leading-relaxed mb-4">
              {factor.description}
            </p>
            <h3 className="mb-2 inline-flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              <Lightbulb className="w-3 h-3" />
              How to improve
            </h3>
            <ul className="space-y-2">
              {factor.tips.map((tip, i) => (
                <li
                  key={i}
                  className="flex gap-2 rounded-xl border border-border/60 bg-surface-elevated px-3 py-2 text-[13px] text-foreground"
                >
                  <span
                    aria-hidden
                    className="font-mono text-[10px] text-muted-foreground tabular-nums mt-0.5"
                  >
                    {String(i + 1).padStart(2, "0")}
                  </span>
                  {tip}
                </li>
              ))}
            </ul>
          </div>
        ) : null}
      </Drawer.Content>
    </Drawer.Portal>
  </Drawer.Root>
);

export default ScoreFactorDrawer;
