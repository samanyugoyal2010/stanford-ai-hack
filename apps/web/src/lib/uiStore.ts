import { create } from "zustand";

// App-wide UI state. Just the settings modal + whether a live call is open.
interface UiState {
  settingsOpen: boolean;
  openSettings: () => void;
  closeSettings: () => void;
  liveOpen: boolean;
  setLiveOpen: (v: boolean) => void;
}

export const useUi = create<UiState>((set) => ({
  settingsOpen: false,
  openSettings: () => set({ settingsOpen: true }),
  closeSettings: () => set({ settingsOpen: false }),
  liveOpen: false,
  setLiveOpen: (v) => set({ liveOpen: v }),
}));
