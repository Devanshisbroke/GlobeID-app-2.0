/**
 * Slice-D — encrypted document vault (IndexedDB + AES-GCM).
 *
 * Design:
 *  - IndexedDB store: `documents` with auto-incrementing numeric `id`.
 *  - Each row stores `{ id, classified, classifiedKind, ciphertext, iv,
 *    createdAt, updatedAt, ocrExcerpt }`. `ciphertext` holds the
 *    AES-GCM-encrypted image blob (the PNG or JPEG the user scanned).
 *    `ocrExcerpt` is a deliberately-truncated plaintext preview for the
 *    list UI — no MRZ / passport numbers / names.
 *  - Key: AES-GCM 256, derived from a passphrase (PBKDF2 200k rounds +
 *    static app-salt). Passphrase is the user's `kioskPin` by default
 *    (reuses existing identity state); it's never persisted anywhere.
 *  - No key escrow: if the pin is wrong, decryption fails. That's the
 *    whole point.
 *
 * This module is async-only. The underlying `idb` library gives us a
 * friendly Promise API over IndexedDB with typed stores.
 */
import { openDB, type IDBPDatabase } from "idb";

export type DocumentKind = "passport" | "visa" | "id_card" | "unknown";

export interface VaultDocument {
  id?: number;
  kind: DocumentKind;
  label: string;
  /** Encrypted image ciphertext (AES-GCM). */
  ciphertext: ArrayBuffer;
  /** Random 12-byte IV for this blob. */
  iv: Uint8Array;
  createdAt: number;
  updatedAt: number;
  /** Non-sensitive OCR preview (first 60 chars, MRZ lines stripped). */
  ocrExcerpt: string;
}

export interface VaultDocumentSummary {
  id: number;
  kind: DocumentKind;
  label: string;
  createdAt: number;
  ocrExcerpt: string;
}

const DB_NAME = "globe-doc-vault";
const DB_VERSION = 1;
const STORE = "documents";
const SALT = new Uint8Array([0x47, 0x4c, 0x4f, 0x42, 0x45, 0x56, 0x41, 0x55, 0x4c, 0x54, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]);
const KDF_ITERATIONS = 200_000;

let dbPromise: Promise<IDBPDatabase> | null = null;

function getDb(): Promise<IDBPDatabase> {
  if (!dbPromise) {
    dbPromise = openDB(DB_NAME, DB_VERSION, {
      upgrade(db) {
        if (!db.objectStoreNames.contains(STORE)) {
          db.createObjectStore(STORE, { keyPath: "id", autoIncrement: true });
        }
      },
    });
  }
  return dbPromise;
}

async function deriveKey(passphrase: string): Promise<CryptoKey> {
  const enc = new TextEncoder().encode(passphrase);
  const baseKey = await crypto.subtle.importKey("raw", enc, "PBKDF2", false, ["deriveKey"]);
  return crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: SALT,
      iterations: KDF_ITERATIONS,
      hash: "SHA-256",
    },
    baseKey,
    { name: "AES-GCM", length: 256 },
    false,
    ["encrypt", "decrypt"],
  );
}

export async function saveDocument(
  passphrase: string,
  input: {
    kind: DocumentKind;
    label: string;
    imageBlob: Blob;
    ocrText: string;
  },
): Promise<number> {
  const key = await deriveKey(passphrase);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const buffer = await input.imageBlob.arrayBuffer();
  const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, buffer);
  const now = Date.now();
  const db = await getDb();
  const excerpt = input.ocrText
    .split(/\n/)
    .filter((l) => !/^[A-Z0-9<]{25,}$/.test(l.replace(/\s/g, "")))
    .join(" ")
    .replace(/\s+/g, " ")
    .slice(0, 60);
  const row: VaultDocument = {
    kind: input.kind,
    label: input.label,
    ciphertext,
    iv,
    createdAt: now,
    updatedAt: now,
    ocrExcerpt: excerpt,
  };
  const id = await db.add(STORE, row);
  return id as number;
}

export async function listDocuments(): Promise<VaultDocumentSummary[]> {
  const db = await getDb();
  const rows = (await db.getAll(STORE)) as VaultDocument[];
  return rows
    .map((r) => ({
      id: r.id!,
      kind: r.kind,
      label: r.label,
      createdAt: r.createdAt,
      ocrExcerpt: r.ocrExcerpt,
    }))
    .sort((a, b) => b.createdAt - a.createdAt);
}

/**
 * Decrypt the raw image blob. Throws on wrong passphrase — WebCrypto
 * treats authentication failures as a rejected promise.
 */
export async function revealDocument(
  passphrase: string,
  id: number,
): Promise<{ kind: DocumentKind; label: string; blob: Blob; createdAt: number } | null> {
  const db = await getDb();
  const row = (await db.get(STORE, id)) as VaultDocument | undefined;
  if (!row) return null;
  const key = await deriveKey(passphrase);
  const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv: row.iv }, key, row.ciphertext);
  return {
    kind: row.kind,
    label: row.label,
    blob: new Blob([plaintext], { type: "image/jpeg" }),
    createdAt: row.createdAt,
  };
}

export async function deleteDocument(id: number): Promise<void> {
  const db = await getDb();
  await db.delete(STORE, id);
}

/** Test-only helper — resets the DB. */
export async function _resetVault(): Promise<void> {
  if (dbPromise) {
    const db = await dbPromise;
    db.close();
    dbPromise = null;
  }
  await new Promise<void>((resolve, reject) => {
    const req = indexedDB.deleteDatabase(DB_NAME);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}
