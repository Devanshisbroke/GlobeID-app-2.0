export interface CountryTheme {
  code: string;
  name: string;
  flag: string;
  greeting: string;
  greetingLocal: string;
  currency: string;
  currencySymbol: string;
  accentHsl: string; // HSL values for theming
}

export const countryThemes: Record<string, CountryTheme> = {
  IN: {
    code: "IN",
    name: "India",
    flag: "🇮🇳",
    greeting: "Welcome to India",
    greetingLocal: "भारत में आपका स्वागत है",
    currency: "INR",
    currencySymbol: "₹",
    accentHsl: "24 95% 53%", // saffron
  },
  US: {
    code: "US",
    name: "United States",
    flag: "🇺🇸",
    greeting: "Welcome to the United States",
    greetingLocal: "Welcome",
    currency: "USD",
    currencySymbol: "$",
    accentHsl: "217 71% 53%", // blue
  },
  SG: {
    code: "SG",
    name: "Singapore",
    flag: "🇸🇬",
    greeting: "Welcome to Singapore",
    greetingLocal: "Selamat Datang",
    currency: "SGD",
    currencySymbol: "S$",
    accentHsl: "0 72% 51%", // red
  },
  AE: {
    code: "AE",
    name: "United Arab Emirates",
    flag: "🇦🇪",
    greeting: "Welcome to the UAE",
    greetingLocal: "أهلاً وسهلاً",
    currency: "AED",
    currencySymbol: "د.إ",
    accentHsl: "142 53% 44%", // green
  },
  GB: {
    code: "GB",
    name: "United Kingdom",
    flag: "🇬🇧",
    greeting: "Welcome to the United Kingdom",
    greetingLocal: "Welcome",
    currency: "GBP",
    currencySymbol: "£",
    accentHsl: "225 73% 57%", // royal blue
  },
  JP: {
    code: "JP",
    name: "Japan",
    flag: "🇯🇵",
    greeting: "Welcome to Japan",
    greetingLocal: "ようこそ日本へ",
    currency: "JPY",
    currencySymbol: "¥",
    accentHsl: "0 72% 51%", // red
  },
};

export function getCountryTheme(code: string): CountryTheme {
  return countryThemes[code] ?? {
    code,
    name: code,
    flag: "🏳️",
    greeting: `Welcome to ${code}`,
    greetingLocal: "Welcome",
    currency: code,
    currencySymbol: "$",
    accentHsl: "185 72% 48%",
  };
}
