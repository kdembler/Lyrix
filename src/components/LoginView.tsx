import React from 'react'
import { ReactComponent as SpotifyIcon } from '../icons/spotify.svg'
import { useApp } from '../hooks/useApp'

export const LoginView: React.FC = () => {
  const { requestAction } = useApp()

  return (
    <button
      onClick={() => requestAction('authorize')}
      type="button"
      className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-xl text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
    >
      <SpotifyIcon className="mr-2 fill-current" aria-hidden="true" />
      Login with Spotify
    </button>
  )
}
