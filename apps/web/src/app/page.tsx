"use client";

import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Settings2, MessageSquare, Plus } from "lucide-react";
import { api } from "@/lib/api";
import { useUi } from "@/lib/uiStore";
import { LiveDock } from "@/components/live/LiveDock";
import { SettingsModal } from "@/components/settings/SettingsModal";
import { OpenLiveMark } from "@/components/OpenLiveMark";
import { useAppVersion } from "@/lib/useAppVersion";
import { loadModels, modelsCached, modelsReady } from "@/lib/live/models";

function relTime(iso: string): string {
  const t = new Date(iso).getTime();
  if (!t) return "";
  const s = Math.floor((Date.now() - t) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

// Resume dropdown: shows saved conversations; picking one resumes it (its context
// rehydrates) and drops into the lobby (where camera/mic/model options live).
function ResumeMenu({ onPick }: { onPick: (id: string) => void }) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const { data: chats = [] } = useQuery({ queryKey: ["chats"], queryFn: api.chats, enabled: open });
  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false); };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);
  return (
    <div ref={ref} className="relative">
      <button onClick={() => setOpen((o) => !o)} title="Resume a past conversation"
        className="flex items-center gap-2 rounded-full border border-white/15 px-5 py-3 text-[14px] text-white/60 transition hover:border-white/30 hover:text-white">
        <MessageSquare className="size-4" /> Resume
      </button>
      {open && (
        <div className="absolute left-1/2 z-50 mt-2 w-80 -translate-x-1/2 overflow-hidden rounded-xl border border-white/10 bg-[#14182a] text-left shadow-xl">
          <div className="takt-scroll max-h-80 overflow-y-auto py-1">
            {chats.length === 0 && <p className="px-3 py-5 text-center text-[12.5px] text-white/40">No saved conversations yet.</p>}
            {chats.map((c) => (
              <button key={c.id} onClick={() => { setOpen(false); onPick(c.id); }}
                className="block w-full px-3 py-2 text-left transition hover:bg-white/[0.06]">
                <div className="truncate text-[13px] text-white">{c.title || "Conversation"}</div>
                <div className="text-[11px] text-white/40">{relTime(c.createdAt)}</div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function Home() {
  const appVersion = useAppVersion();
  const liveOpen = useUi((s) => s.liveOpen);
  const setLiveOpen = useUi((s) => s.setLiveOpen);
  const openSettings = useUi((s) => s.openSettings);
  const activeChatId = useUi((s) => s.activeChatId);
  const newConversation = useUi((s) => s.newConversation);
  const resumeChat = useUi((s) => s.resumeChat);
  const minimized = useUi((s) => s.minimized);

  // Warm the on-device voice models in the background as soon as the app loads, so
  // opening Live doesn't stall on "Preparing…". Only when the weights are already
  // cached — a fresh install still downloads via the explicit pre-call button (we
  // don't silently pull hundreds of MB on first launch).
  useEffect(() => {
    if (modelsCached() && !modelsReady()) void loadModels(() => {}).catch(() => {});
  }, []);

  const startNew = () => { newConversation(); setLiveOpen(true); };
  const resume = (id: string) => { resumeChat(id); setLiveOpen(true); };

  return (
    <main className="relative z-10 flex min-h-dvh flex-col items-center justify-center overflow-hidden px-6 text-center">
      {!minimized && (
        <>
          {/* Dark navy atmosphere — brand-first home, independent of light/dark tokens */}
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 -z-10"
            style={{
              background:
                "radial-gradient(ellipse 80% 60% at 50% 42%, #1a1f3d 0%, #0c101c 52%, #07090f 100%)",
            }}
          />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 -z-10 opacity-[0.35]"
            style={{
              backgroundImage: "url(/brand/nudge-card.png)",
              backgroundSize: "cover",
              backgroundPosition: "center",
              maskImage: "radial-gradient(ellipse 55% 50% at 50% 40%, black 10%, transparent 70%)",
              WebkitMaskImage: "radial-gradient(ellipse 55% 50% at 50% 40%, black 10%, transparent 70%)",
            }}
          />

          {/* Frameless-window drag handle: a top strip clear of the window controls
              (top-left) and the settings button (top-right). Desktop only (.desktop). */}
          <div className="app-drag fixed left-[90px] right-16 top-0 z-0 h-10" />
          <button onClick={openSettings} aria-label="Settings"
            className="absolute right-4 top-4 grid size-9 place-items-center rounded-lg text-white/45 transition hover:bg-white/10 hover:text-white/80">
            <Settings2 className="size-5" />
          </button>

          <div className="flex flex-col items-center gap-7">
            <div className="animate-[nudge-rise_0.9s_var(--ease-out-quart)_both]">
              <OpenLiveMark size={112} />
            </div>
            <div className="space-y-3 animate-[nudge-rise_0.9s_var(--ease-out-quart)_0.08s_both]">
              <h1 className="text-[42px] font-semibold tracking-[-0.03em] text-white">nudge</h1>
              <p className="max-w-sm text-[15px] leading-relaxed text-white/55">
                The quiet tutor that teaches you to think.
              </p>
            </div>
            <div className="flex items-center gap-3 animate-[nudge-rise_0.9s_var(--ease-out-quart)_0.16s_both]">
              <button onClick={startNew}
                className="flex items-center gap-2 rounded-full bg-[#4A42D3] px-7 py-3 text-[15px] font-medium text-white shadow-[0_0_32px_-8px_rgba(74,66,211,0.7)] transition duration-150 hover:scale-[1.03] hover:bg-[#5a52e0] active:scale-95">
                <Plus className="size-5" /> New
              </button>
              <ResumeMenu onPick={resume} />
            </div>
          </div>

          <footer className="absolute inset-x-0 bottom-4 flex items-center justify-center text-[11px] text-white/35">
            <a href="https://github.com/katipally/openlive/releases" target="_blank" rel="noreferrer" className="transition hover:text-white/60">
              {appVersion ? `v${appVersion}` : "dev"}
            </a>
          </footer>
        </>
      )}

      {liveOpen && <LiveDock key={activeChatId} chatId={activeChatId} onExit={() => setLiveOpen(false)} />}
      {!minimized && <SettingsModal />}
    </main>
  );
}
