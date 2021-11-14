import React from 'react'
import { TrackView } from './TrackView'
import { LoginView } from './LoginView'
import { useSharedState } from '../hooks/useSharedState'
import { ProfileSection } from './ProfileSection'
import { ActionsSection } from './ActionsSection'
import { SettingsOverlay } from './SettingsOverlay'

export const Window: React.FC = () => {
  const { isAuthorized, receivedInitialState } = useSharedState()

  return (
    <div className="w-screen h-screen flex flex-col bg-green-50 overflow-hidden">
      <div className="overflow-hidden flex-grow px-4 py-3 pb-0">
        {!receivedInitialState ? <span>Loading...</span> : !isAuthorized ? <LoginView /> : <TrackView />}
        <SettingsOverlay />
      </div>
      <ActionsSection />
      <ProfileSection />
    </div>
  )
}
