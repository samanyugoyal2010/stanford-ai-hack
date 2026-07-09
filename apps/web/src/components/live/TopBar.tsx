"use client";

import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { History, Plus, Settings2, Trash2, Check } from "lucide-react";
import { api } from "@/lib/api";
import { useUi } from "@/lib/uiStore";
import { Logo } from "./Logo";
import { cn } from "@/lib/cn";

// The persistent top bar: logo, a conversation-history dropdown, and settings.
// Draggable (moves the desktop window) except over the interactive controls.
export function TopBar({ chatId, onSelect, onNew }: {
  chatId: string;
  onSelect: (id: string) => void;
  onNew: () => void;
}) {
  const openSettings = useUi((s) => s.openSettings);
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const qc = useQueryClient();
  const { data: chats = [] } = useQuery({ queryKey: ["chats"], queryFn: api.chats, enabled: open });
  const del = useMutation({ mutationFn: (id: string) => api.deleteChat(id), onSuccess: () => qc.invalidateQueries({ queryKey: ["chats"] }) });

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => { if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpen(false); };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  return (
    <header className="fixed inset-x-0 top-0 z-50 flex h-14 items-center justify-between px-4" style={{ WebkitAppRegion: "drag" } as React.CSSProperties}>
      {/* pl leaves room for the macOS traffic lights */}
      <div className="pl-16" style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}><Logo /></div>

      <div className="flex items-center gap-1.5" style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}>
        <div ref={rootRef} className="relative">
          <button onClick={() => setOpen((o) => !o)}
            className="flex h-9 items-center gap-1.5 rounded-lg px-3 text-[13px] text-muted-foreground transition hover:bg-foreground/10 hover:text-foreground">
            <History className="size-4" /> History
          </button>
          {open && (
            <div className="absolute right-0 mt-1.5 w-72 overflow-hidden rounded-xl border border-border bg-popover shadow-xl">
              <button onClick={() => { onNew(); setOpen(false); }}
                className="flex w-full items-center gap-2 border-b border-border px-3 py-2.5 text-[13px] text-foreground transition hover:bg-foreground/[0.06]">
                <Plus className="size-4" /> New conversation
              </button>
              <div className="takt-scroll max-h-80 overflow-y-auto py-1">
                {chats.length === 0 && <p className="px-3 py-4 text-center text-[12px] text-faint">No conversations yet.</p>}
                {chats.map((c) => (
                  <div key={c.id} className={cn("group flex items-center gap-1 px-2 py-1.5 transition hover:bg-foreground/[0.04]", c.id === chatId && "bg-foreground/[0.06]")}>
                    <button onClick={() => { onSelect(c.id); setOpen(false); }} className="min-w-0 flex-1 px-1 text-left">
                      <div className="truncate text-[13px] text-foreground">{c.title}</div>
                      <div className="text-[11px] text-faint">{new Date(c.createdAt).toLocaleString([], { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })}</div>
                    </button>
                    {c.id === chatId && <Check className="size-3.5 shrink-0 text-accent" />}
                    <button onClick={() => del.mutate(c.id)} title="Delete conversation" aria-label="Delete conversation"
                      className="grid size-7 shrink-0 place-items-center rounded text-faint opacity-0 transition hover:text-danger group-hover:opacity-100">
                      <Trash2 className="size-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
        <button onClick={openSettings} aria-label="Settings"
          className="grid size-9 place-items-center rounded-lg text-muted-foreground transition hover:bg-foreground/10 hover:text-foreground">
          <Settings2 className="size-5" />
        </button>
      </div>
    </header>
  );
}
