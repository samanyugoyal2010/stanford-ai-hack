"use client";

import { useEffect, useState } from "react";
import { Mic } from "lucide-react";
import type { DeviceOpt } from "@/lib/live/liveStore";
import { useLiveStore } from "@/lib/live/liveStore";
import type { ModelProgress } from "@/lib/live/models";
import { hasWebGPU } from "@/lib/live/models";
import { ModelQuickPick } from "./ModelQuickPick";
import { cn } from "@/lib/cn";

// The pre-call screen for Live voice: device pickers, mic meter, study goal /
// interrupt prefs, and the on-device model download. The in-call UI lives in
// LiveDock/VoiceBar.

const mb = (bytes: number) => (bytes / 1_048_576).toFixed(bytes >= 100 * 1_048_576 ? 0 : 1);
const MODEL_ROLE: Record<string, string> = { stt: "hears you", tts: "speaks back", turn: "knows when you're done" };

// Shared, transparent progress: overall bar + real MB, and a per-model checklist.
function DownloadProgress({ pct, loaded, total, models }: { pct: number; loaded: number; total: number; models: ModelProgress[] }) {
  return (
    <div className="flex w-72 max-w-[82vw] flex-col gap-2.5">
      <div className="h-1.5 w-full overflow-hidden rounded-full bg-foreground/10">
        <div className="h-full rounded-full bg-accent transition-[width] duration-200" style={{ width: `${Math.round(pct * 100)}%` }} />
      </div>
      <p className="text-center text-[11px] text-muted-foreground">
        {Math.round(pct * 100)}%{total ? ` · ${mb(loaded)} / ${mb(total)} MB` : ""} · one-time, then instant
      </p>
      {models.length > 0 && (
        <ul className="space-y-1">
          {models.map((m) => {
            const done = m.total > 0 && m.loaded >= m.total;
            return (
              <li key={m.key} className="flex items-center gap-2 text-[11px]">
                <span className={cn("grid size-3.5 shrink-0 place-items-center rounded-full text-[8px]", done ? "bg-accent text-accent-foreground" : "border border-border text-transparent")}>✓</span>
                <span className="text-foreground">{m.name}</span>
                <span className="text-faint">· {MODEL_ROLE[m.key]}</span>
                <span className="ml-auto tabular-nums text-muted-foreground">{m.total ? `${mb(m.loaded)}/${mb(m.total)}` : "…"}</span>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}

function DeviceSelect({ icon: Icon, opts, value, onChange }: { icon: typeof Mic; opts: DeviceOpt[]; value?: string; onChange: (id: string) => void }) {
  if (!opts.length) return <p className="text-[12px] text-faint">No device found</p>;
  return (
    <label className="flex items-center gap-2 text-muted-foreground">
      <Icon className="size-3.5 shrink-0" />
      <select value={value ?? opts[0]?.id ?? ""} onChange={(e) => onChange(e.target.value)}
        className="min-w-0 flex-1 truncate rounded-lg border border-border bg-surface px-2 py-1.5 text-[12px] text-foreground">
        {opts.map((o) => <option key={o.id} value={o.id}>{o.label}</option>)}
      </select>
    </label>
  );
}

export function PreCall({ mics, micId, onMic, error, modelsDownloaded, downloading, downloadPct, downloadLoaded, downloadTotal, downloadModels, refreshDevices, onDownload, onStart, onOpenSettings }: {
  mics: DeviceOpt[]; micId?: string;
  onMic: (id: string) => void; error?: string;
  modelsDownloaded: boolean; downloading: boolean; downloadPct: number;
  downloadLoaded: number; downloadTotal: number; downloadModels: ModelProgress[];
  refreshDevices: () => Promise<void>; onDownload: () => void; onStart: () => void; onOpenSettings: () => void;
}) {
  const studyGoal = useLiveStore((s) => s.studyGoal);
  const interruptLevel = useLiveStore((s) => s.interruptLevel);
  const set = useLiveStore((s) => s.set);

  return (
    <div className="relative z-10 flex flex-1 flex-col overflow-y-auto">
      <div className="m-auto flex w-full max-w-sm flex-col items-center gap-4 px-6 py-6 text-center">
        <div className="space-y-1">
          <h2 className="text-[18px] font-semibold tracking-tight">nudge</h2>
          <p className="max-w-sm text-[13px] text-muted-foreground">
            The quiet tutor that teaches you to think. Share your screen while you study — Nudge stays quiet when you’re progressing, and speaks up with short hints when you’re stuck.
          </p>
          {typeof navigator !== "undefined" && !hasWebGPU() && (
            <p className="mx-auto max-w-xs rounded-lg border border-arc/30 bg-arc/10 px-2.5 py-1.5 text-[11.5px] text-arc">
              Running voice on CPU — WebGPU isn&apos;t available, so responses will be slower.
            </p>
          )}
        </div>

        <div className="w-full max-w-xs space-y-3 text-left">
          <label className="block space-y-1">
            <span className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">Study goal</span>
            <input
              value={studyGoal}
              onChange={(e) => set({ studyGoal: e.target.value })}
              placeholder="e.g. AP Chem chapter 4, calc integrals"
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-[13px] text-foreground placeholder:text-faint"
            />
          </label>
          <label className="block space-y-1">
            <span className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">How often to speak up</span>
            <select
              value={interruptLevel}
              onChange={(e) => set({ interruptLevel: e.target.value as "quiet" | "balanced" | "active" })}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-[13px] text-foreground"
            >
              <option value="quiet">Quiet — only when clearly stuck</option>
              <option value="balanced">Balanced — hints when progress stalls</option>
              <option value="active">Active — check in more often</option>
            </select>
          </label>
          <p className="text-[11px] leading-relaxed text-faint">
            Talk: local <span className="text-muted-foreground">gemma4</span> · Eyes: <span className="text-muted-foreground">qwen2.5vl</span>. After start, a floating sphere stays on top — click it to open the full UI.
          </p>
        </div>

        <MicMeter micId={micId} onGranted={refreshDevices} />

        <div className="w-full max-w-xs space-y-2">
          <DeviceSelect icon={Mic} opts={mics} value={micId} onChange={onMic} />
        </div>

        <ModelQuickPick onOpenSettings={onOpenSettings} />

        {downloading ? (
          <div className="flex flex-col items-center gap-2">
            <p className="text-[12px] font-medium text-muted-foreground">Downloading on-device AI…</p>
            <DownloadProgress pct={downloadPct} loaded={downloadLoaded} total={downloadTotal} models={downloadModels} />
          </div>
        ) : !modelsDownloaded ? (
          <div className="flex flex-col items-center gap-2">
            <button onClick={onDownload} className="rounded-full bg-accent px-6 py-2.5 text-[14px] font-medium text-accent-foreground transition duration-150 hover:scale-[1.03] hover:opacity-90 active:scale-95">
              Download AI models
            </button>
            <p className="max-w-[16rem] text-[11px] text-faint">A one-time download of 3 small AI models (speech, voice, turn-taking) that run fully on your device — nothing is sent to a server.</p>
          </div>
        ) : (
          <button onClick={onStart} className="rounded-full bg-accent px-7 py-2.5 text-[14px] font-medium text-accent-foreground transition duration-150 hover:scale-[1.03] hover:opacity-90 active:scale-95">
            Start studying
          </button>
        )}
        {error && <p className="max-w-sm text-[12px] text-danger">{error}</p>}
      </div>
    </div>
  );
}

// Live mic level on the pre-call screen (own stream, released on unmount).
function MicMeter({ micId, onGranted }: { micId?: string; onGranted: () => void }) {
  const [level, setLevel] = useState(0);
  const [denied, setDenied] = useState(false);
  useEffect(() => {
    let stream: MediaStream | null = null, ctx: AudioContext | null = null, raf = 0, stopped = false;
    setDenied(false);
    (async () => {
      try {
        stream = await navigator.mediaDevices.getUserMedia({ audio: micId ? { deviceId: { exact: micId } } : true });
        if (stopped) { stream.getTracks().forEach((t) => t.stop()); return; }
        onGranted();
        ctx = new AudioContext();
        void ctx.resume().catch(() => {});
        if (ctx.state === "suspended") {
          const c = ctx;
          window.addEventListener("pointerdown", () => void c.resume().catch(() => {}), { once: true });
        }
        const analyser = ctx.createAnalyser(); analyser.fftSize = 512;
        ctx.createMediaStreamSource(stream).connect(analyser);
        const buf = new Float32Array(analyser.fftSize);
        const loop = () => {
          analyser.getFloatTimeDomainData(buf);
          let sum = 0; for (let i = 0; i < buf.length; i++) sum += buf[i]! * buf[i]!;
          setLevel(Math.min(1, Math.sqrt(sum / buf.length) * 3.5));
          raf = requestAnimationFrame(loop);
        };
        loop();
      } catch { if (!stopped) setDenied(true); }
    })();
    return () => { stopped = true; cancelAnimationFrame(raf); stream?.getTracks().forEach((t) => t.stop()); ctx?.close().catch(() => {}); };
  }, [micId, onGranted]);
  return (
    <div className="flex w-full max-w-[18rem] items-center gap-2">
      <Mic className={cn("size-3.5 shrink-0", denied ? "text-danger" : "text-muted-foreground")} />
      <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-foreground/10">
        <div className="h-full rounded-full bg-success transition-[width] duration-75" style={{ width: `${Math.round(level * 100)}%` }} />
      </div>
      {denied && <span className="text-[10px] text-danger">mic blocked</span>}
    </div>
  );
}
