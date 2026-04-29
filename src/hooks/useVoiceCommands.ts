/**
 * Slice-C — voice commands hook.
 *
 * Real speech recognition, not a fake:
 *  - On the web, uses the Web Speech API (`webkitSpeechRecognition` /
 *    `SpeechRecognition`). Available in Chrome / Edge / Safari; Firefox
 *    returns `supported: false` honestly.
 *  - On Capacitor native, uses `@capacitor-community/speech-recognition`.
 *
 * The hook is intentionally small — it surfaces `{ supported, listening,
 * transcript, start, stop }` and the caller decides what to do with the
 * parsed intent (navigate, dispatch a store action, etc.).
 *
 * Wake-word mode: if `wakeWord = true`, we only emit `onIntent` when the
 * transcript starts with "hey globe" (or "ok globe"). Otherwise every
 * transcript is parsed.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { Capacitor } from "@capacitor/core";
import { parseIntent, stripWakeWord, type VoiceIntent } from "@/lib/voiceIntents";

// --- Web Speech API typings -----------------------------------------------
// The TS DOM lib doesn't ship `SpeechRecognition` yet. We declare the tiny
// subset we use to avoid `any` in application code.
interface WebSpeechRecognitionEvent extends Event {
  readonly resultIndex: number;
  readonly results: {
    length: number;
    [index: number]: {
      readonly length: number;
      [index: number]: { readonly transcript: string };
      isFinal: boolean;
    };
  };
}
interface WebSpeechRecognition extends EventTarget {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  onresult: ((ev: WebSpeechRecognitionEvent) => void) | null;
  onerror: ((ev: Event) => void) | null;
  onend: (() => void) | null;
  start(): void;
  stop(): void;
}
type WebSpeechCtor = new () => WebSpeechRecognition;

declare global {
  interface Window {
    SpeechRecognition?: WebSpeechCtor;
    webkitSpeechRecognition?: WebSpeechCtor;
  }
}

// --- Lazy native import ---------------------------------------------------
type NativeSR = {
  available: () => Promise<{ available: boolean }>;
  requestPermissions: () => Promise<unknown>;
  checkPermissions: () => Promise<{ speechRecognition: string }>;
  start: (opts: {
    language: string;
    partialResults: boolean;
    popup: boolean;
    prompt?: string;
  }) => Promise<{ matches?: string[] }>;
  stop: () => Promise<void>;
  addListener: (
    event: string,
    cb: (val: { matches?: string[]; value?: string[] }) => void,
  ) => Promise<{ remove: () => Promise<void> }>;
};

async function loadNativeSR(): Promise<NativeSR | null> {
  if (!Capacitor.isNativePlatform()) return null;
  try {
    const mod = (await import("@capacitor-community/speech-recognition")) as {
      SpeechRecognition: NativeSR;
    };
    return mod.SpeechRecognition;
  } catch {
    return null;
  }
}

// --- Hook -----------------------------------------------------------------

export interface UseVoiceOptions {
  language?: string;
  wakeWord?: boolean;
  continuous?: boolean;
  onIntent?: (intent: VoiceIntent) => void;
}

export interface UseVoiceResult {
  supported: boolean;
  listening: boolean;
  permission: "granted" | "denied" | "prompt" | "unknown";
  transcript: string;
  lastIntent: VoiceIntent | null;
  start: () => Promise<void>;
  stop: () => Promise<void>;
}

function getWebRecognitionCtor(): WebSpeechCtor | null {
  if (typeof window === "undefined") return null;
  return window.SpeechRecognition ?? window.webkitSpeechRecognition ?? null;
}

export function useVoiceCommands(opts: UseVoiceOptions = {}): UseVoiceResult {
  const { language = "en-US", wakeWord = false, continuous = false, onIntent } = opts;
  const [supported, setSupported] = useState(false);
  const [listening, setListening] = useState(false);
  const [permission, setPermission] = useState<UseVoiceResult["permission"]>("unknown");
  const [transcript, setTranscript] = useState("");
  const [lastIntent, setLastIntent] = useState<VoiceIntent | null>(null);

  const webRef = useRef<WebSpeechRecognition | null>(null);
  const nativeRef = useRef<NativeSR | null>(null);
  const onIntentRef = useRef(onIntent);
  onIntentRef.current = onIntent;

  useEffect(() => {
    let cancelled = false;
    (async () => {
      if (Capacitor.isNativePlatform()) {
        const sr = await loadNativeSR();
        if (cancelled) return;
        if (!sr) {
          setSupported(false);
          return;
        }
        nativeRef.current = sr;
        try {
          const avail = await sr.available();
          setSupported(avail.available);
          const perm = await sr.checkPermissions();
          setPermission(perm.speechRecognition === "granted" ? "granted" : "prompt");
        } catch {
          setSupported(false);
        }
      } else {
        const Ctor = getWebRecognitionCtor();
        if (!Ctor) {
          setSupported(false);
          return;
        }
        setSupported(true);
        setPermission("prompt");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const handleTranscript = useCallback(
    (text: string) => {
      setTranscript(text);
      let effective: string | null = text;
      if (wakeWord) effective = stripWakeWord(text);
      if (effective === null || !effective) return;
      const intent = parseIntent(effective);
      setLastIntent(intent);
      onIntentRef.current?.(intent);
    },
    [wakeWord],
  );

  const start = useCallback(async () => {
    if (Capacitor.isNativePlatform()) {
      const sr = nativeRef.current;
      if (!sr) return;
      try {
        await sr.requestPermissions();
        const perm = await sr.checkPermissions();
        setPermission(perm.speechRecognition === "granted" ? "granted" : "denied");
        if (perm.speechRecognition !== "granted") return;
        setListening(true);
        const result = await sr.start({
          language,
          partialResults: false,
          popup: false,
        });
        setListening(false);
        const best = result.matches?.[0];
        if (best) handleTranscript(best);
      } catch {
        setListening(false);
      }
      return;
    }

    const Ctor = getWebRecognitionCtor();
    if (!Ctor) return;
    const rec = new Ctor();
    webRef.current = rec;
    rec.lang = language;
    rec.continuous = continuous;
    rec.interimResults = false;
    rec.onresult = (ev) => {
      let text = "";
      for (let i = ev.resultIndex; i < ev.results.length; i++) {
        text += ev.results[i][0].transcript;
      }
      handleTranscript(text);
    };
    rec.onerror = (ev) => {
      // The web API reports "not-allowed" as an error, not a permission API call.
      const err = ev as Event & { error?: string };
      if (err.error === "not-allowed") setPermission("denied");
      setListening(false);
    };
    rec.onend = () => {
      setListening(false);
    };
    try {
      rec.start();
      setListening(true);
      setPermission("granted");
    } catch {
      setListening(false);
    }
  }, [continuous, language, handleTranscript]);

  const stop = useCallback(async () => {
    if (Capacitor.isNativePlatform()) {
      try {
        await nativeRef.current?.stop();
      } catch {
        // ignore
      }
    } else {
      try {
        webRef.current?.stop();
      } catch {
        // ignore
      }
    }
    setListening(false);
  }, []);

  return {
    supported,
    listening,
    permission,
    transcript,
    lastIntent,
    start,
    stop,
  };
}
