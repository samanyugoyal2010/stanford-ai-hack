"use client";

import { useEffect, useRef } from "react";

// The shared screen/window, shown large in the stage (Google-Meet style).
export function ScreenView({ stream }: { stream: MediaStream | null }) {
  const ref = useRef<HTMLVideoElement>(null);
  useEffect(() => { if (ref.current) ref.current.srcObject = stream; }, [stream]);
  return (
    <div className="flex h-full w-full items-center justify-center p-4">
      <video ref={ref} autoPlay muted playsInline
        className="max-h-full max-w-full rounded-xl border border-border bg-black object-contain shadow-2xl" />
    </div>
  );
}
