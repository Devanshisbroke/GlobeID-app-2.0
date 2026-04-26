import * as React from "react";
import { Command as CmdK } from "cmdk";
import * as DialogPrimitive from "@radix-ui/react-dialog";
import { motion, AnimatePresence } from "motion/react";
import { Search } from "lucide-react";
import { cn } from "@/lib/utils";
import { spring, ease, duration } from "@/lib/motion-tokens";

/**
 * CommandBar — Raycast / Cmd+K style global command palette.
 *
 * Composes `cmdk` (already installed) for the input + filtered list and
 * `@radix-ui/react-dialog` for portal + focus-trap + ESC dismissal. The
 * actual route registry lives in PR-γ; this primitive provides the shell.
 *
 * Visual treatment is `Surface variant="elevated"` with the strongest
 * shadow tier (`shadow-p7-overlay`) so it sits above all chrome,
 * including the bottom nav glass.
 *
 * Usage:
 *   <CommandBar open={open} onOpenChange={setOpen}>
 *     <CommandBar.Group heading="Navigate">
 *       <CommandBar.Item onSelect={…} icon={<Home />}>Home</CommandBar.Item>
 *     </CommandBar.Group>
 *   </CommandBar>
 */

type RootProps = React.ComponentPropsWithoutRef<typeof CmdK> & {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  placeholder?: string;
  /** Optional empty-state content. */
  emptyState?: React.ReactNode;
};

const Root = ({
  open,
  onOpenChange,
  placeholder = "Type a command, search anything…",
  emptyState,
  children,
  className,
  ...rest
}: RootProps) => {
  return (
    <DialogPrimitive.Root open={open} onOpenChange={onOpenChange}>
      <DialogPrimitive.Portal>
        <AnimatePresence>
          <DialogPrimitive.Overlay asChild>
            <motion.div
              key="p7-cmdbar-overlay"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: duration.pop, ease: ease.standard }}
              className="fixed inset-0 z-[60] bg-black/40 backdrop-blur-[2px]"
            />
          </DialogPrimitive.Overlay>
          <DialogPrimitive.Content asChild>
            <motion.div
              key="p7-cmdbar-content"
              initial={{ opacity: 0, scale: 0.97, y: -8 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.98, y: -4 }}
              transition={spring.default}
              className={cn(
                "fixed z-[60] left-1/2 top-[12vh] -translate-x-1/2",
                "w-[min(92vw,38rem)] overflow-hidden",
                "rounded-p7-surface border border-surface-hairline",
                "bg-surface-elevated text-ink-primary shadow-p7-overlay",
              )}
            >
              <DialogPrimitive.Title className="sr-only">
                Command palette
              </DialogPrimitive.Title>
              <CmdK
                className={cn("flex flex-col", className)}
                {...rest}
              >
                <div className="flex items-center gap-2 border-b border-surface-hairline px-4">
                  <Search className="h-4 w-4 shrink-0 text-ink-tertiary" />
                  <CmdK.Input
                    placeholder={placeholder}
                    className={cn(
                      "flex-1 h-12 bg-transparent outline-none",
                      "text-p7-body text-ink-primary placeholder:text-ink-tertiary",
                    )}
                  />
                </div>
                <CmdK.List className="max-h-[60vh] overflow-y-auto p-2">
                  <CmdK.Empty className="py-8 text-center text-p7-callout text-ink-tertiary">
                    {emptyState ?? "No matches found."}
                  </CmdK.Empty>
                  {children}
                </CmdK.List>
              </CmdK>
            </motion.div>
          </DialogPrimitive.Content>
        </AnimatePresence>
      </DialogPrimitive.Portal>
    </DialogPrimitive.Root>
  );
};

const Group = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof CmdK.Group>
>(({ className, ...rest }, _ref) => (
  <CmdK.Group
    className={cn(
      "px-1 py-1",
      "[&_[cmdk-group-heading]]:px-2 [&_[cmdk-group-heading]]:py-1.5",
      "[&_[cmdk-group-heading]]:text-p7-caption-2 [&_[cmdk-group-heading]]:font-medium",
      "[&_[cmdk-group-heading]]:uppercase [&_[cmdk-group-heading]]:tracking-wider",
      "[&_[cmdk-group-heading]]:text-ink-tertiary",
      className,
    )}
    {...rest}
  />
));
Group.displayName = "CommandBar.Group";

type ItemProps = React.ComponentPropsWithoutRef<typeof CmdK.Item> & {
  icon?: React.ReactNode;
  shortcut?: React.ReactNode;
};

const Item = React.forwardRef<HTMLDivElement, ItemProps>(
  ({ className, icon, shortcut, children, ...rest }, _ref) => (
    <CmdK.Item
      className={cn(
        "flex items-center gap-3 px-3 py-2 rounded-p7-input cursor-pointer",
        "text-p7-body text-ink-primary",
        "outline-none aria-selected:bg-brand-soft aria-selected:text-brand",
        "transition-colors duration-p7-tap ease-p7-standard",
        className,
      )}
      {...rest}
    >
      {icon ? (
        <span className="shrink-0 [&>svg]:h-4 [&>svg]:w-4">{icon}</span>
      ) : null}
      <span className="flex-1 truncate">{children}</span>
      {shortcut ? (
        <kbd className="shrink-0 text-p7-caption-2 font-mono text-ink-tertiary">
          {shortcut}
        </kbd>
      ) : null}
    </CmdK.Item>
  ),
);
Item.displayName = "CommandBar.Item";

const Separator = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof CmdK.Separator>
>(({ className, ...rest }, _ref) => (
  <CmdK.Separator
    className={cn("my-1 h-px bg-surface-hairline", className)}
    {...rest}
  />
));
Separator.displayName = "CommandBar.Separator";

export const CommandBar = Object.assign(Root, {
  Group,
  Item,
  Separator,
});
