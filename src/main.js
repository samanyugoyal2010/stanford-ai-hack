const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const fs = require('node:fs/promises');
const path = require('node:path');

const ollamaURL = process.env.LUNAR_OLLAMA_URL || 'http://127.0.0.1:11434';
const ollamaModel = process.env.LUNAR_OLLAMA_MODEL || 'gemma4:e2b-it-qat';

async function ollama(pathname, body) {
  const response = await fetch(`${ollamaURL}/${pathname}`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body)
  });
  if (!response.ok) throw new Error(`Ollama returned ${response.status}`);
  return response.json();
}

function createWindow() {
  const window = new BrowserWindow({ width: 1280, height: 820, minWidth: 980, minHeight: 680, titleBarStyle: 'hiddenInset', webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, nodeIntegration: false } });
  window.loadFile(path.join(__dirname, 'index.html'));
}

ipcMain.handle('ollama-status', async () => {
  try { const response = await fetch(`${ollamaURL}/api/tags`); if (!response.ok) throw new Error(); const data = await response.json(); return { online: true, model: data.models?.[0]?.name || ollamaModel }; }
  catch { return { online: false, model: ollamaModel }; }
});
ipcMain.handle('ollama-chat', async (_, prompt) => (await ollama('api/chat', { model: ollamaModel, messages: [{ role: 'user', content: prompt }], stream: false })).message.content);
ipcMain.handle('ollama-scene', async (_, { prompt, image }) => {
  const data = await ollama('api/generate', { model: ollamaModel, prompt: `${prompt} Return JSON only.`, format: 'json', images: image ? [image] : undefined, stream: false });
  return JSON.parse(data.response);
});
ipcMain.handle('pick-image', async () => { const result = await dialog.showOpenDialog({ properties: ['openFile'], filters: [{ name: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp'] }] }); return result.canceled ? null : result.filePaths[0]; });
ipcMain.handle('read-image', async (_, filePath) => (await fs.readFile(filePath)).toString('base64'));

app.whenReady().then(() => { createWindow(); app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); }); });
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
