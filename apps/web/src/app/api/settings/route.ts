import { NextResponse } from "next/server";
import { getAllSettings, setSetting } from "@openlive/db";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Provider + model are chosen live in Settings. This fork defaults to local
// Ollama + Qwen2.5-VL for Study Tutor (no cloud key required). Live effort
// defaults to "auto" (lowest the model supports → smoothest voice).
const DEFAULTS = {
  liveEffort: "auto",
  liveProviderId: "ollama",
  liveModel: "gemma4:e2b-it-qat",
  visionProviderId: "ollama",
  visionModel: "qwen2.5vl:7b",
};
const KEYS = ["liveModel", "liveProviderId", "liveEffort", "visionProviderId", "visionModel"];

export function GET() {
  const saved = getAllSettings() as Record<string, string>;
  const out: Record<string, string> = { ...DEFAULTS, ...saved };
  // Migrate older Study Tutor setups that used VL as the live talk model.
  const live = out.liveModel ?? "";
  if (/qwen2\.5vl|llava|vision/i.test(live) && !saved.visionModel) {
    out.visionProviderId = out.visionProviderId || "ollama";
    out.visionModel = live;
    out.liveModel = DEFAULTS.liveModel;
    setSetting("visionProviderId", out.visionProviderId);
    setSetting("visionModel", out.visionModel);
    setSetting("liveModel", out.liveModel);
  }
  if (!out.visionProviderId) out.visionProviderId = DEFAULTS.visionProviderId;
  if (!out.visionModel) out.visionModel = DEFAULTS.visionModel;
  return NextResponse.json(out);
}

export async function PUT(req: Request) {
  const body = (await req.json()) as Record<string, string>;
  for (const [k, v] of Object.entries(body)) {
    if (KEYS.includes(k) && typeof v === "string") setSetting(k, v);
  }
  return NextResponse.json({ ...DEFAULTS, ...getAllSettings() });
}
