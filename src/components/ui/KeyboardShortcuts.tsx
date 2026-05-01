/**
 * Keyboard shortcuts cheat-sheet — opens via "?" or Ctrl/Cmd+/.
 *
 * Mounted once at the root (in `App.tsx`) so any screen can be
 * tab-driven without each having to re-implement listeners. Shortcuts
 * are limited to the routes the bottom navigation already exposes —
 * we don't try to invent a fictional command surface.
 *
 * Mobile: still mounted, but hidden behind `prefers-coarse-pointer`
 * detection so a touch-only device never sees a "press G to open the
 * globe" prompt that has no keyboard.
 */
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { X, Command } from "lucide-react";

interface Shortcut {
  keys: string[];
  description: string;
  run?: () => void;
}

const KeyboardShortcuts: React.FC = () => {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [coarse, setCoarse] = useState<boolean>(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    setCoarse(window.matchMedia("(pointer: coarse)").matches);
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const handler = (e: KeyboardEvent) => {
      // Don't intercept while the user is typing in an input.
      const target = e.target as HTMLElement | null;
      if (target && /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName)) return;
      if (target?.isContentEditable) return;

      if (e.key === "?" || (e.key === "/" && (e.metaKey || e.ctrlKey))) {
        e.preventDefault();
        setOpen((o) => !o);
        return;
      }
      if (open && e.key === "Escape") {
        setOpen(false);
        return;
      }
      // Single-letter nav shortcuts only when overlay is closed.
      if (open) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      switch (e.key.toLowerCase()) {
        case "h":
          navigate("/");
          break;
        case "t":
          navigate("/travel");
          break;
        case "w":
          navigate("/wallet");
          break;
        case "s":
          navigate("/scan");
          break;
        case "g":
          navigate("/globe");
          break;
        case "p":
          navigate("/profile");
          break;
        default:
          break;
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [navigate, open]);

  if (coarse) return null;

  const shortcuts: Shortcut[] = [
    { keys: ["H"], description: "Go to Home" },
    { keys: ["T"], description: "Go to Travel" },
    { keys: ["W"], description: "Go to Wallet" },
    { keys: ["S"], description: "Open Scanner" },
    { keys: ["G"], description: "Open Globe" },
    { keys: ["P"], description: "Open Profile" },
    { keys: ["?"], description: "Toggle this menu" },
    { keys: ["Esc"], description: "Close any sheet" },
  ];

  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[200] flex items-center justify-center bg-background/70 backdrop-blur-md p-4"
          onClick={() => setOpen(false)}
          role="dialog"
          aria-modal="true"
          aria-label="Keyboard shortcuts"
        >
          <motion.div
            initial={{ y: 24, scale: 0.96, opacity: 0 }}
            animate={{ y: 0, scale: 1, opacity: 1 }}
            exit={{ y: 12, scale: 0.97, opacity: 0 }}
            transition={{ type: "spring", stiffness: 280, damping: 28 }}
            className="w-full max-w-sm rounded-3xl border border-border bg-card p-5 shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Command className="h-4 w-4 text-foreground" />
                <p className="text-sm font-semibold text-foreground">Shortcuts</p>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                aria-label="Close"
                className="flex h-8 w-8 items-center justify-center rounded-full bg-muted text-muted-foreground hover:bg-muted/80"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            <ul className="space-y-2">
              {shortcuts.map((s) => (
                <li
                  key={s.description}
                  className="flex items-center justify-between text-[13px] text-foreground/90"
                >
                  <span>{s.description}</span>
                  <span className="flex gap-1">
                    {s.keys.map((k) => (
                      <kbd
                        key={k}
                        className="inline-block rounded-md border border-border bg-muted/40 px-2 py-0.5 text-[11px] font-mono text-muted-foreground"
                      >
                        {k}
                      </kbd>
                    ))}
                  </span>
                </li>
              ))}
            </ul>
            <p className="mt-4 text-[10px] uppercase tracking-widest text-muted-foreground">
              Press ? again or Esc to dismiss
            </p>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
};

export default KeyboardShortcuts;
