"use client";

import { useEffect, useRef } from "react";
import { useUi } from "@/lib/uiStore";
import { useLiveStore, type LivePhase } from "@/lib/live/liveStore";
import { Orb } from "./Orb";
import { FocusCheckIn } from "./FocusCheckIn";

type Bridge = { mini?: () => void; unmini?: () => void; miniSize?: (h: number) => void };
const ol = (): Bridge | undefined =>
  typeof window !== "undefined" ? (window as unknown as { openlive?: Bridge }).openlive : undefined;

const SPHERE = 64;
/** Mini window height when Focus check-in is showing. */
const FOCUS_H = 132;

/** Tiny always-on-top sphere — click to open the full Nudge UI. */
export function MiniSphere({
  phase,
  getLevels,
  getBands,
  onFocusFine,
  onFocusHelp,
}: {
  phase: LivePhase;
  getLevels: () => { mic: number; agent: number };
  getBands: () => { mic: number[]; agent: number[] };
  onFocusFine: () => void;
  onFocusHelp: () => void;
}) {
  const setMinimized = useUi((s) => s.setMinimized);
  const tutorStatus = useLiveStore((s) => s.tutorStatus);
  const focusPrompt = useLiveStore((s) => s.focusPrompt);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    ol()?.mini?.();
    return () => ol()?.unmini?.();
  }, []);

  // Fit sphere vs Focus prompt height.
  useEffect(() => {
    const h = focusPrompt ? (contentRef.current?.offsetHeight || FOCUS_H) : SPHERE;
    ol()?.miniSize?.(h);
  }, [focusPrompt]);

  useEffect(() => {
    if (!focusPrompt) return;
    const el = contentRef.current;
    if (!el) return;
    const report = () => ol()?.miniSize?.(el.offsetHeight || FOCUS_H);
    report();
    const ro = new ResizeObserver(report);
    ro.observe(el);
    return () => ro.disconnect();
  }, [focusPrompt]);

  const title =
    focusPrompt
      ? "Focus check-in"
      : tutorStatus === "observing"
        ? "Watching your work — click to expand"
        : tutorStatus === "watching"
          ? "Quiet · watching — click to expand"
          : "Click to expand Nudge";

  if (focusPrompt) {
    return (
      <div className="fixed inset-0 flex flex-col items-center justify-center bg-surface [-webkit-app-region:drag]">
        <div ref={contentRef} className="flex w-full flex-col items-center gap-1 px-1.5 py-1.5">
          <button
            type="button"
            title="Expand Nudge"
            aria-label="Expand Nudge"
            onClick={() => setMinimized(false)}
            className="grid place-items-center [-webkit-app-region:no-drag] transition hover:scale-105 active:scale-95"
          >
            <Orb phase={phase} getLevels={getLevels} getBands={getBands} size={40} pulse={phase === "idle"} />
          </button>
          <FocusCheckIn compact onFine={onFocusFine} onHelp={onFocusHelp} />
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 grid place-items-center bg-transparent [-webkit-app-region:drag]">
      <button
        type="button"
        title={title}
        aria-label={title}
        onClick={() => setMinimized(false)}
        className="grid size-14 place-items-center rounded-full [-webkit-app-region:no-drag] transition hover:scale-105 active:scale-95"
      >
        <Orb phase={phase} getLevels={getLevels} getBands={getBands} size={52} pulse={phase === "idle"} />
      </button>
    </div>
  );
}
