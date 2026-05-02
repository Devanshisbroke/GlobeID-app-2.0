import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import AnimatedNumber from "@/components/ui/AnimatedNumber";

function mockMatchMedia(reduced: boolean) {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    configurable: true,
    value: () => ({
      matches: reduced,
      media: "",
      onchange: null,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }),
  });
}

describe("<AnimatedNumber>", () => {
  beforeEach(() => mockMatchMedia(true));

  it("renders the formatted value with prefix/suffix", () => {
    render(
      <AnimatedNumber
        value={1234.5}
        decimals={2}
        prefix="$"
        suffix=" USD"
        ariaLabel="balance"
      />,
    );
    expect(screen.getByText("$1,234.50 USD")).toBeInTheDocument();
  });

  it("respects 0 decimals (integer balance)", () => {
    render(<AnimatedNumber value={42} decimals={0} ariaLabel="count" />);
    expect(screen.getByText("42")).toBeInTheDocument();
  });

  it("exposes a stable aria-label that includes the final value", () => {
    render(
      <AnimatedNumber
        value={9.99}
        decimals={2}
        prefix="$"
        ariaLabel="cost is $9.99"
      />,
    );
    expect(screen.getByLabelText("cost is $9.99")).toBeInTheDocument();
  });
});
