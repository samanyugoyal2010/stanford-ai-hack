"use client";

import { useEffect } from "react";
import { useUi } from "@/lib/uiStore";
import { useLiveStore, type LivePhase } from "@/lib/live/liveStore";
import { Orb } from "./Orb";

type Bridge = { mini?: () => void; unmini?: () => void; miniSize?: (h: number) => void };
const ol = (): Bridge | undefined =>
  typeof window !== "undefined" ? (window as unknown as { openlive?: Bridge }).openlive : undefined;

/** Tiny always-on-top sphere — click to open the full Nudge UI. */
export function MiniSphere({
  phase,
  getLevels,
  getBands,
}: {
  phase: LivePhase;
  getLevels: () => { mic: number; agent: number };
  getBands: () => { mic: number[]; agent: number[] };
}) {
  const setMinimized = useUi((s) => s.setMinimized);
  const tutorStatus = useLiveStore((s) => s.tutorStatus);

  useEffect(() => {
    ol()?.mini?.();
    ol()?.miniSize?.(64);
    return () => ol()?.unmini?.();
  }, []);

  const title =
    tutorStatus === "observing"
      ? "Watching your work — click to expand"
      : tutorStatus === "watching"
        ? "Quiet · watching — click to expand"
        : "Click to expand Nudge";

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
