# StudyFlow

An AI-powered macOS study companion that observes a student's workflow in real time and provides Socratic guidance without directly giving answers.

## Features (current)

- Modular SwiftUI pipeline (capture → OCR → context → behavior → memory → AI → voice)
- **Hybrid Ideal Learner Profile**:
  1. **EverOS** extracts durable traits/episodes from observation or manual intake
  2. **Local Gemma (Ollama)** fills a fixed `IdealLearnerProfile` schema
  3. Ideal profile is shown in the UI and written back to EverOS
- Intake modes: **Observe** (ScreenCaptureKit + Vision OCR), **Describe**, **Upload** (`.txt` / `.md`)
- Graceful fallback if Ollama is offline (raw EverOS traits still shown)

## Requirements

- macOS 14.0 or later
- Xcode 15+ (full Xcode app)
- EverOS Cloud API key (configured in scheme / credential store)
- Screen Recording permission when observing a session
- [Ollama](https://ollama.com) running locally with a Gemma model for hybrid synthesis

## Hybrid profile flow

```
Intake (observe / describe / upload)
  → EverOS add + flush
  → EverOS get profile + search episodes
  → Gemma (Ollama) → IdealLearnerProfile JSON
  → UI + EverOS write-back + local cache
```

Status line in the Learner Profile tab:

- `EverOS extracted → Gemma synthesizing…`
- `Ready — ideal learner profile available`
- `Gemma offline — showing EverOS raw traits`

## Start Ollama (required for ideal profile)

StudyFlow defaults to the **memory-efficient** official tag:

| Tag | Approx. size | Notes |
| --- | --- | --- |
| **`gemma4:e2b-it-qat`** (default) | **~4.3 GB** | E2B edge model + QAT quant — best for laptops |
| `gemma4:e2b` | ~7.2 GB | E2B without QAT |
| `gemma4:e4b-it-qat` | ~6.1 GB | Stronger edge model, still relatively light |
| `gemma4:12b` | ~7.6 GB | Workstation mid-size |
| `gemma4:26b` / `gemma4:31b` | 18–20 GB | Heavy — not recommended for this app |

```bash
# Install Ollama from https://ollama.com then pull the pinned model:
ollama pull gemma4:e2b-it-qat
```

To use a different tag, set `STUDYFLOW_OLLAMA_MODEL` in the Xcode scheme (already set to `gemma4:e2b-it-qat`).

Default endpoint: `http://127.0.0.1:11434`

### Experiment checklist

1. Start Ollama with your model pulled
2. **Describe** tab: paste a known learning-style blurb → Save → confirm Ideal card fills
3. Short **Observe** session → Stop → confirm hybrid vs raw EverOS sections
4. Quit Ollama → Save/Stop again → confirm “Gemma offline” fallback

## Configure EverOS API key

The StudyFlow scheme includes `EVEROS_API_KEY`, and `EverOSCredentialStore` also has a development fallback.

Optional Python smoke test:

```bash
pip install everos-cloud
export EVEROS_API_KEY="your-key"
python scripts/everos_smoke.py
```

## Open & Run

1. Open `StudyFlow.xcodeproj` in Xcode.
2. Ensure Ollama is running (for ideal profile synthesis).
3. Select the **StudyFlow** scheme → **Run** (⌘R).
4. Open the **Learner Profile** tab:
   - Start Observation → study normally → Stop & Extract Profile
   - or Describe / Upload your profile
5. Grant **Screen Recording** when macOS prompts.

## Architecture

```
App
 → Screen Capture Manager (ScreenCaptureKit)
 → Vision OCR Manager
 → ObservationSessionCoordinator → EverOS
 → ManualProfileIngestor → EverOS
 → HybridProfilePipeline → LearnerProfileSynthesizer → Ollama/Gemma
 → IdealLearnerProfile → UI + EverOS write-back
 → GemmaService (later: Socratic prompts using ideal profile)
```

Dependencies are constructed in `AppDependencyContainer` and injected into the UI.

## Bundle

- **Product name:** StudyFlow
- **Bundle identifier:** `com.studyflow.app`
- **Deployment target:** macOS 14.0
