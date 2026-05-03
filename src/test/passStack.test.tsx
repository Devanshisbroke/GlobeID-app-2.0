import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import PassStack from "@/components/wallet/PassStack";
import type { TravelDocument } from "@/store/userStore";

// PassStack uses useNavigate for the empty-state CTA — wrap every
// render in a MemoryRouter so the hook resolves a real router context.
const renderWithRouter = (ui: React.ReactNode) =>
  render(<MemoryRouter>{ui}</MemoryRouter>);

vi.mock("@/utils/haptics", () => ({
  haptics: {
    selection: vi.fn(),
    light: vi.fn(),
    medium: vi.fn(),
    heavy: vi.fn(),
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
}));

vi.mock("@/components/wallet/PassDetail", () => ({
  default: () => <div data-testid="pass-detail" />,
}));

const passport: TravelDocument = {
  id: "p1",
  type: "passport",
  label: "US Passport",
  country: "United States",
  countryFlag: "🇺🇸",
  number: "P123456",
  issueDate: "2020-01-01",
  expiryDate: "2030-01-01",
  status: "active",
};

const boardingSQ: TravelDocument = {
  id: "bp-sq31",
  type: "boarding_pass",
  label: "SQ31 SFO→SIN",
  country: "Singapore",
  countryFlag: "🇸🇬",
  number: "SQ31-AX7K",
  issueDate: "2026-03-01",
  expiryDate: "2026-03-12",
  status: "active",
};

describe("<PassStack>", () => {
  beforeEach(() => vi.clearAllMocks());

  it("renders the empty-state when no documents are provided", () => {
    renderWithRouter(<PassStack documents={[]} />);
    expect(screen.getByText(/No travel documents yet/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /Scan a document/i }),
    ).toBeInTheDocument();
  });

  it("renders the lead document's label when documents are present", () => {
    renderWithRouter(<PassStack documents={[passport]} />);
    expect(screen.getByText(/US Passport/)).toBeInTheDocument();
  });

  it("renders multiple documents (lead + peeks)", () => {
    renderWithRouter(<PassStack documents={[passport, boardingSQ]} />);
    expect(screen.getByText(/US Passport/)).toBeInTheDocument();
    expect(screen.getByText(/SQ31 SFO→SIN/)).toBeInTheDocument();
  });
});
