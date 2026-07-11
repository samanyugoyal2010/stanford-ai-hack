# Lunar

Lunar is a native macOS SwiftUI desktop assistant that talks to a local Ollama model and turns uploaded diagrams into coarse, editable 3D scene drafts.

## Run in Xcode

1. Install the full Xcode app and select it in Xcode > Settings > Locations, or run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.
2. Open `Package.swift` in Xcode.
3. Ensure Ollama is running with `ollama serve` and that the local model name is available as `gemma4`.
4. If the model has another tag, set the scheme environment variable `LUNAR_OLLAMA_MODEL` to that tag.
5. Add microphone and speech-recognition usage descriptions to the app target's Info settings before using voice input.

The Ollama endpoint defaults to `http://127.0.0.1:11434`. The scene generator accepts a JSON scene description and falls back to a starter scene if the response cannot be decoded.

## Layout

- `LunarApp.swift`: app entry point.
- `ContentView.swift`: conversation and workspace UI.
- `OllamaClient.swift`: local inference and scene JSON transport.
- `VoiceAgent.swift`: push-to-talk speech capture plumbing.
- `ScenePreview.swift`: native SceneKit renderer.
- `Models.swift`: observable workspace state and feature orchestration.
