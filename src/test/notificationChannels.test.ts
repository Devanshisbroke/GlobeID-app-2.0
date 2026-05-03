import { afterEach, describe, it, expect, beforeEach } from "vitest";
import {
  NOTIFICATION_CHANNELS,
  DEFAULT_CHANNEL_PREFS,
  getChannelPrefs,
  setChannelPref,
  isChannelEnabled,
} from "@/lib/notificationChannels";

describe("notificationChannels", () => {
  beforeEach(() => {
    try {
      localStorage.clear();
    } catch {
      /* ignore */
    }
  });

  afterEach(() => {
    try {
      localStorage.clear();
    } catch {
      /* ignore */
    }
  });

  it("returns defaults when nothing persisted", () => {
    expect(getChannelPrefs()).toEqual(DEFAULT_CHANNEL_PREFS);
  });

  it("setChannelPref persists and isChannelEnabled reflects it", () => {
    setChannelPref("docExpiry", false);
    expect(isChannelEnabled("docExpiry")).toBe(false);
    expect(isChannelEnabled("weeklyDigest")).toBe(true);
  });

  it("partial persisted state is merged with defaults", () => {
    localStorage.setItem(
      "globeid:notificationChannels",
      JSON.stringify({ docExpiry: false }),
    );
    const prefs = getChannelPrefs();
    expect(prefs.docExpiry).toBe(false);
    // Other channels stay at default true.
    expect(prefs.weeklyDigest).toBe(true);
  });

  it("invalid JSON falls back to defaults", () => {
    localStorage.setItem("globeid:notificationChannels", "not-json");
    expect(getChannelPrefs()).toEqual(DEFAULT_CHANNEL_PREFS);
  });

  it("all canonical channels are listed", () => {
    expect(NOTIFICATION_CHANNELS).toContain("docExpiry");
    expect(NOTIFICATION_CHANNELS).toContain("weeklyDigest");
  });
});
