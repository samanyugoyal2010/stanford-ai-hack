"use client";

import { useEffect, useRef } from "react";
import { Mic, MicOff, Video, VideoOff, ScreenShare, ScreenShareOff, PhoneOff, Maximize2 } from "lucide-react";
import { useLiveStore, type LivePhase } from "@/lib/live/liveStore";
import { useUi } from "@/lib/uiStore";
import { Orb } from "./Orb";
import { cn } from "@/lib/cn";

const noDrag = "[-webkit-app-region:no-drag]";

function Tile({ stream, contain }: { stream: MediaStream | null; contain?: boolean }) {
  const ref = useRef<HTMLVideoElement>(null);
  useEffect(() => { if (ref.current) ref.current.srcObject = stream; }, [stream]);
  return (
    <div className="flex-1 overflow-hidden rounded-lg border border-border/60 bg-black">
      <video ref={ref} autoPlay muted playsInline className={cn("h-full w-full", contain ? "object-contain" : "object-cover")} />
    </div>
  );
}

function MiniBtn({ on, title, onClick, icon: Icon, danger }: { on: boolean; title: string; onClick: () => void; icon: typeof Mic; danger?: boolean }) {
  return (
    <button onClick={onClick} title={title} aria-label={title}
      className={cn("grid size-8 place-items-center rounded-full transition hover:bg-foreground/10", noDrag,
        danger ? "text-danger" : on ? "text-foreground" : "text-muted-foreground")}>
      <Icon className="size-4" />
    </button>
  );
}

// The minimized floating overlay: a small always-on-top window with an animated
// orb, the live caption, the controls, and the camera/screen tiles above the bar.
export function MiniBar({ phase, muted, cameraOn, screenOn, cameraStream, screenStream,
  toggleMute, toggleCamera, toggleScreen, getLevels, onEnd }: {
  phase: LivePhase; muted: boolean; cameraOn: boolean; screenOn: boolean;
  cameraStream: MediaStream | null; screenStream: MediaStream | null;
  toggleMute: () => void; toggleCamera: () => void | Promise<void>; toggleScreen: () => void | Promise<void>;
  getLevels: () => { mic: number; agent: number }; onEnd: () => void;
}) {
  const setMinimized = useUi((s) => s.setMinimized);
  const { userCaption, userPartial, agentCaption } = useLiveStore();
  const sharing = cameraOn || screenOn;
  const w = sharing ? 540 : 460;
  const h = sharing ? 250 : 92;

  // Drive the floating window's size/always-on-top via the Electron bridge.
  useEffect(() => {
    const api = (window as unknown as { openlive?: { mini: (w: number, h: number) => void; unmini: () => void } }).openlive;
    api?.mini(w, h);
    return () => api?.unmini();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useEffect(() => {
    (window as unknown as { openlive?: { size: (w: number, h: number) => void } }).openlive?.size(w, h);
  }, [w, h]);

  const caption = userPartial && userCaption ? userCaption : agentCaption || (phase === "thinking" ? "Thinking…" : "Listening…");

  return (
    <div className="fixed inset-0 z-50 flex flex-col gap-2 bg-transparent p-2 [-webkit-app-region:drag]">
      {sharing && (
        <div className="flex min-h-0 flex-1 gap-2">
          {cameraOn && <Tile stream={cameraStream} />}
          {screenOn && <Tile stream={screenStream} contain />}
        </div>
      )}
      <div className="flex h-14 shrink-0 items-center gap-2 rounded-2xl border border-border bg-surface px-2.5 shadow-2xl">
        <Orb phase={phase} getLevels={getLevels} size={34} />
        <span className="min-w-0 flex-1 truncate text-[12.5px]" aria-live="polite">{caption}</span>
        <MiniBtn on={!muted} title={muted ? "Unmute" : "Mute"} onClick={toggleMute} icon={muted ? MicOff : Mic} danger={muted} />
        <MiniBtn on={cameraOn} title={cameraOn ? "Camera off" : "Camera on"} onClick={() => void toggleCamera()} icon={cameraOn ? Video : VideoOff} />
        <MiniBtn on={screenOn} title={screenOn ? "Stop sharing" : "Share screen"} onClick={() => void toggleScreen()} icon={screenOn ? ScreenShareOff : ScreenShare} />
        <MiniBtn on={false} title="Expand" onClick={() => setMinimized(false)} icon={Maximize2} />
        <button onClick={onEnd} title="End call" aria-label="End call"
          className={cn("grid size-8 place-items-center rounded-full bg-danger text-white transition hover:opacity-90", noDrag)}>
          <PhoneOff className="size-4" />
        </button>
      </div>
    </div>
  );
}
