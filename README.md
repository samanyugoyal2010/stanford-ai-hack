# StudyFlow

An AI-powered macOS study companion that observes a student's workflow in real time and provides Socratic guidance without directly giving answers.

## Features (current)

- Modular SwiftUI pipeline (capture → OCR → context → behavior → memory → AI → voice)
- **Learner Profile** setup via:
  - **Observe** — ScreenCaptureKit + Vision OCR samples sent to [EverOS](https://docs.evermind.ai) for profile extraction
  - **Describe** — paste a free-text learner profile
  - **Upload** — import `.txt` / `.md` profile files
- EverOS Cloud as durable memory (`profile` + `episodic_memory`); local cache for last snapshot

## Requirements

- macOS 14.0 or later
- Xcode 15+ (full Xcode app)
- EverOS Cloud API key from [everos.evermind.ai](https://everos.evermind.ai)
- Screen Recording permission when observing a session
- [Ollama](https://ollama.com) optional until local Gemma guidance is wired

## Configure EverOS API key

**Do not commit API keys.**

1. Open **Product → Scheme → Edit Scheme… → Run → Arguments → Environment Variables**
2. Add:
   - Name: `EVEROS_API_KEY`
   - Value: your key from the EverOS dashboard
3. Or store the key in Keychain via `EverOSCredentialStore` (service `com.studyflow.app.everos`)

If you previously pasted a key into chat or a shared doc, **rotate it** in the EverOS dashboard.

Optional Python smoke test (not required for the app):

```bash
pip install everos-cloud
export EVEROS_API_KEY="your-key"
python scripts/everos_smoke.py
```

## Open & Run

1. Open `StudyFlow.xcodeproj` in Xcode.
2. Set `EVEROS_API_KEY` on the scheme as above.
3. Select the **StudyFlow** scheme and a Mac destination.
4. Press **Run** (⌘R).
5. Open the **Learner Profile** tab:
   - Start Observation → study normally → Stop & Extract Profile
   - or Describe / Upload your profile
6. Grant **Screen Recording** when macOS prompts (System Settings → Privacy & Security → Screen Recording).

## Architecture

```
App
 → Screen Capture Manager (ScreenCaptureKit)
 → Vision OCR Manager
 → ObservationSessionCoordinator → EverOS Memory Service
 → ManualProfileIngestor → EverOS
 → Gemma Service (consumes EverOS profile later for Socratic prompts)
 → Voice Output Manager
```

Dependencies are constructed in `AppDependencyContainer` and injected into the UI.

## Bundle

- **Product name:** StudyFlow
- **Bundle identifier:** `com.studyflow.app`
- **Deployment target:** macOS 14.0
