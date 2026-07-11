const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('lunar', {
  status: () => ipcRenderer.invoke('ollama-status'),
  chat: (prompt) => ipcRenderer.invoke('ollama-chat', prompt),
  scene: (payload) => ipcRenderer.invoke('ollama-scene', payload),
  pickImage: () => ipcRenderer.invoke('pick-image'),
  readImage: (filePath) => ipcRenderer.invoke('read-image', filePath)
  ,fetchAccurateModel: () => ipcRenderer.invoke('fetch-accurate-model')
  ,pickModel: () => ipcRenderer.invoke('pick-model')
  ,readModel: (filePath) => ipcRenderer.invoke('read-model', filePath)
  ,blenderStatus: () => ipcRenderer.invoke('blender-status')
  ,chooseReferences: () => ipcRenderer.invoke('choose-references')
  ,runBlenderPipeline: (payload) => ipcRenderer.invoke('run-blender-pipeline', payload)
});
