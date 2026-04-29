/**
 * Slice-C — i18n skeleton.
 *
 * Minimal `react-i18next` wiring so the rest of the app can lean on
 * `useTranslation()` without a hot-reload cycle. Two locales are
 * shipped: `en` (canonical) and `hi` (Hindi, machine-translated seed
 * for the ~30 most-common strings — easily replaced with curated
 * copy once we have a translator).
 *
 * Detection order:
 *   1. `globe-i18n-lang` localStorage override (Profile → Language toggle).
 *   2. `navigator.language` prefix match.
 *   3. Fallback to `en`.
 *
 * String coverage is intentionally partial — full extraction is its own
 * multi-session undertaking. The keys defined here are the chrome + the
 * most-visible copy on Home / Profile / SuperServicesHub, so the toggle
 * demonstrably changes surface language without pretending every string
 * is localised.
 */
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import LanguageDetector from "i18next-browser-languagedetector";

import en from "./locales/en.json";
import hi from "./locales/hi.json";

export const SUPPORTED_LANGS = ["en", "hi"] as const;
export type SupportedLang = (typeof SUPPORTED_LANGS)[number];

export const LANG_LABELS: Record<SupportedLang, string> = {
  en: "English",
  hi: "हिन्दी",
};

void i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      hi: { translation: hi },
    },
    fallbackLng: "en",
    supportedLngs: SUPPORTED_LANGS as unknown as string[],
    nonExplicitSupportedLngs: true,
    interpolation: { escapeValue: false },
    detection: {
      order: ["localStorage", "navigator"],
      lookupLocalStorage: "globe-i18n-lang",
      caches: ["localStorage"],
    },
    returnNull: false,
  });

export function setLanguage(lang: SupportedLang): void {
  void i18n.changeLanguage(lang);
  try {
    localStorage.setItem("globe-i18n-lang", lang);
  } catch {
    // private mode / quota
  }
}

export function currentLanguage(): SupportedLang {
  const lng = i18n.language?.slice(0, 2) as SupportedLang;
  return SUPPORTED_LANGS.includes(lng) ? lng : "en";
}

export default i18n;
