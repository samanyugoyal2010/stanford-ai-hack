# OpenLive

A live voice + vision AI assistant. Talk to it, show it your camera, and it talks
back in real time.

The whole voice pipeline runs **on-device** — voice activity detection (Silero),
speech-to-text (Whisper), end-of-turn detection (Smart-Turn), and text-to-speech
(Kokoro), via `transformers.js` + WebGPU. No audio leaves your machine. A local
agent runs the LLM turn (against the provider you pick) and streams the reply
back over a WebSocket; the browser speaks it sentence-by-sentence. Barge-in
cancels instantly.

## This branch: the desktop app (lowest latency)

`main` is the **native desktop app** (macOS + Windows, built with Electron). It
runs the web + agent servers locally — warm, persistent WebSocket, no cold
starts, no network hop — so it's the fastest way to use OpenLive. Keys/settings/
chats are small JSON files on disk (AES-256-GCM for keys); no native modules.

- **Develop:** `pnpm install && pnpm desktop:dev`
- **Build:** `pnpm desktop:build:mac` / `pnpm desktop:build:win`
- **Package details + Apple signing/notarization:** see [`apps/desktop/README.md`](apps/desktop/README.md)

You can also run it in a browser during development: `pnpm dev` → localhost:3000.

## Releasing (maintainers)

CI (`.github/workflows/ci.yml`) typechecks every push/PR. Cutting a release is one
tag — `.github/workflows/release.yml` then builds the Mac (arm64 + x64 DMG) and
Windows (x64 NSIS) installers on their native runners and uploads them to a
**draft** GitHub Release:

```bash
# bump the version in BOTH package.jsons, then:
git tag v0.1.1 && git push origin v0.1.1
```

The tag must equal `apps/desktop/package.json` "version" (the workflow fails fast
otherwise). When it finishes, open the draft release, sanity-check the assets, and
Publish.

**Mac signing/notarization** happens automatically when these repo **Secrets** are
set (Settings → Secrets and variables → Actions); without them the DMG builds
unsigned:

| Secret | What it is |
|---|---|
| `MAC_CSC_LINK` | base64 of your **Developer ID Application** `.p12` cert (`base64 -i cert.p12 \| pbcopy`) |
| `MAC_CSC_KEY_PASSWORD` | password for that `.p12` |
| `APPLE_ID` | your Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD` | app-specific password from appleid.apple.com |
| `APPLE_TEAM_ID` | Team ID from developer.apple.com → Membership |

Windows installers ship unsigned (SmartScreen shows a one-time warning); add a code
cert later if desired — see [`apps/desktop/README.md`](apps/desktop/README.md).

## Other branches

| Branch | What it is | Host |
|---|---|---|
| `main` | Desktop app (Electron), WebSocket agent — lowest latency | local app |
| `docker-websocket` | Same WebSocket app as a single Docker image | self-host / Koyeb |
| `serverless-sse` | Serverless rewrite: one streaming `/api/turn` per turn, BYOK | Vercel (free) |

## Using it

1. **⚙ Settings** → pick a provider (Anthropic / OpenAI / MiniMax) → paste your
   API key → **Save** (encrypted at rest; the UI only ever shows the last 4).
2. Pick a model — fetched live from the provider, annotated with vision /
   reasoning / cost. Effort defaults to the lowest the model supports (snappiest
   voice); raise it for depth.
3. **Start a live call** → download the on-device voice models once (~200 MB,
   cached) → **Start** → talk. Turn the camera on to show it things.

## Layout

```
apps/desktop     Electron shell: spawns the servers, media perms, window, splash
apps/web         Next.js UI + on-device voice engine (src/lib/live/*) + /api settings
services/agent   Hono + ws — the /live WebSocket, tools (fetch_url, look, update_todos)
packages/shared  wire protocol + shared types
packages/harness provider-neutral LLM adapters, live model listing, cost/effort
packages/db      JSON-file store: encrypted keys, settings, conversations
```
