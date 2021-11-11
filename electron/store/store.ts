import create from 'zustand'
import { initialState, SharedLyrixState } from './common'
import { Track } from '../spotify/track'
import { Profile } from '../spotify/profile'

type SharedLyrixStateWithActions = SharedLyrixState & {
  setIsAuthorized: (isAuthorized: boolean) => void
  setCurrentTrack: (track: Track | null) => void
  setUserProfile: (profile: Profile | null) => void
}

export const sharedLyrixStore = create<SharedLyrixStateWithActions>((set) => ({
  ...initialState,

  setIsAuthorized: (isAuthorized) => set((state) => ({ ...state, isAuthorized })),
  setCurrentTrack: (track) => set((state) => ({ ...state, currentTrack: track })),
  setUserProfile: (profile) => set((state) => ({ ...state, userProfile: profile })),
}))

type StateKey = keyof SharedLyrixState

export const serializeState = (state: SharedLyrixStateWithActions) => {
  const whitelist: StateKey[] = ['currentTrack', 'isAuthorized', 'userProfile']
  const filteredState = whitelist.reduce((acc, key) => {
    acc[key] = state[key]
    return acc
  }, {} as Record<StateKey, unknown>)
  return JSON.stringify(filteredState)
}
