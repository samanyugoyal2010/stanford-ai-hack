"use strict";
// contextIsolation is on. Expose ONLY the tiny window-control bridge the minimized
// (floating-overlay) mode needs — nothing else.
const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("openlive", {
  // Enter minimized mode: shrink to a small always-on-top floating window.
  mini: (width, height) => ipcRenderer.send("openlive:mini", { width, height }),
  // Resize the floating window (e.g. when tiles toggle on/off).
  size: (width, height) => ipcRenderer.send("openlive:size", { width, height }),
  // Restore the normal window.
  unmini: () => ipcRenderer.send("openlive:unmini"),
  // True when running inside the desktop app.
  isDesktop: true,
  // App version, passed from main via additionalArguments (set from the release tag).
  version: (process.argv.find((a) => a.startsWith("--openlive-version=")) || "").split("=")[1] || "",
  // The native menu (⌘,) asks the UI to open Settings.
  onOpenSettings: (cb) => ipcRenderer.on("openlive:open-settings", () => cb()),
});
