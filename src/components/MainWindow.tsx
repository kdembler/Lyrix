import React from 'react'
import { useSpotify, useSpotifyStore } from '../hooks/useSpotify'
import { MainView } from './MainView'
import { LoginView } from './LoginView'
import { useApp } from '../hooks/useApp'

export const MainWindow: React.FC = () => {
  const { isAuthorized, isAuthSet } = useSpotifyStore()
  const { requestQuit } = useApp()

  return (
    <div className="w-screen h-screen flex items-center justify-center bg-blue-50">
      {!isAuthSet ? <span>Loading...</span> : !isAuthorized ? <LoginView /> : <MainView />}
      <button onClick={requestQuit} className="absolute right-4 top-4 text-gray-400">
        Exit
      </button>
    </div>
  )
}
