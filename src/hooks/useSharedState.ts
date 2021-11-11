import create from 'zustand'
import { initialState, SharedLyrixState } from '../../electron/store/common'

type LocalLyrixState = {
  receivedInitialState: boolean
  setReceivedInitialState: () => void
}

export const useSharedState = create<LocalLyrixState & SharedLyrixState>((set) => ({
  ...initialState,
  receivedInitialState: false,
  setReceivedInitialState: () => set((state) => ({ ...state, receivedInitialState: true })),
}))
export type { SharedLyrixState }
