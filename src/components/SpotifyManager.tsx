import React, { useEffect } from 'react'
import { useSpotify, useSpotifyStore } from '../hooks/useSpotify'

export const SpotifyManager: React.FC = () => {
  const { setIsAuthorized, setIsAuthSet } = useSpotifyStore()
  const { requestRefresh } = useSpotify()

  useEffect(() => {
    console.log(`SpotifyManager: adding auth callback`)
    const callback = (_: unknown, isAuthorized: boolean) => {
      console.log('Spotify:authorize changed', isAuthorized)
      setIsAuthorized(isAuthorized)
      setIsAuthSet(true)
    }

    window.Main.on('authorized_change', callback)
    return () => {
      console.log(`SpotifyManager: removing auth callback`)

      window.Main.off('authorized_change', callback)
    }
  }, [setIsAuthSet, setIsAuthorized])

  useEffect(() => {
    console.log(`SpotifyManager: requesting auth status`)
    requestRefresh()
  }, [requestRefresh])

  return null
}
