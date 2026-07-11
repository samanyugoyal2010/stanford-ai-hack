# OpenLive Study Tutor (Ollama)

Fork of [OpenLive](https://github.com/katipally/openlive) with a **Study Tutor** mode: a live voice tutor that watches your screen while you study, stays quiet when you’re progressing, and speaks up with short Socratic hints when you’re stuck.

The voice loop (VAD / Whisper / Kokoro) still runs on-device. The brain defaults to **local Ollama** — nothing leaves your machine except HTTP to `localhost:11434`.

## Prerequisites

1. **Node.js** ≥ 22.13 and **pnpm** 11
2. **[Ollama](https://ollama.com)** installed and running
3. Pull a vision model (recommended):

```bash
ollama pull qwen2.5vl:7b
```

On a tighter machine:

```bash
ollama pull qwen2.5vl:3b
```

4. **macOS screen recording permission** for Electron / your browser when sharing a window or display (System Settings → Privacy & Security → Screen Recording).

## Run

```bash
pnpm install
pnpm desktop:dev      # Electron + local web + agent (ports 47824 / 47823)
# or browser-only:
pnpm dev              # then open http://localhost:3000
```

## Use Study Tutor

1. Open the app → start a **New** live call.
2. Leave mode on **Study Tutor** (default).
3. Set an optional **study goal** (e.g. `AP Chem chapter 4`) and how often to speak up (Quiet / Balanced / Active).
4. Confirm the model picker shows **Ollama (local)** + `qwen2.5vl:7b` (Settings defaults to this).
5. Download on-device voice models once if prompted, then **Start studying**.
6. Allow **screen share** when prompted — pick the PDF, notes, or worksheet window.
7. Study normally. Status shows **Watching · quiet** or **Watching your work…**. Ask questions out loud anytime (“am I doing this right?”).

Switch to **Assistant** in the lobby for classic OpenLive reactive chat without the proactive observe loop.

## How the tutor adapts

```
screen frames ──▶ observe loop (every ~4–10s) ──▶ Ollama vision model
                         │
                         ├─ SILENCE → stay quiet
                         └─ short hint / question → on-device TTS
```

- **Quiet / Balanced / Active** control how often proactive peeks can become spoken interventions.
- Server rate-limits spoken interventions (cooldown + max per minute).
- Prefer Socratic questions over full answers; use `remember` for lasting misconceptions.

## Defaults

| Setting | Value |
|---------|--------|
| Provider | `ollama` (`http://localhost:11434/v1`) |
| Live model | `qwen2.5vl:7b` |
| Session mode | Study Tutor |

Change provider/model anytime in Settings or the lobby quick-pick.

## Upstream OpenLive

Voice + vision plumbing, desktop shell, and BYO providers come from OpenLive (MIT). This fork adds Study Tutor session config, proactive `observe` turns, education prompts, and Ollama-first defaults.
