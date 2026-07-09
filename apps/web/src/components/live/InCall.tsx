"use client";

import { useEffect, useState } from "react";
import { useReducedMotion } from "motion/react";
import { Mic, MicOff, Video, VideoOff, PhoneOff, Hand } from "lucide-react";
import { useLiveStore, type LivePhase } from "@/lib/live/liveStore";
import { Orb } from "./Orb";
import { CameraPiP } from "./CameraPiP";
import { TranscriptPanel } from "./TranscriptPanel";
import { cn } from "@/lib/cn";

const PHASE_LABEL: Record<LivePhase, string> = {
  off: "", connecting: "Connecting…", loading: "Preparing…", reconnecting: "Reconnecting…",
  idle: "Listening", listening: "Listening…", thinking: "Thinking…", speaking: "Speaking",
};

// The in-call screen: the orb is the hero, center stage, with a karaoke subtitle
// beneath it; the running transcript sits in a panel on the right; a slim control
// bar floats at the bottom; the camera is a draggable PiP.
export function InCall({
  chatId, phase, muted, pttEnabled, cameraOn, cameraStream, error,
  toggleMute, setPtt, holdTalk, toggleCamera, getLevels, onEnd,
}: {
  chatId: string; phase: LivePhase; muted: boolean; pttEnabled: boolean; cameraOn: boolean;
  cameraStream: MediaStream | null; error?: string;
  toggleMute: () => void; setPtt: (v: boolean) => void; holdTalk: (v: boolean) => void;
  toggleCamera: () => void | Promise<void>; getLevels: () => { mic: number; agent: number }; onEnd: () => void;
}) {
  const { userCaption, userPartial, agentCaption, agentCaptionMs } = useLiveStore();
  const reduce = useReducedMotion();

  // Karaoke: reveal the agent's current chunk a few words at a time, paced to how
  // long it actually voices — so it shows the ~4 words being spoken right now.
  const [agentWindow, setAgentWindow] = useState("");
  useEffect(() => {
    const words = agentCaption.split(/\s+/).filter(Boolean);
    if (words.length <= 5) { setAgentWindow(words.join(" ")); return; }
    const dur = agentCaptionMs > 0 ? agentCaptionMs : words.length * 320;
    const WINDOW = 5;
    const start = performance.now();
    let raf = 0;
    const tick = () => {
      const frac = Math.min(1, (performance.now() - start) / dur);
      const idx = Math.max(1, Math.min(words.length, Math.ceil(frac * words.length)));
      setAgentWindow(words.slice(Math.max(0, idx - WINDOW), idx).join(" "));
      if (frac < 1) raf = requestAnimationFrame(tick);
    };
    tick();
    return () => cancelAnimationFrame(raf);
  }, [agentCaption, agentCaptionMs]);

  // Spacebar push-to-talk.
  useEffect(() => {
    if (!pttEnabled) return;
    const down = (e: KeyboardEvent) => { if (e.code === "Space" && !e.repeat) { e.preventDefault(); holdTalk(true); } };
    const up = (e: KeyboardEvent) => { if (e.code === "Space") { e.preventDefault(); holdTalk(false); } };
    window.addEventListener("keydown", down); window.addEventListener("keyup", up);
    return () => { window.removeEventListener("keydown", down); window.removeEventListener("keyup", up); };
  }, [pttEnabled, holdTalk]);

  const subtitle = userPartial && userCaption
    ? <span className="italic text-muted-foreground">{userCaption}</span>
    : agentCaption
      ? <span className="font-medium text-foreground">{agentWindow || agentCaption}</span>
      : <span className="text-muted-foreground">{PHASE_LABEL[phase] || "Listening…"}</span>;

  return (
    <div className={cn("fixed inset-0 z-40 flex bg-background", !reduce && "animate-live-in")}>
      {/* stage — orb hero + karaoke + controls + camera PiP */}
      <main className="relative flex min-w-0 flex-1 flex-col items-center justify-center overflow-hidden px-6">
        <Orb phase={phase} getLevels={getLevels} size={240} />

        <div className="mt-10 h-16 max-w-xl text-center" aria-live="polite">
          <p className="text-[22px] leading-snug tracking-tight">{subtitle}</p>
          <p className="mt-2 text-[12px] uppercase tracking-wide text-faint">{PHASE_LABEL[phase]}</p>
        </div>

        {error && <p className="mt-2 max-w-md text-center text-[12.5px] text-danger">{error}</p>}

        {cameraOn && <CameraPiP stream={cameraStream} />}

        {/* control bar */}
        <div className="absolute bottom-8 left-1/2 flex -translate-x-1/2 items-center gap-2 rounded-full border border-border bg-surface px-3 py-2 shadow-[0_10px_34px_-10px_rgba(0,0,0,0.35)]">
          <IconBtn on={pttEnabled} title={pttEnabled ? "Switch to hands-free" : "Switch to push-to-talk"} onClick={() => setPtt(!pttEnabled)} icon={Hand} />
          {pttEnabled ? (
            <button onPointerDown={() => holdTalk(true)} onPointerUp={() => holdTalk(false)} onPointerLeave={() => holdTalk(false)}
              className={cn("select-none rounded-full px-4 py-2 text-[12px] font-medium transition", muted ? "bg-foreground/[0.06] text-muted-foreground" : "bg-accent text-accent-foreground")}>
              {muted ? "Hold · Space" : "Listening"}
            </button>
          ) : (
            <IconBtn on={!muted} title={muted ? "Unmute" : "Mute"} onClick={toggleMute} icon={muted ? MicOff : Mic} danger={muted} />
          )}
          <IconBtn on={cameraOn} title={cameraOn ? "Turn camera off" : "Turn camera on"} onClick={() => void toggleCamera()} icon={cameraOn ? Video : VideoOff} />
          <button onClick={onEnd} title="End call" aria-label="End call"
            className="grid size-9 place-items-center rounded-full bg-danger text-white transition hover:opacity-90 active:scale-95">
            <PhoneOff className="size-4" />
          </button>
        </div>
      </main>

      {/* transcript — always visible on wider screens */}
      <div className="hidden w-80 shrink-0 md:block lg:w-96">
        <TranscriptPanel chatId={chatId} />
      </div>
    </div>
  );
}

function IconBtn({ on, title, onClick, icon: Icon, danger }: { on: boolean; title: string; onClick: () => void; icon: typeof Mic; danger?: boolean }) {
  return (
    <button onClick={onClick} title={title} aria-label={title} aria-pressed={on}
      className={cn("grid size-9 place-items-center rounded-full transition hover:bg-foreground/10",
        danger ? "text-danger" : on ? "text-foreground" : "text-muted-foreground")}>
      <Icon className="size-4" />
    </button>
  );
}
