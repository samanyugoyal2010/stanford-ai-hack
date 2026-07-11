# Nudge

The quiet tutor that teaches you to think.

Fork of [OpenLive](https://github.com/katipally/openlive): a live voice tutor that watches your screen while you study, stays quiet when you’re progressing, and speaks up with short Socratic hints when you’re stuck.

Voice (VAD / Whisper / Kokoro) runs on-device. The brain uses **two local Ollama models**:

| Role | Default model | Job |
|------|---------------|-----|
| **Talk** | `gemma4:e2b-it-qat` | Fast spoken replies (no big image prefill) |
| **Eyes** | `qwen2.5vl:7b` | Screen observe + cached summaries |

## Prerequisites

1. **Node.js** ≥ 22.13 and **pnpm** 11
2. **[Ollama](https://ollama.com)** installed and running
3. Pull both models:

```bash
ollama pull gemma4:e2b-it-qat   # fast talk
ollama pull qwen2.5vl:7b       # vision eyes
```

Talk fallback if Gemma isn’t available:

```bash
ollama pull llama3.2
```

Lighter eyes:

```bash
ollama pull qwen2.5vl:3b
```

4. **macOS screen recording permission** for Electron (System Settings → Privacy & Security → Screen Recording).

## Run

```bash
pnpm install
pnpm desktop:dev      # Electron + local web + agent (ports 47824 / 47823)
# or browser-only:
pnpm dev              # then open http://localhost:3000
```

## Use Nudge

1. Open the app → **New** live call.
2. Set an optional **study goal** and how often to speak up.
3. Confirm Settings: Talk = `gemma4:e2b-it-qat`, Eyes (vision) = `qwen2.5vl:7b`.
4. Download on-device voice models once if prompted → **Start studying**.
5. Allow **screen share** — pick your PDF / notes / worksheet.
6. The window shrinks to a **floating sphere** (top-right, always on top). Study normally; click the sphere to open the full UI; minimize to return to the sphere.
7. Ask questions out loud anytime (“am I doing this right?”).

## How it stays fast

```
screen ──▶ observe (qwen2.5vl, small JPEG) ──▶ SUMMARY cache + optional short SPEAK
mic    ──▶ talk (gemma4) + cached SUMMARY ──▶ on-device TTS
```

Spoken turns do **not** re-send full screen frames to the vision model every time.

## Sphere UX

- After start: auto-collapse to a ~64px always-on-top orb
- **Click orb** → full Nudge interface
- **Minimize** in the full UI → back to the orb

## Upstream OpenLive

Voice + vision plumbing and desktop shell come from OpenLive (MIT). This product rebrands as Nudge: quiet screen tutoring, dual Ollama Talk/Eyes defaults, and the floating sphere.
