import { getAirport } from "./airports";
import { useUserStore } from "@/store/userStore";

export interface LocationContext {
  country: string;
  city: string;
  iata: string;
  currency: string;
  language: string;
}

const locationProfiles: Record<string, Omit<LocationContext, "country" | "city" | "iata">> = {
  Singapore: { currency: "SGD", language: "English" },
  Japan: { currency: "JPY", language: "Japanese" },
  India: { currency: "INR", language: "Hindi" },
  "United States": { currency: "USD", language: "English" },
  "United Kingdom": { currency: "GBP", language: "English" },
  France: { currency: "EUR", language: "French" },
  UAE: { currency: "AED", language: "Arabic" },
  Thailand: { currency: "THB", language: "Thai" },
  Australia: { currency: "AUD", language: "English" },
};

/** Detect location from most recent upcoming flight destination */
export function detectCurrentLocation(): LocationContext {
  const records = useUserStore.getState().travelHistory;
  // Sort upcoming/current trips by date and take the soonest.
  const upcoming = records
    .filter((r) => r.type === "upcoming" || r.type === "current")
    .slice()
    .sort((a, b) => a.date.localeCompare(b.date))[0];
  if (upcoming) {
    const apt = getAirport(upcoming.to);
    if (apt) {
      const profile = locationProfiles[apt.country] || { currency: "USD", language: "English" };
      return { country: apt.country, city: apt.city, iata: apt.iata, ...profile };
    }
  }
  return { country: "Singapore", city: "Singapore", iata: "SIN", currency: "SGD", language: "English" };
}

// ── Localized services per country ──
export interface LocalizedService {
  id: string;
  name: string;
  description: string;
  category: "ride" | "food" | "activity" | "transport" | "shopping";
  icon: string;
  gradient: string;
}

const localizedServices: Record<string, LocalizedService[]> = {
  Singapore: [
    { id: "sg-1", name: "Grab", description: "Southeast Asia's super app", category: "ride", icon: "car", gradient: "bg-gradient-forest" },
    { id: "sg-2", name: "Hawker Centres", description: "Iconic street food culture", category: "food", icon: "utensils", gradient: "bg-gradient-sunset" },
    { id: "sg-3", name: "Marina Bay Tour", description: "Iconic waterfront experience", category: "activity", icon: "landmark", gradient: "bg-gradient-ocean" },
    { id: "sg-4", name: "MRT Pass", description: "Unlimited metro travel", category: "transport", icon: "train", gradient: "bg-gradient-cosmic" },
    { id: "sg-5", name: "Orchard Road", description: "Premium shopping district", category: "shopping", icon: "shopping-bag", gradient: "bg-gradient-aurora" },
  ],
  Japan: [
    { id: "jp-1", name: "JR Pass", description: "Unlimited bullet train travel", category: "transport", icon: "train", gradient: "bg-gradient-cosmic" },
    { id: "jp-2", name: "Sushi Omakase", description: "Chef's choice dining", category: "food", icon: "utensils", gradient: "bg-gradient-sunset" },
    { id: "jp-3", name: "Temple Tours", description: "Historic Kyoto temples", category: "activity", icon: "landmark", gradient: "bg-gradient-forest" },
    { id: "jp-4", name: "Suica Card", description: "Contactless transit & shopping", category: "transport", icon: "credit-card", gradient: "bg-gradient-ocean" },
    { id: "jp-5", name: "Akihabara", description: "Electronics & anime culture", category: "shopping", icon: "shopping-bag", gradient: "bg-gradient-aurora" },
  ],
  India: [
    { id: "in-1", name: "Ola", description: "India's ride-hailing platform", category: "ride", icon: "car", gradient: "bg-gradient-forest" },
    { id: "in-2", name: "Street Food Walk", description: "Guided culinary tours", category: "food", icon: "utensils", gradient: "bg-gradient-sunset" },
    { id: "in-3", name: "Taj Mahal Visit", description: "Wonder of the World", category: "activity", icon: "landmark", gradient: "bg-gradient-ocean" },
    { id: "in-4", name: "Metro Card", description: "Delhi Metro smart card", category: "transport", icon: "train", gradient: "bg-gradient-cosmic" },
  ],
  UAE: [
    { id: "ae-1", name: "Careem", description: "Middle East ride-hailing", category: "ride", icon: "car", gradient: "bg-gradient-forest" },
    { id: "ae-2", name: "Brunch Experience", description: "Luxury Friday brunch", category: "food", icon: "utensils", gradient: "bg-gradient-sunset" },
    { id: "ae-3", name: "Desert Safari", description: "Dune bashing adventure", category: "activity", icon: "compass", gradient: "bg-gradient-ocean" },
    { id: "ae-4", name: "Dubai Mall", description: "World's largest shopping center", category: "shopping", icon: "shopping-bag", gradient: "bg-gradient-aurora" },
  ],
};

export function getLocalizedServices(country: string): LocalizedService[] {
  return localizedServices[country] || localizedServices["Singapore"];
}

// ── Mock data for sub-screens ──
export interface Hotel {
  id: string;
  name: string;
  location: string;
  rating: number;
  stars: number;
  price: number;
  currency: string;
  image: string;
  amenities: string[];
}

export interface Activity {
  id: string;
  name: string;
  duration: string;
  price: number;
  currency: string;
  rating: number;
  category: string;
  location: string;
  image: string;
}

export interface TransportOption {
  id: string;
  name: string;
  type: "metro" | "bus" | "shuttle" | "bike" | "ferry";
  price: string;
  frequency: string;
  icon: string;
}

const hotelsByCountry: Record<string, Hotel[]> = {
  Singapore: [
    { id: "h1", name: "Marina Bay Sands", location: "Marina Bay", rating: 4.9, stars: 5, price: 520, currency: "SGD", image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=250&fit=crop", amenities: ["Infinity Pool", "Casino", "Spa", "Sky Park"] },
    { id: "h2", name: "Raffles Hotel", location: "Beach Road", rating: 4.8, stars: 5, price: 680, currency: "SGD", image: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&h=250&fit=crop", amenities: ["Heritage", "Bar", "Spa", "Restaurant"] },
    { id: "h3", name: "Capella Singapore", location: "Sentosa", rating: 4.7, stars: 5, price: 450, currency: "SGD", image: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=250&fit=crop", amenities: ["Beach", "Pool", "Spa", "Nature"] },
    { id: "h4", name: "Hotel G", location: "Middle Road", rating: 4.3, stars: 3, price: 120, currency: "SGD", image: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=250&fit=crop", amenities: ["Gym", "Restaurant", "Bar"] },
  ],
};

const activitiesByCountry: Record<string, Activity[]> = {
  Singapore: [
    { id: "a1", name: "Gardens by the Bay", duration: "3 hours", price: 28, currency: "SGD", rating: 4.8, category: "Nature", location: "Marina Bay", image: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=250&fit=crop" },
    { id: "a2", name: "Sentosa Island Tour", duration: "Full day", price: 65, currency: "SGD", rating: 4.6, category: "Adventure", location: "Sentosa", image: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=250&fit=crop" },
    { id: "a3", name: "Night Safari", duration: "4 hours", price: 45, currency: "SGD", rating: 4.7, category: "Wildlife", location: "Mandai", image: "https://images.unsplash.com/photo-1474511320723-9a56873571b7?w=400&h=250&fit=crop" },
    { id: "a4", name: "Chinatown Walking Tour", duration: "2 hours", price: 15, currency: "SGD", rating: 4.5, category: "Culture", location: "Chinatown", image: "https://images.unsplash.com/photo-1533050487297-09b450131914?w=400&h=250&fit=crop" },
  ],
};

const transportByCountry: Record<string, TransportOption[]> = {
  Singapore: [
    { id: "t1", name: "MRT (Metro)", type: "metro", price: "S$1.50–2.50", frequency: "Every 3 min", icon: "train" },
    { id: "t2", name: "SBS Bus", type: "bus", price: "S$1.00–2.00", frequency: "Every 8 min", icon: "bus" },
    { id: "t3", name: "Airport Shuttle", type: "shuttle", price: "S$9.00", frequency: "Every 15 min", icon: "plane-landing" },
    { id: "t4", name: "SG Bike", type: "bike", price: "S$1.00/30min", frequency: "On demand", icon: "bike" },
    { id: "t5", name: "Harbour Ferry", type: "ferry", price: "S$4.00", frequency: "Every 20 min", icon: "ship" },
  ],
};

export function getHotels(country: string): Hotel[] {
  return hotelsByCountry[country] || hotelsByCountry["Singapore"];
}
export function getActivities(country: string): Activity[] {
  return activitiesByCountry[country] || activitiesByCountry["Singapore"];
}
export function getTransportOptions(country: string): TransportOption[] {
  return transportByCountry[country] || transportByCountry["Singapore"];
}
