"use client";

import { useEffect, useId, useRef } from "react";
import type { LivePhase } from "@/lib/live/liveStore";

// The Nudge mark: a rounded square with a blue→indigo gradient and a white
// two-stroke "n". ONE component everywhere: the animated in-call orb, the home
// hero + top-bar logo (idle pulse), and the static favicon.
//
// Live states drive glow / ring intensity (and a soft scale breath on pulse):
//   idle       → gentle breathing glow
//   listening  → glow rides YOUR mic level + soft rings
//   speaking   → glow rides the AGENT's voice level + soft rings
//   thinking/… → amber working shimmer
const BUSY = new Set<LivePhase>(["thinking", "connecting", "loading", "reconnecting"]);
const VOICE = new Set<LivePhase>(["listening", "speaking"]);

type Palette = { hi: string; mid: string; lo: string; ring: string; glow: string };

function paletteFor(phase: LivePhase): Palette {
  switch (phase) {
    case "listening":
      return { hi: "#3ecf8e", mid: "#1f8a5b", lo: "#0f3d2c", ring: "#4ade80", glow: "#43c286" };
    case "speaking":
      return { hi: "#5b6ef0", mid: "#3a3fbf", lo: "#1a1d5c", ring: "#8ba3f5", glow: "#6f8ce6" };
    case "thinking":
    case "connecting":
    case "loading":
    case "reconnecting":
      return { hi: "#f0a24a", mid: "#b5651c", lo: "#4a2a0c", ring: "#f2a24a", glow: "#f0a24a" };
    default:
      // Brand idle: bright blue → deep indigo (matches nudge-card)
      return { hi: "#4A42D3", mid: "#2E2F85", lo: "#181D3B", ring: "#6b74e8", glow: "#4A42D3" };
  }
}

export function OpenLiveOrb({
  phase = "idle",
  getLevels,
  getBands: _getBands,
  size = 240,
  pulse = false,
}: {
  phase?: LivePhase;
  getLevels?: () => { mic: number; agent: number };
  getBands?: () => { mic: number[]; agent: number[] };
  size?: number;
  pulse?: boolean;
}) {
  const uid = useId().replace(/[^a-zA-Z0-9]/g, "");
  const rootRef = useRef<SVGSVGElement | null>(null);
  const env = useRef(0);
  const phaseRef = useRef(phase);
  phaseRef.current = phase;
  const p = paletteFor(phase);
  const rings = !!getLevels && size >= 96 && VOICE.has(phase);
  const cTrans = "0.55s var(--ease-out-quart)";

  useEffect(() => {
    if (!getLevels && !pulse) return;
    const reduce = matchMedia?.("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;
    let t0 = 0;
    const loop = (ms: number) => {
      if (!t0) t0 = ms;
      const time = (ms - t0) / 1000;
      const ph = phaseRef.current;
      const el = rootRef.current;
      if (!el) {
        raf = requestAnimationFrame(loop);
        return;
      }

      let level = 0;
      if (getLevels && VOICE.has(ph)) {
        const { mic, agent } = getLevels();
        const raw = Math.min(1, ph === "listening" ? mic * 5 : agent * 6);
        env.current += (raw - env.current) * (raw > env.current ? 0.5 : 0.12);
        level = env.current;
      } else if (BUSY.has(ph)) {
        level = 0.35 + 0.25 * (0.5 + 0.5 * Math.sin(time * 4.2));
      } else if (pulse) {
        level = 0.12 + 0.1 * (0.5 + 0.5 * Math.sin(time * 1.5));
      }

      if (reduce) level = VOICE.has(ph) || BUSY.has(ph) ? 0.25 : 0.08;

      const scale = 1 + level * (size >= 96 ? 0.045 : 0.03);
      const glowPx = Math.round(size * (0.04 + level * 0.08));
      el.style.transform = `scale(${scale})`;
      el.style.filter = `drop-shadow(0 0 ${glowPx}px ${p.glow})`;

      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [getLevels, pulse, p.glow, size]);

  return (
    <svg
      ref={rootRef}
      width={size}
      height={size}
      viewBox="0 0 100 100"
      aria-hidden
      style={{
        overflow: "visible",
        filter: `drop-shadow(0 0 ${Math.round(size * 0.045)}px ${p.glow})`,
        transition: `filter ${cTrans}`,
        display: "block",
        transformOrigin: "center",
      }}
    >
      <defs>
        <linearGradient id={`nudge-${uid}`} x1="12" y1="8" x2="92" y2="96" gradientUnits="userSpaceOnUse">
          <stop offset="0%" style={{ stopColor: p.hi, transition: `stop-color ${cTrans}` }} />
          <stop offset="48%" style={{ stopColor: p.mid, transition: `stop-color ${cTrans}` }} />
          <stop offset="100%" style={{ stopColor: p.lo, transition: `stop-color ${cTrans}` }} />
        </linearGradient>
      </defs>
      {rings && (
        <style>{
          `@keyframes olwr-${uid}{0%{transform:scale(.92);opacity:.45}100%{transform:scale(1.7);opacity:0}}` +
          `.olwr-${uid}{transform-box:fill-box;transform-origin:center;animation:olwr-${uid} 2.6s var(--ease-out-quart) infinite}`
        }</style>
      )}
      {rings &&
        [0, 1, 2].map((k) => (
          <rect
            key={`r${k}`}
            className={`olwr-${uid}`}
            x="4"
            y="4"
            width="92"
            height="92"
            rx="22"
            fill="none"
            style={{ stroke: p.ring, transition: `stroke ${cTrans}`, animationDelay: `${k * 0.87}s` }}
            strokeWidth="1.2"
          />
        ))}
      <rect width="100" height="100" rx="22" fill={`url(#nudge-${uid})`} />
      <path
        d="M34 70V42L50 28"
        fill="none"
        stroke="#ffffff"
        strokeWidth="11.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path d="M63 28V70" fill="none" stroke="#ffffff" strokeWidth="11.5" strokeLinecap="round" />
    </svg>
  );
}
