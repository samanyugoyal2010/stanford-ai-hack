"use client";

// The in-call voice orb is the shared Nudge mark (rounded square + "n"), driven
// live by mic/agent level. Thin re-export so existing call sites stay stable.
export { OpenLiveOrb as Orb } from "@/components/OpenLiveOrb";
