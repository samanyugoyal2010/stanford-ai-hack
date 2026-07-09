"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { KeyRound, Check, Trash2, ShieldAlert, Eye, Brain, Zap } from "lucide-react";
// Pure subpaths only — the barrel pulls in catalog/models (node:fs), which can't
// bundle into this client component.
import { BUILTIN_PROVIDERS } from "@openlive/harness/registry";
import { allowedEfforts } from "@openlive/harness/types";
import { modelVision } from "@openlive/shared";
import { api, type ModelInfo } from "@/lib/api";
import { cn } from "@/lib/cn";

const inputCls = "w-full rounded-lg border border-border bg-card px-3 py-2 text-[13px] text-foreground outline-none placeholder:text-faint focus:border-border-heavy";
const fmtCtx = (n?: number) => (n ? (n >= 1_000_000 ? `${n / 1_000_000}M` : `${Math.round(n / 1000)}k`) : "—");

// Every provider the harness supports. `protocol` drives which reasoning efforts
// a model can take.
const PROVIDERS = BUILTIN_PROVIDERS.map((p) => ({ id: p.id, name: p.name, protocol: p.protocol, keyless: !!p.keyless }));

// API-key entry bound to one provider (by registry id). Upserts the DB row on save.
function ProviderKey({ kind }: { kind: string }) {
  const qc = useQueryClient();
  const { data: providers = [] } = useQuery({ queryKey: ["providers"], queryFn: api.providers });
  const row = providers.find((p) => p.kind === kind);
  const info = PROVIDERS.find((p) => p.id === kind);
  const [key, setKey] = useState("");
  const refresh = () => { qc.invalidateQueries({ queryKey: ["providers"] }); qc.invalidateQueries({ queryKey: ["models"] }); };
  const save = useMutation({ mutationFn: () => api.setProviderKey(kind, key.trim()), onSuccess: () => { setKey(""); refresh(); } });
  const remove = useMutation({ mutationFn: () => api.removeProviderKey(row!.id), onSuccess: refresh });

  if (info?.keyless) return <p className="mt-2 text-[12px] text-muted-foreground">No key needed — {info.name} is a local provider.</p>;

  return (
    <div className="mt-3 flex flex-wrap items-center gap-2">
      <div className="flex flex-1 items-center gap-2 rounded-lg border border-border bg-card px-3 py-2 text-[12.5px] text-muted-foreground">
        {row?.hasKey
          ? <><Check className="size-3.5 text-success" /> Key set · ••••{row.keyLast4}</>
          : "No key set"}
      </div>
      <input value={key} onChange={(e) => setKey(e.target.value)} type="password" name={`${kind}-api-key`}
        placeholder={`Paste ${info?.name ?? kind} key`} aria-label={`${info?.name ?? kind} API key`}
        onKeyDown={(e) => { if (e.key === "Enter" && key.trim()) save.mutate(); }}
        className="w-56 rounded-lg border border-border bg-card px-3 py-2 text-[12.5px] text-foreground outline-none focus:border-border-heavy" />
      <button onClick={() => save.mutate()} disabled={!key.trim() || save.isPending}
        className="flex items-center gap-1.5 rounded-lg bg-foreground px-3 py-2 text-[13px] font-medium text-background transition hover:opacity-90 disabled:opacity-30">
        {save.isSuccess ? <Check className="size-4" /> : <KeyRound className="size-4" />} Save
      </button>
      {row?.hasKey && (
        <button onClick={() => remove.mutate()} disabled={remove.isPending} title="Remove the stored key"
          className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-[13px] text-muted-foreground transition hover:border-border-heavy hover:text-foreground">
          <Trash2 className="size-4" /> Remove
        </button>
      )}
      {save.isError && <p className="w-full text-[12px] text-destructive">{(save.error as Error).message}</p>}
    </div>
  );
}

// Per-model capability badges surfaced right in the picker.
function ModelBadges({ providerId, m }: { providerId: string; m?: ModelInfo }) {
  if (!m) return null;
  const vision = modelVision(providerId, m.id);
  return (
    <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-[11.5px] text-muted-foreground">
      {vision && <span className="inline-flex items-center gap-1 text-foreground"><Eye className="size-3.5" /> vision</span>}
      {m.reasoning && <span className="inline-flex items-center gap-1 text-foreground"><Brain className="size-3.5" /> reasoning</span>}
      {!m.reasoning && <span className="inline-flex items-center gap-1"><Zap className="size-3.5" /> fast</span>}
      <span>Context <b className="text-foreground">{fmtCtx(m.contextWindow)}</b></span>
      {m.maxOutput ? <span>Max out <b className="text-foreground">{Math.round(m.maxOutput / 1000)}k</b></span> : null}
      {m.cost ? <span>${m.cost.input}/M in</span> : null}
      {m.cost ? <span>${m.cost.output}/M out</span> : null}
    </div>
  );
}

export function ModelsSettings() {
  const qc = useQueryClient();
  const { data: providers = [] } = useQuery({ queryKey: ["providers"], queryFn: api.providers });
  const { data: settings } = useQuery({ queryKey: ["settings"], queryFn: api.settings });

  const providerId = settings?.liveProviderId ?? providers.find((p) => p.isDefault)?.kind ?? providers[0]?.kind ?? PROVIDERS[0]!.id;
  const { data: models = [] } = useQuery({ queryKey: ["models", providerId], queryFn: () => api.models(providerId), enabled: !!providerId });

  const saveSetting = useMutation({
    mutationFn: (b: Record<string, string>) => api.updateSettings(b),
    onSuccess: (s) => qc.setQueryData(["settings"], s),
  });

  const provider = PROVIDERS.find((p) => p.id === providerId);
  const model = models.find((m) => m.id === settings?.liveModel);
  // "auto" = lowest the model supports (smoothest voice); the rest are overrides.
  const efforts = ["auto", ...allowedEfforts(provider?.protocol, model?.reasoning ?? true)];
  const effort = settings?.liveEffort ?? "auto";

  const changeModel = (id: string) => {
    const m = models.find((x) => x.id === id);
    const eff = ["auto", ...allowedEfforts(provider?.protocol, m?.reasoning ?? true)];
    const patch: Record<string, string> = { liveModel: id };
    if (effort !== "auto" && !eff.includes(effort)) patch.liveEffort = "auto";
    saveSetting.mutate(patch);
  };

  return (
    <div className="flex flex-col gap-7">
      <div>
        <h2 className="text-[15px] font-semibold">Provider &amp; API key</h2>
        <p className="mt-1 text-[12.5px] text-muted-foreground">
          Pick a provider and paste its key. The key is encrypted at rest on this machine — only the last 4 digits are ever shown, and it never reaches the browser again.
        </p>
        <div className="mt-3 inline-flex flex-wrap gap-1 rounded-lg border border-border bg-card p-1">
          {PROVIDERS.map((p) => (
            <button key={p.id} onClick={() => saveSetting.mutate({ liveProviderId: p.id, liveModel: "" })}
              className={cn("rounded-md px-3.5 py-1.5 text-[13px] font-medium transition",
                providerId === p.id ? "bg-foreground text-background shadow-sm" : "text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground")}>
              {p.name}
            </button>
          ))}
        </div>
        <ProviderKey kind={providerId} />
        <div className="mt-3 flex items-start gap-2 rounded-lg border border-border bg-surface px-3 py-2 text-[12px] text-muted-foreground">
          <ShieldAlert className="mt-0.5 size-3.5 shrink-0 text-arc" />
          <span>This key is shared by anyone who can open this instance (there&apos;s no login). Use a spend-limited key, or remove it when you&apos;re done.</span>
        </div>
      </div>

      <div>
        <h2 className="text-[15px] font-semibold">Model</h2>
        <p className="mt-1 text-[12.5px] text-muted-foreground">
          Fetched live from {provider?.name}. Pick a fast one with vision — in a voice call, time-to-first-word matters and the camera needs a model that can see.
        </p>
        <select className={cn(inputCls, "mt-3 max-w-md")} value={settings?.liveModel ?? ""} onChange={(e) => changeModel(e.target.value)}>
          <option value="" disabled>{models.length ? "Select a model…" : "Add a key to load models…"}</option>
          {models.map((m) => {
            const vision = modelVision(providerId, m.id);
            return <option key={m.id} value={m.id}>{m.display_name}{vision ? " · vision" : ""}{m.reasoning ? " · reasoning" : ""}</option>;
          })}
        </select>
        <ModelBadges providerId={providerId} m={model} />
      </div>

      <div>
        <h2 className="text-[15px] font-semibold">Reasoning effort</h2>
        <p className="mt-1 text-[12.5px] text-muted-foreground">
          <b className="text-foreground">Auto</b> keeps the voice snappy (lowest the model supports). Raise it for deeper answers — but higher effort means a longer pause before it starts speaking. Levels adapt to the selected model.
        </p>
        <div className="mt-3 inline-flex rounded-lg border border-border bg-card p-1">
          {efforts.map((e) => (
            <button key={e} onClick={() => saveSetting.mutate({ liveEffort: e })}
              className={cn("rounded-md px-3.5 py-1.5 text-[12.5px] font-medium capitalize transition",
                effort === e ? "bg-foreground text-background shadow-sm" : "text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground")}>
              {e}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
