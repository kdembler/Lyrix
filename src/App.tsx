import React from 'react'
import { MainWindow } from './components/MainWindow'
import { SpotifyManager } from './components/SpotifyManager'

export const App: React.FC = () => {
  return (
    <>
      <SpotifyManager />
      <MainWindow />
    </>
  )
}
