"use client";

import { useEffect, useRef, useState } from "react";
import { useReducedMotion } from "motion/react";
import { Mic, MicOff, Video, VideoOff, PhoneOff, Hand, ScreenShare, ScreenShareOff, ChevronUp, Check, MonitorUp } from "lucide-react";
import { useLiveStore, type LivePhase, type DeviceOpt } from "@/lib/live/liveStore";
import { useChat } from "@/lib/chatStore";
import { Orb } from "./Orb";
import { CameraPiP } from "./CameraPiP";
import { ScreenView } from "./ScreenView";
import { cn } from "@/lib/cn";

const PHASE_LABEL: Record<LivePhase, string> = {
  off: "", connecting: "Connecting…", loading: "Preparing…", reconnecting: "Reconnecting…",
  idle: "Listening", listening: "Listening…", thinking: "Thinking…", speaking: "Speaking",
};

export interface InCallProps {
  chatId: string;
  phase: LivePhase; muted: boolean; pttEnabled: boolean;
  cameraOn: boolean; screenOn: boolean;
  cameraStream: MediaStream | null; screenStream: MediaStream | null; error?: string;
  mics: DeviceOpt[]; cams: DeviceOpt[]; micId?: string; camId?: string;
  toggleMute: () => void; setPtt: (v: boolean) => void; holdTalk: (v: boolean) => void;
  toggleCamera: () => void | Promise<void>; toggleScreen: () => void | Promise<void>; changeScreen: () => void | Promise<void>;
  setMic: (id: string) => void | Promise<void>; setCam: (id: string) => void | Promise<void>;
  getLevels: () => { mic: number; agent: number }; onEnd: () => void;
}

// In-call, Google-Meet style: the shared screen (or the ambient AI response) fills
// the stage, the camera is a PiP, your own words show as a bubble, and a slim
// control bar carries a small orb + the mic/camera/screen controls (each with a
// live device menu).
export function InCall(p: InCallProps) {
  const { chatId, phase, muted, pttEnabled, cameraOn, screenOn, cameraStream, screenStream, error,
    mics, cams, micId, camId, toggleMute, setPtt, holdTalk, toggleCamera, toggleScreen, changeScreen,
    setMic, setCam, getLevels, onEnd } = p;
  const reduce = useReducedMotion();
  const { userCaption, userPartial } = useLiveStore();
  const msgs = useChat(chatId);
  const lastAssistant = [...msgs].reverse().find((m) => m.role === "assistant");
  const lastUser = [...msgs].reverse().find((m) => m.role === "user");
  const aiText = lastAssistant?.text?.trim() ?? "";
  const userBubble = userPartial && userCaption ? userCaption : lastUser?.text ?? "";

  // Spacebar push-to-talk.
  useEffect(() => {
    if (!pttEnabled) return;
    const down = (e: KeyboardEvent) => { if (e.code === "Space" && !e.repeat) { e.preventDefault(); holdTalk(true); } };
    const up = (e: KeyboardEvent) => { if (e.code === "Space") { e.preventDefault(); holdTalk(false); } };
    window.addEventListener("keydown", down); window.addEventListener("keyup", up);
    return () => { window.removeEventListener("keydown", down); window.removeEventListener("keyup", up); };
  }, [pttEnabled, holdTalk]);

  return (
    <div className={cn("fixed inset-0 z-40 flex flex-col bg-background", !reduce && "animate-live-in")}>
      {/* stage */}
      <main className="relative min-h-0 flex-1 overflow-hidden pt-14">
        {screenOn ? (
          <ScreenView stream={screenStream} />
        ) : (
          <div className="flex h-full items-center justify-center px-8">
            {aiText
              ? <p className="max-w-3xl text-center text-[30px] font-medium leading-snug tracking-tight text-foreground/95">{aiText}</p>
              : <p className="text-[18px] text-muted-foreground">{PHASE_LABEL[phase] || "Listening…"}</p>}
          </div>
        )}

        {/* when sharing a screen, the AI reply becomes a subtitle */}
        {screenOn && aiText && (
          <div className="pointer-events-none absolute inset-x-0 bottom-6 flex justify-center px-6">
            <p className="max-w-2xl rounded-xl bg-surface/90 px-4 py-2 text-center text-[15px] leading-snug text-foreground shadow-lg backdrop-blur">{aiText}</p>
          </div>
        )}

        {/* your own words, as a bubble */}
        {userBubble && (
          <div className="pointer-events-none absolute inset-x-0 bottom-6 flex justify-end px-6" style={{ bottom: screenOn ? undefined : "1.5rem" }}>
            <div className={cn("max-w-md rounded-2xl bg-accent px-4 py-2 text-[14px] text-accent-foreground shadow-lg", screenOn && "opacity-90")}>
              {userPartial && userCaption ? <span className="italic opacity-80">{userCaption}</span> : lastUser?.text}
            </div>
          </div>
        )}

        {cameraOn && <CameraPiP stream={cameraStream} />}
        {error && <p className="absolute inset-x-0 top-16 z-10 text-center text-[12.5px] text-danger">{error}</p>}
      </main>

      {/* control bar */}
      <footer className="flex shrink-0 items-center justify-center gap-2 border-t border-border bg-surface/70 px-4 py-2.5 backdrop-blur">
        <div className="grid size-9 place-items-center"><Orb phase={phase} getLevels={getLevels} size={36} /></div>
        <div className="mx-1 h-6 w-px bg-border" />

        {pttEnabled ? (
          <button onPointerDown={() => holdTalk(true)} onPointerUp={() => holdTalk(false)} onPointerLeave={() => holdTalk(false)}
            className={cn("select-none rounded-full px-4 py-2 text-[12px] font-medium transition", muted ? "bg-foreground/[0.06] text-muted-foreground" : "bg-accent text-accent-foreground")}>
            {muted ? "Hold · Space" : "Listening"}
          </button>
        ) : (
          <Picker on={!muted} danger={muted} title={muted ? "Unmute" : "Mute"} icon={muted ? MicOff : Mic} onClick={toggleMute}
            options={mics.map((d) => ({ id: d.id, label: d.label, active: d.id === micId, onSelect: () => setMic(d.id) }))} menuTitle="Microphone" />
        )}
        <Picker on={cameraOn} title={cameraOn ? "Turn camera off" : "Turn camera on"} icon={cameraOn ? Video : VideoOff} onClick={() => void toggleCamera()}
          options={cams.map((d) => ({ id: d.id, label: d.label, active: d.id === camId, onSelect: () => setCam(d.id) }))} menuTitle="Camera" />
        <Picker on={screenOn} title={screenOn ? "Stop sharing" : "Share screen"} icon={screenOn ? ScreenShareOff : ScreenShare} onClick={() => void toggleScreen()}
          options={screenOn ? [{ id: "change", label: "Change window / screen", icon: MonitorUp, onSelect: () => void changeScreen() }] : []} menuTitle="Screen" />
        <IconBtn on={pttEnabled} title={pttEnabled ? "Switch to hands-free" : "Push-to-talk"} icon={Hand} onClick={() => setPtt(!pttEnabled)} />

        <button onClick={onEnd} title="End call" aria-label="End call"
          className="ml-1 grid size-9 place-items-center rounded-full bg-danger text-white transition hover:opacity-90 active:scale-95">
          <PhoneOff className="size-4" />
        </button>
      </footer>
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

interface Opt { id: string; label: string; active?: boolean; icon?: typeof Mic; onSelect: () => void }

// A control (mic/camera/screen) with a chevron that opens a live device menu.
function Picker({ on, danger, title, icon: Icon, onClick, options, menuTitle }: {
  on: boolean; danger?: boolean; title: string; icon: typeof Mic; onClick: () => void; options: Opt[]; menuTitle: string;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false); };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  return (
    <div ref={ref} className="relative flex items-center rounded-full">
      <IconBtn on={on} danger={danger} title={title} icon={Icon} onClick={onClick} />
      {options.length > 0 && (
        <button onClick={() => setOpen((o) => !o)} aria-label={`${menuTitle} options`}
          className="grid h-9 w-5 place-items-center rounded-full text-muted-foreground transition hover:bg-foreground/10 hover:text-foreground">
          <ChevronUp className={cn("size-3.5 transition", open && "rotate-180")} />
        </button>
      )}
      {open && options.length > 0 && (
        <div className="absolute bottom-full left-1/2 mb-2 w-60 -translate-x-1/2 overflow-hidden rounded-xl border border-border bg-popover shadow-xl">
          <div className="border-b border-border px-3 py-2 text-[11px] font-medium uppercase tracking-wide text-faint">{menuTitle}</div>
          <div className="takt-scroll max-h-56 overflow-y-auto py-1">
            {options.map((o) => (
              <button key={o.id} onClick={() => { o.onSelect(); setOpen(false); }}
                className="flex w-full items-center gap-2 px-3 py-1.5 text-left text-[13px] text-foreground transition hover:bg-foreground/[0.05]">
                <span className={cn("grid size-4 shrink-0 place-items-center", o.active ? "text-accent" : "text-transparent")}>
                  {o.icon ? <o.icon className="size-3.5 text-muted-foreground" /> : <Check className="size-3.5" />}
                </span>
                <span className="truncate">{o.label}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
