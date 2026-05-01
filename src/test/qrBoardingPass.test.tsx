import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import QRBoardingPass from "@/components/trip/QRBoardingPass";
import { useUserStore } from "@/store/userStore";

vi.mock("qrcode", () => ({
  default: { toCanvas: vi.fn().mockResolvedValue(undefined) },
}));

vi.mock("@/lib/boardingPass", () => ({
  issueBoardingPass: vi.fn().mockResolvedValue({
    payload: { passportLast4: "1234", iat: 0 },
    qrText: "globeid.bp.v1.test",
  }),
}));

vi.mock("@/utils/haptics", () => ({
  haptics: { success: vi.fn(), selection: vi.fn(), light: vi.fn() },
}));

vi.mock("sonner", () => ({
  toast: { success: vi.fn() },
}));

const baseProps = {
  passenger: "Devansh Barai",
  passportNo: "P12345678",
  flightNumber: "SQ 31",
  airline: "Singapore Airlines",
  fromIata: "SFO",
  toIata: "SIN",
  scheduledDate: "2026-03-10",
  legId: "leg-tr-f1",
  tripId: "tr-f1",
};

describe("<QRBoardingPass>", () => {
  beforeEach(() => {
    // Reset store between cases — `documents` is the only slice we touch.
    useUserStore.setState({ documents: [] });
    vi.clearAllMocks();
  });

  it("shows an Add to Wallet button when the pass is not yet saved", async () => {
    render(<QRBoardingPass {...baseProps} />);
    const btn = await screen.findByRole("button", {
      name: /add boarding pass to wallet/i,
    });
    expect(btn).toBeEnabled();
  });

  it("appends a boarding_pass document on click and disables the button", async () => {
    const { toast } = await import("sonner");
    render(<QRBoardingPass {...baseProps} />);
    const btn = await screen.findByRole("button", {
      name: /add boarding pass to wallet/i,
    });

    fireEvent.click(btn);

    await waitFor(() => {
      expect(useUserStore.getState().documents).toHaveLength(1);
    });

    const saved = useUserStore.getState().documents[0];
    expect(saved.id).toBe("bp-leg-tr-f1");
    expect(saved.type).toBe("boarding_pass");
    expect(saved.label).toBe("Singapore Airlines SQ 31");
    expect(saved.number).toBe("SQ 31");
    expect(saved.expiryDate).toBe("2026-03-10");
    expect(saved.status).toBe("active");
    expect(toast.success).toHaveBeenCalledWith(
      "Boarding pass saved to Wallet",
    );

    // The button now reflects the saved state.
    expect(
      screen.getByRole("button", { name: /already in wallet/i }),
    ).toBeDisabled();
  });

  it("is idempotent when the same legId is rendered twice", async () => {
    render(<QRBoardingPass {...baseProps} />);
    const btn = await screen.findByRole("button", {
      name: /add boarding pass to wallet/i,
    });
    fireEvent.click(btn);

    await waitFor(() => {
      expect(useUserStore.getState().documents).toHaveLength(1);
    });

    // A second click on the now-disabled button is a no-op.
    const disabled = screen.getByRole("button", {
      name: /already in wallet/i,
    });
    fireEvent.click(disabled);
    expect(useUserStore.getState().documents).toHaveLength(1);
  });
});
