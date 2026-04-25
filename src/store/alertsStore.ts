import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface TravelAlert {
  id: string;
  type: "visa_change" | "flight_disruption" | "advisory" | "info";
  title: string;
  description: string;
  country?: string;
  severity: "low" | "medium" | "high";
  timestamp: string;
  read: boolean;
}

interface AlertsState {
  alerts: TravelAlert[];
  markRead: (id: string) => void;
  dismissAlert: (id: string) => void;
  unreadCount: () => number;
}

const defaultAlerts: TravelAlert[] = [
  {
    id: "alert-1",
    type: "visa_change",
    title: "Japan Visa Policy Update",
    description: "Japan now offers e-visa for Indian nationals for short-term stays up to 30 days.",
    country: "Japan",
    severity: "medium",
    timestamp: "2 hours ago",
    read: false,
  },
  {
    id: "alert-2",
    type: "flight_disruption",
    title: "SFO Fog Advisory",
    description: "Possible delays at San Francisco International due to morning fog. Your SQ31 flight may be affected.",
    severity: "high",
    timestamp: "4 hours ago",
    read: false,
  },
  {
    id: "alert-3",
    type: "advisory",
    title: "Singapore Health Advisory",
    description: "Singapore requires valid health insurance for all visitors. Ensure coverage before travel.",
    country: "Singapore",
    severity: "low",
    timestamp: "1 day ago",
    read: false,
  },
  {
    id: "alert-4",
    type: "info",
    title: "Currency Rate Alert",
    description: "USD to SGD rate is at a 6-month high. Good time to convert currency.",
    severity: "low",
    timestamp: "2 days ago",
    read: true,
  },
];

export const useAlertsStore = create<AlertsState>()(
  persist(
    (set, get) => ({
      alerts: defaultAlerts,
      markRead: (id) =>
        set((state) => ({
          alerts: state.alerts.map((a) => (a.id === id ? { ...a, read: true } : a)),
        })),
      dismissAlert: (id) =>
        set((state) => ({
          alerts: state.alerts.filter((a) => a.id !== id),
        })),
      unreadCount: () => get().alerts.filter((a) => !a.read).length,
    }),
    { name: "globe-alerts" }
  )
);
