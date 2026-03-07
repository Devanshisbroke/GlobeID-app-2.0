import React, { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";
import { cn } from "@/lib/utils";

const ThemeToggle: React.FC = () => {
  const [dark, setDark] = useState(() => {
    if (typeof window === "undefined") return true;
    return document.documentElement.classList.contains("dark") ||
      (!document.documentElement.classList.contains("light") &&
       window.matchMedia("(prefers-color-scheme: dark)").matches);
  });

  useEffect(() => {
    if (dark) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
    localStorage.setItem("globe-theme", dark ? "dark" : "light");
  }, [dark]);

  // Init from localStorage
  useEffect(() => {
    const saved = localStorage.getItem("globe-theme");
    if (saved === "light") setDark(false);
    else if (saved === "dark") setDark(true);
  }, []);

  return (
    <button
      onClick={() => setDark(!dark)}
      className={cn(
        "w-9 h-9 rounded-xl flex items-center justify-center",
        "glass border border-border/40",
        "text-muted-foreground hover:text-foreground",
        "transition-all duration-[var(--motion-small)]",
        "active:scale-90"
      )}
      aria-label="Toggle theme"
    >
      {dark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
    </button>
  );
};

export default ThemeToggle;
