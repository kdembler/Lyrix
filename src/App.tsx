import React from 'react'
import { MainWindow } from './components/MainWindow'
import { SharedStateManager } from './components/SharedStateManager'

export const App: React.FC = () => {
  return (
    <>
      <SharedStateManager />
      <MainWindow />
    </>
  )
}
