import { describe, it, expect, beforeEach } from "vitest";
import {
  runNightlyDocExpiryCheck,
  runWeeklyDigest,
  _resetScheduledJobs,
} from "@/core/scheduledJobs";
import { useUserStore } from "@/store/userStore";
import { useAlertsStore } from "@/store/alertsStore";
import { useWalletStore } from "@/store/walletStore";

const NOW = new Date("2026-03-09T12:00:00Z").getTime();

beforeEach(() => {
  _resetScheduledJobs();
  // Reset alerts to empty (start fresh).
  useAlertsStore.setState({
    alerts: [],
    pendingMutations: [],
    syncStatus: "idle",
    lastHydratedAt: null,
  });
});

describe("runNightlyDocExpiryCheck", () => {
  it("pushes a high-severity alert for a critically expiring doc", () => {
    useUserStore.setState({
      documents: [
        {
          id: "p1",
          type: "passport",
          label: "Passport",
          country: "US",
          countryFlag: "🇺🇸",
          number: "P-1",
          issueDate: "2020-01-01",
          expiryDate: "2026-03-12",
          status: "active",
        },
      ],
    } as Partial<ReturnType<typeof useUserStore.getState>>);
    runNightlyDocExpiryCheck(NOW);
    const alerts = useAlertsStore.getState().alerts;
    expect(alerts.length).toBe(1);
    expect(alerts[0]?.severity).toBe("high");
    expect(alerts[0]?.title).toContain("Passport");
  });

  it("does not push when nothing expires soon", () => {
    useUserStore.setState({
      documents: [
        {
          id: "p1",
          type: "passport",
          label: "Passport",
          country: "US",
          countryFlag: "🇺🇸",
          number: "P-1",
          issueDate: "2020-01-01",
          expiryDate: "2030-01-01",
          status: "active",
        },
      ],
    } as Partial<ReturnType<typeof useUserStore.getState>>);
    runNightlyDocExpiryCheck(NOW);
    expect(useAlertsStore.getState().alerts.length).toBe(0);
  });

  it("is idempotent on re-run with same data", () => {
    useUserStore.setState({
      documents: [
        {
          id: "p1",
          type: "passport",
          label: "Passport",
          country: "US",
          countryFlag: "🇺🇸",
          number: "P-1",
          issueDate: "2020-01-01",
          expiryDate: "2026-03-12",
          status: "active",
        },
      ],
    } as Partial<ReturnType<typeof useUserStore.getState>>);
    runNightlyDocExpiryCheck(NOW);
    runNightlyDocExpiryCheck(NOW);
    runNightlyDocExpiryCheck(NOW);
    expect(useAlertsStore.getState().alerts.length).toBe(1);
  });
});

describe("runWeeklyDigest", () => {
  it("emits a digest when there's activity", () => {
    useUserStore.setState({
      travelHistory: [
        {
          id: "t1",
          from: "SFO",
          to: "SIN",
          date: "2026-03-12",
          airline: "Singapore Airlines",
          duration: "18h",
          type: "upcoming",
          source: "history",
        },
      ],
    } as Partial<ReturnType<typeof useUserStore.getState>>);
    useWalletStore.setState({
      transactions: [],
    } as Partial<ReturnType<typeof useWalletStore.getState>>);
    runWeeklyDigest(NOW);
    const alerts = useAlertsStore.getState().alerts;
    expect(alerts.some((a) => a.title === "Weekly digest")).toBe(true);
  });

  it("emits nothing when there's no activity at all", () => {
    useUserStore.setState({
      travelHistory: [],
    } as Partial<ReturnType<typeof useUserStore.getState>>);
    useWalletStore.setState({
      transactions: [],
    } as Partial<ReturnType<typeof useWalletStore.getState>>);
    runWeeklyDigest(NOW);
    const titles = useAlertsStore
      .getState()
      .alerts.map((a) => a.title);
    expect(titles).not.toContain("Weekly digest");
  });
});
