# Lunar Electron Desktop Assistant

Lunar is an Electron/Node.js macOS desktop assistant for local Ollama chat, push-to-talk speech recognition, diagram uploads, and coarse editable 3D scene drafts rendered with Three.js.

## Run locally

```bash
npm install
ollama serve
ollama list
npm start
```

The app expects Ollama at `http://127.0.0.1:11434` and defaults to the model tag `gemma4:e2b-it-qat`. If your downloaded model uses another tag:

```bash
LUNAR_OLLAMA_MODEL=your-model-tag npm start
```

The model name is read by the Electron main process, keeping Ollama access outside the renderer. Upload an image, then choose `Generate 3D draft`; the result is a simple JSON scene made of boxes, spheres, and cylinders that can be orbited in the preview.

## Development

```bash
npm run check
npm run dev
```
