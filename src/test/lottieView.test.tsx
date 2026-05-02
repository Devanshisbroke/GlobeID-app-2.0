import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import LottieView from "@/components/animations/LottieView";

vi.mock("lottie-react", () => ({
  __esModule: true,
  default: () => <div data-testid="lottie-real" />,
}));

function mockMatchMedia(reduced: boolean) {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    configurable: true,
    value: (query: string) => ({
      matches: query.includes("reduce") ? reduced : false,
      media: query,
      onchange: null,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }),
  });
}

describe("<LottieView>", () => {
  beforeEach(() => {
    mockMatchMedia(false);
  });

  it("renders the lottie component when reduced motion is OFF", async () => {
    mockMatchMedia(false);
    render(
      <LottieView
        data={{}}
        fallback={<span data-testid="fb">fallback</span>}
        ariaLabel="test"
      />,
    );
    // Lazy import resolves async; await tick
    expect(await screen.findByTestId("lottie-real")).toBeInTheDocument();
  });

  it("renders ONLY the static fallback when reduced motion is ON", () => {
    mockMatchMedia(true);
    render(
      <LottieView
        data={{}}
        fallback={<span data-testid="fb">fallback</span>}
        ariaLabel="test"
      />,
    );
    expect(screen.getByTestId("fb")).toBeInTheDocument();
    expect(screen.queryByTestId("lottie-real")).toBeNull();
  });

  it("applies role=img + aria-label when ariaLabel is set", () => {
    mockMatchMedia(true); // simpler: avoids waiting for lazy load
    render(
      <LottieView
        data={{}}
        fallback={<span>fb</span>}
        ariaLabel="document saved"
      />,
    );
    expect(screen.getByRole("img", { name: "document saved" })).toBeInTheDocument();
  });
});
