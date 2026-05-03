import React, { useEffect, useRef } from "react";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import { useTripNotesStore } from "@/store/tripNotesStore";

/**
 * TripNotesEditor — Tiptap (ProseMirror) backed rich-text editor.
 * Persists per-trip notes to `tripNotesStore`. Code-split via a
 * `React.lazy` boundary in `<TripNotes />` so this editor + Tiptap
 * core only ship when the user opens a trip detail.
 *
 * Toolbar surfaces the most-used commands (bold, italic, h2, list,
 * ordered list). All commands have ≥44px hit targets, focus rings
 * and `aria-pressed` for the active state.
 */
const TripNotesEditor: React.FC<{ tripId: string }> = ({ tripId }) => {
  const initial = useTripNotesStore.getState().getNote(tripId);
  const setNote = useTripNotesStore((s) => s.setNote);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [2, 3] },
      }),
    ],
    content:
      initial ??
      {
        type: "doc",
        content: [
          {
            type: "paragraph",
            content: [
              {
                type: "text",
                text: "Things to remember, packing reminders, contacts…",
              },
            ],
          },
        ],
      },
    editorProps: {
      attributes: {
        class:
          "tiptap-editor min-h-[120px] outline-none px-3 py-3 text-[14px] text-foreground prose prose-sm max-w-none dark:prose-invert focus:outline-none",
        spellcheck: "true",
        "aria-label": "Trip notes",
      },
    },
    onUpdate({ editor: ed }) {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => {
        setNote(tripId, ed.getJSON());
      }, 350);
    },
  });

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []);

  if (!editor) {
    return (
      <div
        className="rounded-2xl border border-border bg-card min-h-[120px] flex items-center justify-center text-muted-foreground text-[12px]"
        aria-busy
      >
        Loading editor…
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-border bg-card overflow-hidden">
      <Toolbar editor={editor} />
      <EditorContent editor={editor} />
    </div>
  );
};

interface TiptapEditor {
  isActive: (name: string, attrs?: Record<string, unknown>) => boolean;
  chain: () => {
    focus: () => {
      toggleBold: () => { run: () => boolean };
      toggleItalic: () => { run: () => boolean };
      toggleHeading: (attrs: { level: number }) => { run: () => boolean };
      toggleBulletList: () => { run: () => boolean };
      toggleOrderedList: () => { run: () => boolean };
    };
  };
}

const Toolbar: React.FC<{ editor: TiptapEditor }> = ({ editor }) => {
  const btnCls = (active: boolean) =>
    `min-h-[44px] min-w-[44px] px-2.5 inline-flex items-center justify-center text-[12px] font-semibold tracking-tight rounded-md focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] ${
      active
        ? "bg-[hsl(var(--p7-brand)/0.18)] text-[hsl(var(--p7-brand))]"
        : "text-muted-foreground hover:bg-surface-overlay/40"
    }`;

  return (
    <div className="flex flex-wrap items-center gap-1 border-b border-border/40 px-2 py-1.5 bg-surface-overlay/30">
      <button
        type="button"
        aria-pressed={editor.isActive("bold")}
        onClick={() => editor.chain().focus().toggleBold().run()}
        className={btnCls(editor.isActive("bold"))}
      >
        B
      </button>
      <button
        type="button"
        aria-pressed={editor.isActive("italic")}
        onClick={() => editor.chain().focus().toggleItalic().run()}
        className={btnCls(editor.isActive("italic"))}
      >
        <span className="italic">I</span>
      </button>
      <span className="w-px h-5 bg-border/60 mx-1" aria-hidden />
      <button
        type="button"
        aria-pressed={editor.isActive("heading", { level: 2 })}
        onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        className={btnCls(editor.isActive("heading", { level: 2 }))}
      >
        H2
      </button>
      <button
        type="button"
        aria-pressed={editor.isActive("heading", { level: 3 })}
        onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
        className={btnCls(editor.isActive("heading", { level: 3 }))}
      >
        H3
      </button>
      <span className="w-px h-5 bg-border/60 mx-1" aria-hidden />
      <button
        type="button"
        aria-pressed={editor.isActive("bulletList")}
        onClick={() => editor.chain().focus().toggleBulletList().run()}
        className={btnCls(editor.isActive("bulletList"))}
      >
        •
      </button>
      <button
        type="button"
        aria-pressed={editor.isActive("orderedList")}
        onClick={() => editor.chain().focus().toggleOrderedList().run()}
        className={btnCls(editor.isActive("orderedList"))}
      >
        1.
      </button>
    </div>
  );
};

export default TripNotesEditor;
