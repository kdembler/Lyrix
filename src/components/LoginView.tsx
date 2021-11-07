import React from 'react'
import { useSpotify } from '../hooks/useSpotify'
import { ReactComponent as SpotifyIcon } from '../icons/spotify.svg'

export const LoginView: React.FC = () => {
  const { requestAuthorize } = useSpotify()
  return (
    <button
      onClick={requestAuthorize}
      type="button"
      className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-xl text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
    >
      <SpotifyIcon className="mr-2 fill-current" aria-hidden="true" />
      Login with Spotify
    </button>
  )
}
