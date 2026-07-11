const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('lunar', {
  status: () => ipcRenderer.invoke('ollama-status'),
  chat: (prompt) => ipcRenderer.invoke('ollama-chat', prompt),
  scene: (payload) => ipcRenderer.invoke('ollama-scene', payload),
  pickImage: () => ipcRenderer.invoke('pick-image'),
  readImage: (filePath) => ipcRenderer.invoke('read-image', filePath)
});
