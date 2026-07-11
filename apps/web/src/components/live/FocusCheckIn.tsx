"use client";

import { cn } from "@/lib/cn";

/** Shared “Still with me?” prompt — I’m fine / I need help. */
export function FocusCheckIn({
  onFine,
  onHelp,
  compact,
  className,
}: {
  onFine: () => void;
  onHelp: () => void;
  /** Tighter layout for the floating sphere. */
  compact?: boolean;
  className?: string;
}) {
  return (
    <div
      role="dialog"
      aria-label="Focus check-in"
      className={cn(
        "flex flex-col items-center gap-2 [-webkit-app-region:no-drag]",
        compact ? "gap-1.5 px-2 pb-1" : "gap-3 rounded-2xl border border-border bg-surface px-5 py-4 shadow-[0_10px_34px_-10px_rgba(0,0,0,0.4)]",
        className,
      )}
    >
      <p className={cn("text-center font-medium tracking-tight text-foreground", compact ? "text-[11px]" : "text-[15px]")}>
        Still with me?
      </p>
      <div className={cn("flex items-center", compact ? "gap-1.5" : "gap-2")}>
        <button
          type="button"
          onClick={onFine}
          className={cn(
            "rounded-full border border-border bg-card font-medium text-muted-foreground transition hover:bg-foreground/5 hover:text-foreground active:scale-[0.98]",
            compact ? "px-2.5 py-1 text-[10px]" : "px-4 py-2 text-[13px]",
          )}
        >
          I&apos;m fine
        </button>
        <button
          type="button"
          onClick={onHelp}
          className={cn(
            "rounded-full bg-foreground font-medium text-background transition hover:opacity-90 active:scale-[0.98]",
            compact ? "px-2.5 py-1 text-[10px]" : "px-4 py-2 text-[13px]",
          )}
        >
          I need help
        </button>
      </div>
    </div>
  );
}
