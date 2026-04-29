/**
 * Slice-F — receipt renderer.
 *
 * Takes a wallet transaction (and optionally the user profile) and emits
 * a printable PDF via `jspdf`. The layout is deliberately austere — a
 * branded header, key/value rows, a monospaced reference footer — so
 * the output reads like an actual payment receipt, not a screenshot.
 *
 * Design:
 *  - Pure function except for the final `jspdf` instantiation, which
 *    must run in a browser (document/Blob APIs). The line-by-line layout
 *    helpers are pure and testable.
 */
import type { WalletTransaction } from "@shared/types/wallet";

export interface ReceiptMeta {
  holderName: string;
  holderEmail?: string;
  issuedBy?: string;
}

export interface ReceiptRow {
  label: string;
  value: string;
}

/** Build the semantic rows for a receipt. Pure — no IO. */
export function buildReceiptRows(
  tx: WalletTransaction,
  meta: ReceiptMeta,
): ReceiptRow[] {
  const abs = Math.abs(tx.amount);
  const direction = tx.amount >= 0 ? "Credit" : "Debit";
  const rows: ReceiptRow[] = [
    { label: "Transaction ID", value: tx.id },
    { label: "Type", value: tx.type.toUpperCase() },
    { label: "Direction", value: direction },
    { label: "Description", value: tx.description },
    {
      label: "Amount",
      value: `${tx.currency} ${abs.toFixed(2)}`,
    },
    { label: "Category", value: tx.category },
    { label: "Date", value: tx.date },
    { label: "Holder", value: meta.holderName },
  ];
  if (tx.merchant) rows.push({ label: "Merchant", value: tx.merchant });
  if (tx.location) rows.push({ label: "Location", value: tx.location });
  if (tx.country) rows.push({ label: "Country", value: tx.country });
  if (tx.reference) rows.push({ label: "Reference", value: tx.reference });
  if (meta.holderEmail) rows.push({ label: "Email", value: meta.holderEmail });
  rows.push({
    label: "Issued by",
    value: meta.issuedBy ?? "GlobeID",
  });
  rows.push({ label: "Issued at", value: new Date().toISOString() });
  return rows;
}

/**
 * Render to a PDF Blob. Lazy-loads jspdf so it doesn't inflate the
 * initial bundle (users who never download a receipt never pay the
 * ~400 KB cost).
 */
export async function renderReceiptPdf(
  tx: WalletTransaction,
  meta: ReceiptMeta,
): Promise<Blob> {
  const rows = buildReceiptRows(tx, meta);
  const jsPdfMod = await import("jspdf");
  const jsPDFCtor = jsPdfMod.jsPDF ?? (jsPdfMod as unknown as { default: typeof jsPdfMod.jsPDF }).default;
  const doc = new jsPDFCtor({ unit: "pt", format: "a5" });

  // Header
  doc.setFont("helvetica", "bold");
  doc.setFontSize(22);
  doc.text("GlobeID", 32, 48);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  doc.text("Digital payment receipt", 32, 64);

  // Separator
  doc.setDrawColor(200);
  doc.line(32, 74, 388, 74);

  // Body
  doc.setFontSize(11);
  let y = 96;
  for (const row of rows) {
    doc.setFont("helvetica", "bold");
    doc.text(row.label, 32, y);
    doc.setFont("helvetica", "normal");
    // Wrap long values (rare but possible — descriptions)
    const text = doc.splitTextToSize(row.value, 220) as string[];
    doc.text(text, 160, y);
    y += 14 * text.length + 2;
  }

  // Footer
  doc.setDrawColor(200);
  doc.line(32, y + 8, 388, y + 8);
  doc.setFont("courier", "normal");
  doc.setFontSize(9);
  doc.text(
    `ref://${tx.id}  •  ${tx.currency}  •  ${tx.date}`,
    32,
    y + 28,
  );

  const out = doc.output("blob");
  return out;
}

/** Kick a download of the receipt in the browser. */
export async function downloadReceipt(
  tx: WalletTransaction,
  meta: ReceiptMeta,
): Promise<void> {
  const blob = await renderReceiptPdf(tx, meta);
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `receipt-${tx.id}.pdf`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}
