---
title: OpenLive
emoji: 🎙️
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
short_description: Live voice + vision AI assistant — the voice runs on-device
---

# OpenLive

A live voice + vision AI assistant. Talk to it, show it your camera, and it talks
back in real time.

The trick: the whole voice pipeline runs **in your browser** — voice activity
detection (Silero), speech-to-text (Whisper), end-of-turn detection (Smart-Turn),
and text-to-speech (Kokoro), all on-device via `transformers.js` + WebGPU. No
audio ever leaves your machine. The server is a thin proxy that takes your final
text (plus a camera frame when the camera's on), runs an ordinary streaming
chat-completion turn against the LLM you pick, and streams the reply text back —
which the browser speaks sentence-by-sentence as it arrives.

## Using it

1. Open **⚙ Settings** → pick a provider (Anthropic / OpenAI / MiniMax) → paste
   your API key → **Save**. The key is encrypted at rest on the server; the
   browser only ever sees the last 4 digits.
2. Pick a model. The list is fetched live from the provider, annotated with
   vision / reasoning / cost. Reasoning effort defaults to the lowest the model
   supports (smoothest voice); raise it for depth over latency.
3. **Start a live call** → download the on-device voice models once (~200 MB,
   cached after) → **Start** → talk. Turn the camera on to show it things; it can
   call `look` for a closer frame.

> The API key is shared by anyone who can open this instance — there's no login.
> Use a spend-limited key, or run a private copy.

## Running locally

```bash
pnpm install
pnpm dev          # web on :3000, agent on :8787 (predev frees the ports first)
```

Everything is configured in the UI — no `.env` required.

## Layout

```
apps/web        Next.js 16 + a custom server.mjs that proxies the /live WebSocket
                to the agent. The on-device voice engine lives in src/lib/live/*.
services/agent  Hono + ws. A thin LLM proxy: session lifecycle, barge-in, tools
                (fetch_url, look, update_todos), conversation persistence.
packages/shared The /live wire protocol + shared types.
packages/harness Provider-neutral LLM adapters, live model listing, cost/effort.
packages/db     SQLite: encrypted provider keys, settings, chats, messages.
```

## Deploy (Hugging Face Space)

A single Docker image runs web + agent together on port 7860 (see `Dockerfile` /
`docker-entrypoint.sh`), which is how this Space is built.
