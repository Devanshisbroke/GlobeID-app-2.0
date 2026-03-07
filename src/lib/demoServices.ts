/**
 * Demo service simulation APIs for rides, food, flights, hotels, payments.
 * Backend replacement: swap to real API calls via Supabase edge functions.
 */

// ── Ride Services ──
export interface RideProvider {
  id: string;
  name: string;
  icon: string;
  eta: string;
  price: string;
  currency: string;
  vehicleType: string;
  rating: number;
  available: boolean;
}

export const demoRideProviders: RideProvider[] = [
  { id: "uber", name: "Uber", icon: "🚗", eta: "4 min", price: "12.50", currency: "SGD", vehicleType: "UberX", rating: 4.8, available: true },
  { id: "grab", name: "Grab", icon: "🟢", eta: "3 min", price: "11.00", currency: "SGD", vehicleType: "GrabCar", rating: 4.7, available: true },
  { id: "didi", name: "DiDi", icon: "🟠", eta: "6 min", price: "10.50", currency: "SGD", vehicleType: "Express", rating: 4.5, available: true },
  { id: "ola", name: "Ola", icon: "🔵", eta: "8 min", price: "9.80", currency: "SGD", vehicleType: "Mini", rating: 4.3, available: false },
];

export interface RideRequest {
  id: string;
  provider: string;
  pickup: string;
  dropoff: string;
  status: "searching" | "confirmed" | "arriving" | "in_progress" | "completed";
  driver?: { name: string; rating: number; vehicle: string; plate: string };
  eta?: string;
  price: string;
  currency: string;
}

export function simulateRideRequest(providerId: string, pickup: string, dropoff: string): RideRequest {
  const provider = demoRideProviders.find(p => p.id === providerId)!;
  return {
    id: `ride-${Date.now()}`,
    provider: provider.name,
    pickup,
    dropoff,
    status: "confirmed",
    driver: { name: "Ahmad K.", rating: 4.9, vehicle: "Toyota Camry", plate: "SGX 4521" },
    eta: provider.eta,
    price: provider.price,
    currency: provider.currency,
  };
}

// ── Food Delivery ──
export interface Restaurant {
  id: string;
  name: string;
  cuisine: string;
  rating: number;
  deliveryTime: string;
  deliveryFee: string;
  priceRange: string;
  image: string;
  icon: string;
  provider: string;
}

export const demoRestaurants: Restaurant[] = [
  { id: "r1", name: "Din Tai Fung", cuisine: "Chinese • Dumplings", rating: 4.8, deliveryTime: "25-35 min", deliveryFee: "S$2.50", priceRange: "$$", image: "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&h=250&fit=crop", icon: "🥟", provider: "GrabFood" },
  { id: "r2", name: "Jumbo Seafood", cuisine: "Seafood • Local", rating: 4.6, deliveryTime: "30-40 min", deliveryFee: "S$3.00", priceRange: "$$$", image: "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=250&fit=crop", icon: "🦀", provider: "Deliveroo" },
  { id: "r3", name: "The Coconut Club", cuisine: "Malay • Nasi Lemak", rating: 4.7, deliveryTime: "20-30 min", deliveryFee: "S$1.50", priceRange: "$$", image: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=250&fit=crop", icon: "🍛", provider: "FoodPanda" },
  { id: "r4", name: "Burnt Ends", cuisine: "BBQ • Modern", rating: 4.9, deliveryTime: "35-45 min", deliveryFee: "S$4.00", priceRange: "$$$$", image: "https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=250&fit=crop", icon: "🔥", provider: "GrabFood" },
];

// ── Flight Search ──
export interface FlightResult {
  id: string;
  airline: string;
  airlineCode: string;
  from: string;
  to: string;
  departure: string;
  arrival: string;
  duration: string;
  price: number;
  currency: string;
  stops: number;
  class: string;
  icon: string;
}

export const demoFlightResults: FlightResult[] = [
  { id: "fl1", airline: "Singapore Airlines", airlineCode: "SQ", from: "SIN", to: "BOM", departure: "08:30", arrival: "11:45", duration: "5h 15m", price: 485, currency: "USD", stops: 0, class: "Economy", icon: "✈️" },
  { id: "fl2", airline: "Air India", airlineCode: "AI", from: "SIN", to: "BOM", departure: "14:15", arrival: "17:30", duration: "5h 15m", price: 320, currency: "USD", stops: 0, class: "Economy", icon: "✈️" },
  { id: "fl3", airline: "Emirates", airlineCode: "EK", from: "SIN", to: "BOM", departure: "22:00", arrival: "04:30+1", duration: "8h 30m", price: 380, currency: "USD", stops: 1, class: "Economy", icon: "✈️" },
  { id: "fl4", airline: "Singapore Airlines", airlineCode: "SQ", from: "SIN", to: "BOM", departure: "10:00", arrival: "13:15", duration: "5h 15m", price: 1250, currency: "USD", stops: 0, class: "Business", icon: "💎" },
];

// ── Hotel Search ──
export interface HotelResult {
  id: string;
  name: string;
  location: string;
  rating: number;
  stars: number;
  price: number;
  currency: string;
  perNight: boolean;
  image: string;
  amenities: string[];
  available: boolean;
}

export const demoHotelResults: HotelResult[] = [
  { id: "h1", name: "Taj Mahal Palace", location: "Mumbai, Colaba", rating: 4.9, stars: 5, price: 380, currency: "USD", perNight: true, image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=250&fit=crop", amenities: ["Pool", "Spa", "Restaurant", "Bar"], available: true },
  { id: "h2", name: "The Oberoi", location: "Mumbai, Nariman Point", rating: 4.8, stars: 5, price: 320, currency: "USD", perNight: true, image: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&h=250&fit=crop", amenities: ["Pool", "Gym", "Restaurant"], available: true },
  { id: "h3", name: "ITC Grand Central", location: "Mumbai, Parel", rating: 4.6, stars: 5, price: 210, currency: "USD", perNight: true, image: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&h=250&fit=crop", amenities: ["Pool", "Spa", "Restaurant", "Business Center"], available: true },
  { id: "h4", name: "Trident Nariman Point", location: "Mumbai, Marine Drive", rating: 4.5, stars: 5, price: 195, currency: "USD", perNight: true, image: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=250&fit=crop", amenities: ["Pool", "Restaurant", "Gym"], available: false },
];

// ── Payment Networks ──
export interface PaymentNetwork {
  id: string;
  name: string;
  icon: string;
  region: string;
  connected: boolean;
  type: "mobile" | "card" | "bank";
}

export const demoPaymentNetworks: PaymentNetwork[] = [
  { id: "upi", name: "UPI", icon: "🇮🇳", region: "India", connected: true, type: "mobile" },
  { id: "alipay", name: "Alipay", icon: "🔵", region: "China", connected: false, type: "mobile" },
  { id: "wechat", name: "WeChat Pay", icon: "🟢", region: "China", connected: false, type: "mobile" },
  { id: "visa", name: "Visa •••• 4242", icon: "💳", region: "Global", connected: true, type: "card" },
  { id: "mastercard", name: "Mastercard •••• 8888", icon: "💳", region: "Global", connected: true, type: "card" },
  { id: "applepay", name: "Apple Pay", icon: "🍎", region: "Global", connected: true, type: "mobile" },
  { id: "sepa", name: "SEPA Transfer", icon: "🇪🇺", region: "Europe", connected: false, type: "bank" },
];

// ── Local Services ──
export interface LocalService {
  id: string;
  name: string;
  icon: string;
  description: string;
  category: "exchange" | "telecom" | "insurance" | "emergency" | "transport";
}

export const demoLocalServices: LocalService[] = [
  { id: "ls1", name: "Currency Exchange", icon: "💱", description: "Best rates at airport & city", category: "exchange" },
  { id: "ls2", name: "Tourist SIM Card", icon: "📱", description: "Local data plans from S$10", category: "telecom" },
  { id: "ls3", name: "Travel Insurance", icon: "🛡️", description: "Coverage for medical & travel", category: "insurance" },
  { id: "ls4", name: "Emergency: 999", icon: "🚨", description: "Police, Fire, Ambulance", category: "emergency" },
  { id: "ls5", name: "Embassy Locator", icon: "🏛️", description: "Find your country's embassy", category: "emergency" },
  { id: "ls6", name: "Airport Transfer", icon: "🛬", description: "Pre-book airport pickup", category: "transport" },
  { id: "ls7", name: "City Metro Pass", icon: "🚇", description: "Unlimited daily transit", category: "transport" },
  { id: "ls8", name: "Nearest Hospital", icon: "🏥", description: "24/7 emergency care", category: "emergency" },
];

// ── Safety & Emergency ──
export interface EmergencyContact {
  id: string;
  name: string;
  number: string;
  icon: string;
  country: string;
}

export const demoEmergencyContacts: EmergencyContact[] = [
  { id: "e1", name: "Police", number: "999", icon: "🚔", country: "SG" },
  { id: "e2", name: "Ambulance", number: "995", icon: "🚑", country: "SG" },
  { id: "e3", name: "Fire", number: "995", icon: "🚒", country: "SG" },
  { id: "e4", name: "Indian Embassy", number: "+65-6737-6777", icon: "🏛️", country: "SG" },
  { id: "e5", name: "Tourist Helpline", number: "1800-736-2000", icon: "ℹ️", country: "SG" },
];
