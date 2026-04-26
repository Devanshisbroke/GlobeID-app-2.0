import * as React from "react";
import * as LabelPrimitive from "@radix-ui/react-label";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

/**
 * Field — labelled input wrapper.
 *
 * `<Field label="…" hint="…" error="…">` composes:
 *  - A semantic `<Label>` linked via `htmlFor`
 *  - The control (Input / Textarea / Select / custom)
 *  - An optional hint or error message under the control
 *
 * The Input + Textarea here are the bare textbox primitives; the Field
 * shell provides the visual frame (label, hint, error). This split is
 * deliberate — composing this way means custom controls (date pickers,
 * masked inputs, OTP inputs) can drop into the same Field shell without
 * duplicating label / error logic.
 *
 * Validation states are visual only — wire to react-hook-form / zod /
 * whatever validates upstream. The Field doesn't own state.
 */

const inputCva = cva(
  [
    "flex w-full font-sans text-p7-body text-ink-primary",
    "placeholder:text-ink-tertiary",
    "bg-surface-elevated border border-surface-hairline",
    "rounded-p7-input",
    "outline-none",
    "transition-colors duration-p7-tap ease-p7-standard",
    "focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
    "focus-visible:ring-offset-2 focus-visible:ring-offset-[hsl(var(--p7-ring-offset))]",
    "focus-visible:border-brand",
    "disabled:opacity-50 disabled:cursor-not-allowed",
    "data-[invalid=true]:border-critical",
    "data-[invalid=true]:focus-visible:ring-[hsl(var(--p7-critical))]",
  ].join(" "),
  {
    variants: {
      size: {
        sm: "h-8 px-3",
        md: "h-10 px-3",
        lg: "h-12 px-4",
      },
    },
    defaultVariants: {
      size: "md",
    },
  },
);

/* ──────────────────── primitives ──────────────────── */

export type InputProps = React.InputHTMLAttributes<HTMLInputElement> &
  VariantProps<typeof inputCva> & {
    invalid?: boolean;
  };

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, size, invalid, ...rest }, ref) => (
    <input
      ref={ref}
      data-invalid={invalid ? true : undefined}
      className={cn(inputCva({ size }), className)}
      {...rest}
    />
  ),
);
Input.displayName = "Input";

export type TextareaProps = React.TextareaHTMLAttributes<HTMLTextAreaElement> & {
  invalid?: boolean;
};

export const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, invalid, ...rest }, ref) => (
    <textarea
      ref={ref}
      data-invalid={invalid ? true : undefined}
      className={cn(
        inputCva({ size: "md" }),
        "min-h-[88px] py-2 leading-[var(--p7-text-body-lh)]",
        className,
      )}
      {...rest}
    />
  ),
);
Textarea.displayName = "Textarea";

/* ──────────────────── shell ──────────────────── */

export type FieldProps = {
  label?: React.ReactNode;
  hint?: React.ReactNode;
  error?: React.ReactNode;
  htmlFor?: string;
  required?: boolean;
  className?: string;
  children: React.ReactNode;
};

export function Field({
  label,
  hint,
  error,
  htmlFor,
  required,
  className,
  children,
}: FieldProps) {
  return (
    <div className={cn("flex flex-col gap-1.5", className)}>
      {label ? (
        <LabelPrimitive.Root
          htmlFor={htmlFor}
          className="text-p7-caption-1 font-medium text-ink-secondary"
        >
          {label}
          {required ? <span className="ml-0.5 text-critical">*</span> : null}
        </LabelPrimitive.Root>
      ) : null}
      {children}
      {error ? (
        <p className="text-p7-caption-2 text-critical">{error}</p>
      ) : hint ? (
        <p className="text-p7-caption-2 text-ink-tertiary">{hint}</p>
      ) : null}
    </div>
  );
}
Field.displayName = "Field";
