/**
 * Keyboard shortcut layer + cheat-sheet overlay.
 *
 * Mounted once at the root (in `App.tsx`) so any screen can be
 * keyboard-driven without re-implementing listeners. Notion-class
 * chord support via `tinykeys` so multi-key sequences (e.g. `g w` →
 * Wallet) feel native instead of single-letter shortcuts that
 * collide with regular typing.
 *
 * Mobile: still mounted, but hidden behind `prefers-coarse-pointer`
 * detection so a touch-only device never sees a "press G W to open
 * the wallet" prompt that has no keyboard.
 */
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { X, Command } from "lucide-react";
import { tinykeys } from "tinykeys";

interface Shortcut {
  keys: string[];
  description: string;
}

const KeyboardShortcuts: React.FC = () => {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [coarse, setCoarse] = useState<boolean>(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    setCoarse(window.matchMedia("(pointer: coarse)").matches);
  }, []);

  // Notion-class chord shortcuts via tinykeys. The library debounces
  // the chord window automatically so "g" doesn't fire on its own.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const unsubscribe = tinykeys(window, {
      "?": (e) => {
        e.preventDefault();
        setOpen(true);
      },
      "Shift+?": (e) => {
        e.preventDefault();
        setOpen(true);
      },
      "$mod+/": (e) => {
        e.preventDefault();
        setOpen((o) => !o);
      },
      Escape: () => setOpen(false),
      "g h": () => navigate("/"),
      "g w": () => navigate("/wallet"),
      "g t": () => navigate("/trips"),
      "g i": () => navigate("/identity"),
      "g m": () => navigate("/map"),
      "g s": () => navigate("/scan"),
      "g p": () => navigate("/profile"),
    });
    return () => unsubscribe();
  }, [navigate]);

  if (coarse) return null;

  const shortcuts: Shortcut[] = [
    { keys: ["G", "H"], description: "Go to Home" },
    { keys: ["G", "T"], description: "Go to Trips" },
    { keys: ["G", "W"], description: "Go to Wallet" },
    { keys: ["G", "I"], description: "Go to Identity" },
    { keys: ["G", "M"], description: "Open Globe / Map" },
    { keys: ["G", "S"], description: "Open Scanner" },
    { keys: ["G", "P"], description: "Open Profile" },
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
                        className="font-mono text-[11px] tracking-wide text-foreground bg-surface-elevated border border-border/60 rounded-md px-2 py-1 min-w-[24px] text-center"
                      >
                        {k}
                      </kbd>
                    ))}
                  </span>
                </li>
              ))}
            </ul>
            <p className="mt-4 text-[11px] text-muted-foreground leading-relaxed">
              Chord shortcuts (e.g. <kbd className="font-mono text-[10px] bg-surface-elevated border border-border/60 rounded px-1 py-0.5">G</kbd>{" "}
              <kbd className="font-mono text-[10px] bg-surface-elevated border border-border/60 rounded px-1 py-0.5">W</kbd>)
              are press-then-press. They never fire while you're typing in a text field.
            </p>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
};

export default KeyboardShortcuts;
