import { useCallback } from 'react'
import create from 'zustand'

type SpotifyStore = {
  isAuthorized: boolean
  isAuthSet: boolean

  setIsAuthorized: (isAuthorized: boolean) => void
  setIsAuthSet: (isAuthSet: boolean) => void
}

export const useSpotifyStore = create<SpotifyStore>((set) => ({
  isAuthorized: false,
  isAuthSet: false,

  setIsAuthorized: (isAuthorized) => set((state) => ({ ...state, isAuthorized })),
  setIsAuthSet: (isAuthSet) => set((state) => ({ ...state, isAuthSet })),
}))

export const useSpotify = () => {
  const requestAuthorize = useCallback(() => {
    console.log('Spotify:requestAuthorize()')
    window.Main.authorize()
  }, [])

  const requestRefresh = useCallback(() => {
    console.log('Spotify:requestRefresh()')
    window.Main.refresh()
  }, [])

  const requestLogout = useCallback(() => {
    console.log('Spotify:requestLogout()')
    window.Main.logout()
  }, [])

  return { requestAuthorize, requestRefresh, requestLogout }
}
