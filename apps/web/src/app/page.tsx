"use client";

import { useState } from "react";
import { AudioLines, Settings2 } from "lucide-react";
import { useUi } from "@/lib/uiStore";
import { LiveDock } from "@/components/live/LiveDock";
import { SettingsModal } from "@/components/settings/SettingsModal";

export default function Home() {
  // One chat id per page load — the live session persists under it.
  const [chatId] = useState(() => (typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID() : `chat-${Date.now()}`));
  const liveOpen = useUi((s) => s.liveOpen);
  const setLiveOpen = useUi((s) => s.setLiveOpen);
  const openSettings = useUi((s) => s.openSettings);

  return (
    <main className="relative z-10 flex min-h-dvh flex-col items-center justify-center px-6 text-center">
      <button onClick={openSettings} aria-label="Settings"
        className="absolute right-4 top-4 grid size-9 place-items-center rounded-lg text-muted-foreground transition hover:bg-foreground/10 hover:text-foreground">
        <Settings2 className="size-5" />
      </button>

      <div className="flex flex-col items-center gap-6">
        <div className="grid size-16 place-items-center rounded-2xl bg-accent/10 text-accent">
          <AudioLines className="size-8" />
        </div>
        <div className="space-y-2">
          <h1 className="text-[32px] font-semibold tracking-tight">OpenLive</h1>
          <p className="max-w-md text-[14px] leading-relaxed text-muted-foreground">
            A live voice &amp; vision assistant. Talk to it, show it your camera, and it talks back in real time — the whole voice pipeline runs privately on your device.
          </p>
        </div>
        <button onClick={() => setLiveOpen(true)}
          className="flex items-center gap-2 rounded-full bg-accent px-7 py-3 text-[15px] font-medium text-accent-foreground shadow-lg transition duration-150 hover:scale-[1.03] hover:opacity-90 active:scale-95">
          <AudioLines className="size-5" /> Start a live call
        </button>
      </div>

      {liveOpen && <LiveDock chatId={chatId} onExit={() => setLiveOpen(false)} />}
      <SettingsModal />
    </main>
  );
}
