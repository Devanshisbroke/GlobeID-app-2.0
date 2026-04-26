import * as React from "react";
import * as ToastPrimitive from "@radix-ui/react-toast";
import { motion, AnimatePresence } from "motion/react";
import { CheckCircle2, AlertCircle, Info, AlertTriangle, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { spring } from "@/lib/motion-tokens";

/**
 * Toast — top-anchored notification.
 *
 * Built on `@radix-ui/react-toast` for a11y (live region, swipe-dismiss
 * gesture, focus management, screen-reader announcements). Visual treatment
 * is the v2 elevated surface; tone-aware leading icon (success / info /
 * warning / critical). Spring entrance from the top so it reads as
 * "drops in from the status bar".
 *
 * Use `<Toast.Provider>` once at the app root; emit toasts from anywhere
 * via the `toast()` helper exported from `@/lib/toast` (PR-γ wires that
 * helper to the new Toast viewport).
 */

const Provider = ToastPrimitive.Provider;
const Viewport = React.forwardRef<
  React.ComponentRef<typeof ToastPrimitive.Viewport>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitive.Viewport>
>(({ className, ...rest }, ref) => (
  <ToastPrimitive.Viewport
    ref={ref}
    className={cn(
      "fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse gap-2 p-4",
      "sm:right-0 sm:top-0 sm:flex-col sm:max-w-[400px]",
      "outline-none",
      "pt-[max(env(safe-area-inset-top),16px)]",
      className,
    )}
    {...rest}
  />
));
Viewport.displayName = "Toast.Viewport";

type ToastTone = "neutral" | "success" | "warning" | "critical";

const toneIcon: Record<ToastTone, React.ReactNode> = {
  neutral: <Info className="h-4 w-4 text-brand" />,
  success: <CheckCircle2 className="h-4 w-4 text-state-accent" />,
  warning: <AlertTriangle className="h-4 w-4 text-[hsl(var(--p7-warning))]" />,
  critical: <AlertCircle className="h-4 w-4 text-critical" />,
};

type RootProps = React.ComponentPropsWithoutRef<typeof ToastPrimitive.Root> & {
  tone?: ToastTone;
  title?: React.ReactNode;
  description?: React.ReactNode;
  action?: React.ReactNode;
};

const Root = React.forwardRef<
  React.ComponentRef<typeof ToastPrimitive.Root>,
  RootProps
>(({ className, tone = "neutral", title, description, action, ...rest }, ref) => {
  return (
    <ToastPrimitive.Root asChild ref={ref} {...rest}>
      <AnimatePresence>
        <motion.div
          key="p7-toast"
          initial={{ opacity: 0, y: -20, scale: 0.96 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -10, scale: 0.98 }}
          transition={spring.default}
          className={cn(
            "relative flex w-full items-start gap-3",
            "rounded-p7-surface border border-surface-hairline",
            "bg-surface-elevated text-ink-primary shadow-p7-lg",
            "p-3 pr-9",
            className,
          )}
        >
          <span className="mt-0.5 shrink-0">{toneIcon[tone]}</span>
          <div className="flex min-w-0 flex-1 flex-col gap-0.5">
            {title ? (
              <ToastPrimitive.Title className="text-p7-body-em text-ink-primary">
                {title}
              </ToastPrimitive.Title>
            ) : null}
            {description ? (
              <ToastPrimitive.Description className="text-p7-callout text-ink-secondary">
                {description}
              </ToastPrimitive.Description>
            ) : null}
            {action ? <div className="mt-2">{action}</div> : null}
          </div>
          <ToastPrimitive.Close
            className={cn(
              "absolute top-2 right-2 inline-flex h-6 w-6 items-center justify-center rounded-p7-chip",
              "text-ink-tertiary hover:text-ink-primary hover:bg-surface-overlay",
              "outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
              "transition-colors duration-p7-tap",
            )}
            aria-label="Dismiss"
          >
            <X className="h-3.5 w-3.5" />
          </ToastPrimitive.Close>
        </motion.div>
      </AnimatePresence>
    </ToastPrimitive.Root>
  );
});
Root.displayName = "Toast";

const Action = ToastPrimitive.Action;

export const Toast = Object.assign(Root, {
  Provider,
  Viewport,
  Action,
});
