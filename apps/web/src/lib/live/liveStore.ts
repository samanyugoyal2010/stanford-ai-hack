import { create } from "zustand";
import type { ModelProgress } from "./models";

export type LivePhase = "off" | "connecting" | "loading" | "reconnecting" | "idle" | "listening" | "thinking" | "speaking";

export type InterruptLevel = "quiet" | "balanced" | "active";
/** Study Tutor UI status from proactive observe. */
export type TutorStatus = "" | "watching" | "observing" | "quiet";

export interface DeviceOpt { id: string; label: string }

interface LiveState {
  active: boolean;
  phase: LivePhase;
  modelsDownloaded: boolean; // on-device models present (cached/warm) → skip download
  downloading: boolean;      // model download in progress on the pre-call screen
  downloadPct: number; // 0..1 model-download progress (phase === "loading")
  downloadLoaded: number; // bytes downloaded so far (across all models)
  downloadTotal: number;  // bytes total known so far
  downloadModels: ModelProgress[]; // per-model breakdown for the download UI
  muted: boolean;
  cameraOn: boolean;
  screenOn: boolean;
  screenStream: MediaStream | null;
  cameraStream: MediaStream | null;
  userCaption: string;
  userPartial: boolean; // true while the user caption is still interim (greyed)
  agentCaption: string;
  agentCaptionMs: number; // playback duration of the current agent chunk — paces the word-by-word caption reveal
  toolStatus: string; // active tool name while a tool is running (""), drives the live "Searching the web…" cue
  warming: boolean;   // true from socket-open until the agent signals warm-ready → shows "Warming up…"
  // Study lobby + in-call status
  studyGoal: string;
  interruptLevel: InterruptLevel;
  tutorStatus: TutorStatus;
  error?: string;
  micId?: string;
  camId?: string;
  mics: DeviceOpt[];
  cams: DeviceOpt[];
  set: (p: Partial<LiveState>) => void;
}

// One live session at a time (single-user target). ponytail: global store, not
// keyed by chatId — add keying if multi-session live is ever needed.
export const useLiveStore = create<LiveState>((set) => ({
  active: false,
  phase: "off",
  modelsDownloaded: false,
  downloading: false,
  downloadPct: 0,
  downloadLoaded: 0,
  downloadTotal: 0,
  downloadModels: [],
  muted: false,
  cameraOn: false,
  screenOn: false,
  screenStream: null,
  cameraStream: null,
  userCaption: "",
  userPartial: false,
  agentCaption: "",
  agentCaptionMs: 0,
  toolStatus: "",
  warming: false,
  studyGoal: "",
  interruptLevel: "balanced",
  tutorStatus: "",
  mics: [],
  cams: [],
  set: (p) => set(p),
}));

/** Client observe poll interval from interrupt level. */
export function observeIntervalMs(level: InterruptLevel): number {
  switch (level) {
    case "quiet": return 10_000;
    case "active": return 4_000;
    default: return 6_000;
  }
}
