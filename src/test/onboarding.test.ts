import { beforeEach, describe, expect, it } from "vitest";
import { hasCompletedOnboarding, markOnboardingComplete } from "@/lib/onboarding";

describe("onboarding flag", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("is false on a fresh install", () => {
    expect(hasCompletedOnboarding()).toBe(false);
  });

  it("flips to true after markOnboardingComplete", () => {
    markOnboardingComplete();
    expect(hasCompletedOnboarding()).toBe(true);
  });

  it("persists across repeated reads", () => {
    markOnboardingComplete();
    expect(hasCompletedOnboarding()).toBe(true);
    expect(hasCompletedOnboarding()).toBe(true);
  });
});
