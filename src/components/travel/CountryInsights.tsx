import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { getVisaRequirement } from "@/lib/visaEngine";
import { useUserStore } from "@/store/userStore";
import { ShieldCheck, DollarSign, Languages, Clock, MapPin, X } from "lucide-react";
import { cn } from "@/lib/utils";

interface CountryInsightsProps {
  country: string;
  onClose: () => void;
}

// Mock country data
const countryData: Record<string, {
  currency: string;
  currencySymbol: string;
  language: string;
  avgFlightDuration: string;
  popularCities: string[];
  timezone: string;
  flag: string;
}> = {
  Japan: { currency: "JPY (¥)", currencySymbol: "¥", language: "Japanese", avgFlightDuration: "6h 50m", popularCities: ["Tokyo", "Osaka", "Kyoto", "Hiroshima"], timezone: "UTC+9", flag: "🇯🇵" },
  Singapore: { currency: "SGD (S$)", currencySymbol: "S$", language: "English, Mandarin, Malay, Tamil", avgFlightDuration: "18h 15m", popularCities: ["Marina Bay", "Sentosa", "Orchard Road", "Chinatown"], timezone: "UTC+8", flag: "🇸🇬" },
  Thailand: { currency: "THB (฿)", currencySymbol: "฿", language: "Thai", avgFlightDuration: "5h 30m", popularCities: ["Bangkok", "Phuket", "Chiang Mai", "Pattaya"], timezone: "UTC+7", flag: "🇹🇭" },
  Indonesia: { currency: "IDR (Rp)", currencySymbol: "Rp", language: "Indonesian", avgFlightDuration: "7h 20m", popularCities: ["Bali", "Jakarta", "Yogyakarta", "Lombok"], timezone: "UTC+7 to +9", flag: "🇮🇩" },
  UAE: { currency: "AED (د.إ)", currencySymbol: "د.إ", language: "Arabic, English", avgFlightDuration: "3h 30m", popularCities: ["Dubai", "Abu Dhabi", "Sharjah"], timezone: "UTC+4", flag: "🇦🇪" },
  "United Kingdom": { currency: "GBP (£)", currencySymbol: "£", language: "English", avgFlightDuration: "9h", popularCities: ["London", "Edinburgh", "Manchester", "Oxford"], timezone: "UTC+0", flag: "🇬🇧" },
  France: { currency: "EUR (€)", currencySymbol: "€", language: "French", avgFlightDuration: "8h 30m", popularCities: ["Paris", "Nice", "Lyon", "Marseille"], timezone: "UTC+1", flag: "🇫🇷" },
  "United States": { currency: "USD ($)", currencySymbol: "$", language: "English", avgFlightDuration: "Direct varies", popularCities: ["New York", "Los Angeles", "San Francisco", "Miami"], timezone: "UTC-5 to -10", flag: "🇺🇸" },
  India: { currency: "INR (₹)", currencySymbol: "₹", language: "Hindi, English", avgFlightDuration: "Domestic", popularCities: ["Mumbai", "Delhi", "Bangalore", "Goa"], timezone: "UTC+5:30", flag: "🇮🇳" },
  Brazil: { currency: "BRL (R$)", currencySymbol: "R$", language: "Portuguese", avgFlightDuration: "20h+", popularCities: ["Rio de Janeiro", "São Paulo", "Salvador"], timezone: "UTC-3", flag: "🇧🇷" },
  Australia: { currency: "AUD (A$)", currencySymbol: "A$", language: "English", avgFlightDuration: "14h", popularCities: ["Sydney", "Melbourne", "Brisbane", "Perth"], timezone: "UTC+8 to +11", flag: "🇦🇺" },
  Turkey: { currency: "TRY (₺)", currencySymbol: "₺", language: "Turkish", avgFlightDuration: "7h", popularCities: ["Istanbul", "Antalya", "Cappadocia", "Izmir"], timezone: "UTC+3", flag: "🇹🇷" },
};

const CountryInsights: React.FC<CountryInsightsProps> = ({ country, onClose }) => {
  const { profile } = useUserStore();
  const visaReq = getVisaRequirement(profile.nationality, country);
  const data = countryData[country];

  if (!data) {
    return (
      <AnimatedPage>
        <GlassCard variant="premium" depth="lg" className="relative">
          <button onClick={onClose} className="absolute top-3 right-3 w-7 h-7 rounded-full bg-secondary/60 flex items-center justify-center">
            <X className="w-3.5 h-3.5 text-muted-foreground" />
          </button>
          <p className="text-sm text-muted-foreground">No data available for {country}</p>
        </GlassCard>
      </AnimatedPage>
    );
  }

  return (
    <AnimatedPage>
      <GlassCard variant="premium" depth="lg" className="relative overflow-hidden">
        <div className="absolute top-0 right-0 w-28 h-28 rounded-full bg-gradient-ocean blur-3xl opacity-10 pointer-events-none" />
        <button onClick={onClose} className="absolute top-3 right-3 w-7 h-7 rounded-full bg-secondary/60 flex items-center justify-center z-10">
          <X className="w-3.5 h-3.5 text-muted-foreground" />
        </button>

        <div className="flex items-center gap-3 mb-4">
          <span className="text-3xl">{data.flag}</span>
          <div>
            <h3 className="text-base font-bold text-foreground">{country}</h3>
            <p className="text-xs text-muted-foreground">{data.timezone}</p>
          </div>
        </div>

        <div className="space-y-3">
          {/* Visa */}
          <div className="flex items-center gap-3 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <ShieldCheck className={cn("w-5 h-5 shrink-0", visaReq.color)} />
            <div className="flex-1 min-w-0">
              <p className="text-xs text-muted-foreground">Visa Requirement</p>
              <p className={cn("text-sm font-bold", visaReq.color)}>{visaReq.label}</p>
              {visaReq.durationAllowed && <p className="text-[10px] text-muted-foreground">{visaReq.durationAllowed}</p>}
            </div>
          </div>

          {/* Currency */}
          <div className="flex items-center gap-3 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <DollarSign className="w-5 h-5 text-neon-amber shrink-0" />
            <div>
              <p className="text-xs text-muted-foreground">Currency</p>
              <p className="text-sm font-bold text-foreground">{data.currency}</p>
            </div>
          </div>

          {/* Language */}
          <div className="flex items-center gap-3 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <Languages className="w-5 h-5 text-primary shrink-0" />
            <div>
              <p className="text-xs text-muted-foreground">Language</p>
              <p className="text-sm font-bold text-foreground">{data.language}</p>
            </div>
          </div>

          {/* Flight Duration */}
          <div className="flex items-center gap-3 p-3 rounded-xl bg-secondary/30 border border-border/20">
            <Clock className="w-5 h-5 text-muted-foreground shrink-0" />
            <div>
              <p className="text-xs text-muted-foreground">Avg Flight Duration</p>
              <p className="text-sm font-bold text-foreground">{data.avgFlightDuration}</p>
            </div>
          </div>

          {/* Popular Cities */}
          <div className="p-3 rounded-xl bg-secondary/30 border border-border/20">
            <div className="flex items-center gap-2 mb-2">
              <MapPin className="w-4 h-4 text-accent" />
              <p className="text-xs text-muted-foreground">Popular Cities</p>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {data.popularCities.map((city) => (
                <span key={city} className="text-[10px] px-2.5 py-1 rounded-full bg-primary/10 text-primary font-medium border border-primary/20">
                  {city}
                </span>
              ))}
            </div>
          </div>

          {visaReq.notes && (
            <p className="text-[10px] text-muted-foreground text-center px-2">{visaReq.notes}</p>
          )}
        </div>
      </GlassCard>
    </AnimatedPage>
  );
};

export default CountryInsights;
