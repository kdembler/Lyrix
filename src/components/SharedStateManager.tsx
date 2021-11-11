import React, { useEffect } from 'react'
import { useApp } from '../hooks/useApp'
import { SharedLyrixState, useSharedState } from '../hooks/useSharedState'

export const SharedStateManager: React.FC = () => {
  useEffect(() => {
    const callback = (_: unknown, serializedState: string) => {
      console.log(`SharedStateManager: received state update`, serializedState)
      const newState = JSON.parse(serializedState) as SharedLyrixState
      useSharedState.setState({ ...newState, receivedInitialState: true })
    }

    window.Main.on('state_update', callback)

    return () => {
      window.Main.off('state_update', callback)
    }
  }, [])

  const { requestAction } = useApp()

  useEffect(() => {
    requestAction('sendState')
  }, [requestAction])

  return null
}
