/**
 * Lightweight QR Code SVG generator.
 * Uses a simplified encoding for demo purposes — produces a visual QR-like grid
 * from the input string. For production, swap with a proper QR library.
 */

function hashCode(str: string): number {
  let h = 0;
  for (let i = 0; i < str.length; i++) {
    h = ((h << 5) - h + str.charCodeAt(i)) | 0;
  }
  return h;
}

function seededRandom(seed: number) {
  let s = seed;
  return () => {
    s = (s * 16807 + 0) % 2147483647;
    return (s - 1) / 2147483646;
  };
}

/**
 * Generate a QR-like SVG string from data.
 * This is a visual simulation — for real QR encoding, use a proper library.
 */
export function generateQRSvg(data: string, size = 200, moduleCount = 25): string {
  const seed = hashCode(data);
  const rand = seededRandom(Math.abs(seed));
  const cellSize = size / moduleCount;
  
  const modules: boolean[][] = Array.from({ length: moduleCount }, () =>
    Array.from({ length: moduleCount }, () => false)
  );

  // Finder patterns (top-left, top-right, bottom-left)
  const drawFinder = (ox: number, oy: number) => {
    for (let y = 0; y < 7; y++) {
      for (let x = 0; x < 7; x++) {
        const isOuter = y === 0 || y === 6 || x === 0 || x === 6;
        const isInner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        if (isOuter || isInner) {
          modules[oy + y][ox + x] = true;
        }
      }
    }
  };

  drawFinder(0, 0);
  drawFinder(moduleCount - 7, 0);
  drawFinder(0, moduleCount - 7);

  // Timing patterns
  for (let i = 8; i < moduleCount - 8; i++) {
    modules[6][i] = i % 2 === 0;
    modules[i][6] = i % 2 === 0;
  }

  // Data area — seeded from input
  for (let y = 0; y < moduleCount; y++) {
    for (let x = 0; x < moduleCount; x++) {
      // Skip finder + timing zones
      if ((x < 8 && y < 8) || (x >= moduleCount - 7 && y < 8) || (x < 8 && y >= moduleCount - 7)) continue;
      if (x === 6 || y === 6) continue;
      modules[y][x] = rand() > 0.5;
    }
  }

  // Build SVG
  let rects = "";
  for (let y = 0; y < moduleCount; y++) {
    for (let x = 0; x < moduleCount; x++) {
      if (modules[y][x]) {
        const rx = x * cellSize;
        const ry = y * cellSize;
        rects += `<rect x="${rx.toFixed(1)}" y="${ry.toFixed(1)}" width="${cellSize.toFixed(1)}" height="${cellSize.toFixed(1)}" rx="0.5"/>`;
      }
    }
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${size} ${size}" width="${size}" height="${size}">
    <rect width="${size}" height="${size}" fill="white" rx="8"/>
    <g fill="currentColor">${rects}</g>
  </svg>`;
}
