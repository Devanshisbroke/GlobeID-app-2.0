/**
 * Slice-F — OCR preprocessing pipeline.
 *
 * Real image processing (pure JS, runs on Canvas2D) to lift Tesseract
 * hit-rate on document scans. Pipeline:
 *
 *   1. Downscale if wider than MAX_WIDTH (keeps WASM OCR fast).
 *   2. Grayscale (luminance-weighted, not naive average).
 *   3. Sobel edge magnitude — used for the crop ROI, not the OCR input.
 *   4. Largest-rect edge crop: horizontal/vertical edge-density scan
 *      finds the document bounds inside the frame.
 *   5. Otsu binarisation of the cropped grayscale so MRZ/printed text
 *      is pure black on white.
 *   6. Return the processed `Blob` (PNG) plus metadata.
 *
 * Everything is deterministic + testable — no random sampling.
 */

const MAX_WIDTH = 1600;
const CROP_EDGE_THRESHOLD = 32;
const CROP_DENSITY_THRESHOLD = 0.04;

export interface PreprocessResult {
  blob: Blob;
  width: number;
  height: number;
  elapsedMs: number;
  /** Bounds of the detected document within the source image. */
  roi: { x: number; y: number; w: number; h: number };
  /** % of edge pixels above CROP_EDGE_THRESHOLD (0–1). */
  edgeDensity: number;
}

export async function preprocessForOcr(input: Blob): Promise<PreprocessResult> {
  const t0 = performance.now();
  const img = await blobToImage(input);

  // 1. Downscale
  const scale = img.naturalWidth > MAX_WIDTH ? MAX_WIDTH / img.naturalWidth : 1;
  const w = Math.round(img.naturalWidth * scale);
  const h = Math.round(img.naturalHeight * scale);
  const src = drawToCanvas(img, w, h);
  const srcCtx = src.getContext("2d")!;
  const imgData = srcCtx.getImageData(0, 0, w, h);

  // 2. Grayscale
  const gray = toGrayscale(imgData);

  // 3. Sobel + 4. ROI
  const { magnitude, density } = sobel(gray, w, h);
  const roi = findDocumentRoi(magnitude, w, h);

  // Crop the grayscale buffer to ROI.
  const cropGray = cropGrayBuffer(gray, w, h, roi);

  // 5. Otsu binarisation
  const binarised = otsuBinarise(cropGray, roi.w, roi.h);

  // Paint into an output canvas for blob encoding.
  const out = new OffscreenCanvas(roi.w, roi.h);
  const outCtx = out.getContext("2d")!;
  const outData = outCtx.createImageData(roi.w, roi.h);
  for (let i = 0; i < binarised.length; i++) {
    const v = binarised[i]!;
    const j = i * 4;
    outData.data[j] = v;
    outData.data[j + 1] = v;
    outData.data[j + 2] = v;
    outData.data[j + 3] = 255;
  }
  outCtx.putImageData(outData, 0, 0);
  const blob = await out.convertToBlob({ type: "image/png" });

  return {
    blob,
    width: roi.w,
    height: roi.h,
    elapsedMs: performance.now() - t0,
    roi,
    edgeDensity: density,
  };
}

// ── Helpers ────────────────────────────────────────────────────

function blobToImage(blob: Blob): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.onload = () => {
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("image decode failed"));
    };
    img.src = url;
  });
}

function drawToCanvas(img: HTMLImageElement, w: number, h: number): HTMLCanvasElement {
  const c = document.createElement("canvas");
  c.width = w;
  c.height = h;
  const ctx = c.getContext("2d")!;
  ctx.drawImage(img, 0, 0, w, h);
  return c;
}

function toGrayscale(img: ImageData): Uint8ClampedArray {
  const { data, width, height } = img;
  const out = new Uint8ClampedArray(width * height);
  for (let i = 0, j = 0; i < data.length; i += 4, j++) {
    // ITU-R BT.601 luminance.
    out[j] = Math.round(
      0.299 * data[i]! + 0.587 * data[i + 1]! + 0.114 * data[i + 2]!,
    );
  }
  return out;
}

function sobel(
  gray: Uint8ClampedArray,
  w: number,
  h: number,
): { magnitude: Uint8ClampedArray; density: number } {
  const mag = new Uint8ClampedArray(w * h);
  let abovePix = 0;
  let total = 0;
  for (let y = 1; y < h - 1; y++) {
    for (let x = 1; x < w - 1; x++) {
      const i = y * w + x;
      const gx =
        -gray[i - w - 1]! -
        2 * gray[i - 1]! -
        gray[i + w - 1]! +
        gray[i - w + 1]! +
        2 * gray[i + 1]! +
        gray[i + w + 1]!;
      const gy =
        -gray[i - w - 1]! -
        2 * gray[i - w]! -
        gray[i - w + 1]! +
        gray[i + w - 1]! +
        2 * gray[i + w]! +
        gray[i + w + 1]!;
      const m = Math.min(255, Math.abs(gx) + Math.abs(gy));
      mag[i] = m;
      total += 1;
      if (m > CROP_EDGE_THRESHOLD) abovePix += 1;
    }
  }
  return { magnitude: mag, density: total ? abovePix / total : 0 };
}

function findDocumentRoi(
  mag: Uint8ClampedArray,
  w: number,
  h: number,
): { x: number; y: number; w: number; h: number } {
  // Column / row edge-density histograms. We want the tightest rectangle
  // that contains the bulk of strong edges (≈ the document).
  const colHist = new Float32Array(w);
  const rowHist = new Float32Array(h);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (mag[y * w + x]! > CROP_EDGE_THRESHOLD) {
        colHist[x]! += 1;
        rowHist[y]! += 1;
      }
    }
  }
  const colMax = Math.max(...colHist);
  const rowMax = Math.max(...rowHist);
  const colThresh = colMax * CROP_DENSITY_THRESHOLD;
  const rowThresh = rowMax * CROP_DENSITY_THRESHOLD;

  let x0 = 0;
  let x1 = w - 1;
  let y0 = 0;
  let y1 = h - 1;
  while (x0 < w - 1 && colHist[x0]! < colThresh) x0++;
  while (x1 > 0 && colHist[x1]! < colThresh) x1--;
  while (y0 < h - 1 && rowHist[y0]! < rowThresh) y0++;
  while (y1 > 0 && rowHist[y1]! < rowThresh) y1--;

  // Add a small margin, clamp to bounds.
  const mx = Math.round(w * 0.01);
  const my = Math.round(h * 0.01);
  x0 = Math.max(0, x0 - mx);
  x1 = Math.min(w - 1, x1 + mx);
  y0 = Math.max(0, y0 - my);
  y1 = Math.min(h - 1, y1 + my);

  const roiW = Math.max(1, x1 - x0 + 1);
  const roiH = Math.max(1, y1 - y0 + 1);
  // If we "detected" a ROI that's basically the whole frame, keep it.
  if (roiW < w * 0.2 || roiH < h * 0.2) {
    return { x: 0, y: 0, w, h };
  }
  return { x: x0, y: y0, w: roiW, h: roiH };
}

function cropGrayBuffer(
  gray: Uint8ClampedArray,
  w: number,
  _h: number,
  roi: { x: number; y: number; w: number; h: number },
): Uint8ClampedArray {
  const out = new Uint8ClampedArray(roi.w * roi.h);
  for (let y = 0; y < roi.h; y++) {
    const srcStart = (roi.y + y) * w + roi.x;
    out.set(gray.subarray(srcStart, srcStart + roi.w), y * roi.w);
  }
  return out;
}

/**
 * Otsu's method: choose the luminance threshold that maximises
 * between-class variance. Classical binarisation for OCR.
 */
function otsuBinarise(
  gray: Uint8ClampedArray,
  w: number,
  h: number,
): Uint8ClampedArray {
  const hist = new Array<number>(256).fill(0);
  for (let i = 0; i < gray.length; i++) hist[gray[i]!]! += 1;
  const total = w * h;
  let sumAll = 0;
  for (let i = 0; i < 256; i++) sumAll += i * hist[i]!;
  let sumB = 0;
  let wB = 0;
  let maxVar = 0;
  let threshold = 127;
  for (let t = 0; t < 256; t++) {
    wB += hist[t]!;
    if (wB === 0) continue;
    const wF = total - wB;
    if (wF === 0) break;
    sumB += t * hist[t]!;
    const mB = sumB / wB;
    const mF = (sumAll - sumB) / wF;
    const between = wB * wF * (mB - mF) * (mB - mF);
    if (between > maxVar) {
      maxVar = between;
      threshold = t;
    }
  }
  const out = new Uint8ClampedArray(gray.length);
  for (let i = 0; i < gray.length; i++) out[i] = gray[i]! > threshold ? 255 : 0;
  return out;
}
