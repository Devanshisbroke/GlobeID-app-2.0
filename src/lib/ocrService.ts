/**
 * Slice-D — Tesseract.js OCR service.
 *
 * Thin wrapper that lazy-imports tesseract.js (large) so the main bundle
 * isn't bloated for users who never scan anything. The worker is kept
 * alive between calls to amortise the (expensive) init cost.
 *
 * API:
 *   - `ocrImage(blob)` → `{ text, confidence, elapsedMs }`
 *   - `terminateOcr()` → tears down the worker (call on unmount of the
 *     scanner screen to free 20+ MB of heap).
 */

type OcrWorker = {
  recognize: (img: Blob | string) => Promise<{
    data: { text: string; confidence: number };
  }>;
  terminate: () => Promise<void>;
};

let workerPromise: Promise<OcrWorker> | null = null;

async function getWorker(): Promise<OcrWorker> {
  if (workerPromise) return workerPromise;
  workerPromise = (async () => {
    const mod = (await import("tesseract.js")) as {
      createWorker: (lang: string) => Promise<OcrWorker>;
    };
    return mod.createWorker("eng");
  })();
  return workerPromise;
}

export interface OcrResult {
  text: string;
  confidence: number;
  elapsedMs: number;
}

export async function ocrImage(blob: Blob): Promise<OcrResult> {
  const t0 = performance.now();
  const worker = await getWorker();
  const { data } = await worker.recognize(blob);
  return {
    text: data.text,
    confidence: data.confidence,
    elapsedMs: performance.now() - t0,
  };
}

export async function terminateOcr(): Promise<void> {
  if (!workerPromise) return;
  const w = await workerPromise;
  await w.terminate();
  workerPromise = null;
}
