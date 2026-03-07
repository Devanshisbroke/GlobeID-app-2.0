/**
 * Icon mapping — replaces emoji usage with Lucide icon references.
 * Components use getIcon(key) to render the proper vector icon.
 */
import {
  Plane, Hotel, Car, ShoppingBag, ArrowUpRight, ArrowDownLeft,
  RefreshCw, Send, CreditCard, Scan, Utensils, ShieldCheck,
  Fingerprint, Lock, ArrowRightLeft, MapPin, Globe, Smartphone,
  Shield, Siren, Landmark, PlaneLanding, TrainFront, Building2,
  Star, Flame, Phone, CircleAlert, CircleCheck, Banknote, Wallet,
  Sparkles, QrCode, Receipt, ChefHat, Gem, Package, ScanLine
} from "lucide-react";
import React from "react";

// Map string keys → Lucide components
const iconMap: Record<string, React.ElementType> = {
  // Transport
  car: Car,
  plane: Plane,
  "plane-landing": PlaneLanding,
  train: TrainFront,

  // Accommodation
  hotel: Hotel,
  building: Building2,

  // Food
  utensils: Utensils,
  "chef-hat": ChefHat,
  flame: Flame,

  // Finance
  send: Send,
  receive: ArrowDownLeft,
  "arrow-up-right": ArrowUpRight,
  convert: ArrowRightLeft,
  "credit-card": CreditCard,
  banknote: Banknote,
  wallet: Wallet,
  receipt: Receipt,

  // Identity
  scan: Scan,
  "scan-line": ScanLine,
  "shield-check": ShieldCheck,
  shield: Shield,
  fingerprint: Fingerprint,
  lock: Lock,

  // Services
  smartphone: Smartphone,
  globe: Globe,
  "map-pin": MapPin,
  landmark: Landmark,
  siren: Siren,
  phone: Phone,
  star: Star,
  gem: Gem,
  package: Package,

  // Status
  "circle-check": CircleCheck,
  "circle-alert": CircleAlert,

  // AI
  sparkles: Sparkles,
  "qr-code": QrCode,

  // Shopping
  "shopping-bag": ShoppingBag,
};

export function getIcon(key: string): React.ElementType {
  return iconMap[key] ?? Globe;
}

export type IconKey = keyof typeof iconMap;
