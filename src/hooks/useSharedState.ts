import create from 'zustand'
import { initialState, SharedLyrixState } from '../../electron/store/common'

type LocalLyrixState = {
  receivedInitialState: boolean
  settingsOpen: boolean

  setReceivedInitialState: () => void
  setSettingsOpen: (settingsOpen: boolean) => void
}

export const useSharedState = create<LocalLyrixState & SharedLyrixState>((set) => ({
  ...initialState,
  receivedInitialState: false,
  settingsOpen: false,

  setReceivedInitialState: () => set((state) => ({ ...state, receivedInitialState: true })),
  setSettingsOpen: (settingsOpen) => set((state) => ({ ...state, settingsOpen })),
}))
export type { SharedLyrixState }
