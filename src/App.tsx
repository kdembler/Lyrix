import React from 'react'
import { Window } from './components/Window'
import { SharedStateManager } from './components/SharedStateManager'

export const App: React.FC = () => {
  return (
    <>
      <SharedStateManager />
      <Window />
    </>
  )
}
