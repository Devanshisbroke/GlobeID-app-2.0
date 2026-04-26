import * as React from "react";
import * as DialogPrimitive from "@radix-ui/react-dialog";
import { motion, AnimatePresence } from "motion/react";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";
import { spring, ease, duration } from "@/lib/motion-tokens";

/**
 * Modal — center-screen dialog.
 *
 * Built on `@radix-ui/react-dialog`. The visible motion is split into two
 * passes:
 *  - The overlay scrim cross-fades on `ease.standard` (no spring; fades
 *    don't have momentum).
 *  - The dialog body itself springs in (`spring.default`) with a slight
 *    scale + lift so it feels like the modal "comes forward" rather than
 *    "appears".
 *
 * `title` / `description` props wire to `Dialog.Title` /
 * `Dialog.Description` so screen readers announce the dialog correctly
 * without consumers having to remember the wiring.
 *
 * Implementation note (PR-β review fix): `AnimatePresence` lives **outside**
 * `DialogPrimitive.Portal` and the Portal/Overlay/Content all use
 * `forceMount`. The previous nesting (Portal → AnimatePresence) caused Radix
 * to unmount the entire Portal tree when the dialog closed, killing exit
 * animations. By inverting the nesting and gating the children on a context
 * `open` flag, AnimatePresence sees the children leave and plays the exit
 * spring before the DOM nodes are removed.
 */

type RootProps = {
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  children: React.ReactNode;
  modal?: boolean;
};

const ModalOpenContext = React.createContext<boolean>(false);

const Root = ({
  open,
  defaultOpen = false,
  onOpenChange,
  children,
  modal,
}: RootProps) => {
  const [internalOpen, setInternalOpen] = React.useState(defaultOpen);
  const isControlled = open !== undefined;
  const current = isControlled ? open : internalOpen;

  const handleChange = React.useCallback(
    (next: boolean) => {
      if (!isControlled) setInternalOpen(next);
      onOpenChange?.(next);
    },
    [isControlled, onOpenChange],
  );

  return (
    <ModalOpenContext.Provider value={current}>
      <DialogPrimitive.Root
        open={current}
        onOpenChange={handleChange}
        modal={modal}
      >
        {children}
      </DialogPrimitive.Root>
    </ModalOpenContext.Provider>
  );
};

const Trigger = DialogPrimitive.Trigger;
const Close = DialogPrimitive.Close;

type ModalContentProps = React.ComponentPropsWithoutRef<
  typeof DialogPrimitive.Content
> & {
  title?: React.ReactNode;
  description?: React.ReactNode;
  showClose?: boolean;
  /** Hide visual title — still announced for screen readers. */
  visuallyHiddenTitle?: boolean;
};

const Content = React.forwardRef<
  React.ComponentRef<typeof DialogPrimitive.Content>,
  ModalContentProps
>(
  (
    {
      className,
      children,
      title,
      description,
      showClose = true,
      visuallyHiddenTitle,
      ...rest
    },
    ref,
  ) => {
    const open = React.useContext(ModalOpenContext);
    return (
      <AnimatePresence>
        {open ? (
          <DialogPrimitive.Portal forceMount>
            <DialogPrimitive.Overlay asChild forceMount>
              <motion.div
                key="p7-modal-overlay"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: duration.pop, ease: ease.standard }}
                className="fixed inset-0 z-50 bg-black/40 backdrop-blur-[2px]"
              />
            </DialogPrimitive.Overlay>
            <DialogPrimitive.Content asChild forceMount ref={ref} {...rest}>
              <motion.div
                key="p7-modal-content"
                initial={{ opacity: 0, scale: 0.96, y: 12 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.98, y: 8 }}
                transition={spring.default}
                className={cn(
                  "fixed z-50 left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2",
                  "w-[min(92vw,28rem)] max-h-[88vh] overflow-y-auto",
                  "rounded-p7-sheet border border-surface-hairline",
                  "bg-surface-elevated text-ink-primary shadow-p7-overlay",
                  "p-6",
                  className,
                )}
              >
                {(title || description) && (
                  <header className="mb-4 flex items-start justify-between gap-3">
                    <div className="flex flex-col gap-1">
                      {title ? (
                        <DialogPrimitive.Title
                          className={cn(
                            "text-p7-title-2 text-ink-primary",
                            visuallyHiddenTitle && "sr-only",
                          )}
                        >
                          {title}
                        </DialogPrimitive.Title>
                      ) : null}
                      {description ? (
                        <DialogPrimitive.Description className="text-p7-callout text-ink-secondary">
                          {description}
                        </DialogPrimitive.Description>
                      ) : null}
                    </div>
                    {showClose ? (
                      <DialogPrimitive.Close
                        className={cn(
                          "shrink-0 inline-flex h-8 w-8 items-center justify-center rounded-p7-input",
                          "text-ink-tertiary hover:text-ink-primary hover:bg-surface-overlay",
                          "outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
                          "transition-colors duration-p7-tap",
                        )}
                        aria-label="Close"
                      >
                        <X className="h-4 w-4" />
                      </DialogPrimitive.Close>
                    ) : null}
                  </header>
                )}
                {children}
              </motion.div>
            </DialogPrimitive.Content>
          </DialogPrimitive.Portal>
        ) : null}
      </AnimatePresence>
    );
  },
);
Content.displayName = "Modal.Content";

export const Modal = Object.assign(Root, {
  Trigger,
  Close,
  Content,
});
