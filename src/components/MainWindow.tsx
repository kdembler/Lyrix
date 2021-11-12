import React from 'react'
import { MainView } from './MainView'
import { LoginView } from './LoginView'
import { useApp } from '../hooks/useApp'
import { useSharedState } from '../hooks/useSharedState'
import { IconButton } from './IconButton'
import { ReactComponent as ExitIcon } from '../icons/exit.svg'
import { ReactComponent as CogIcon } from '../icons/cog.svg'
import { ProfileSection } from './ProfileSection'

export const MainWindow: React.FC = () => {
  const { isAuthorized, receivedInitialState, setSettingsOpen } = useSharedState()
  const { requestAction } = useApp()

  const isLoading = !receivedInitialState

  return (
    <div className="w-screen h-screen flex flex-col bg-blue-50 overflow-hidden">
      <div className="overflow-hidden flex-grow px-4 py-3 pb-0">
        {isLoading ? <span>Loading...</span> : !isAuthorized ? <LoginView /> : <MainView />}
      </div>
      <div className="w-full flex flex-row justify-end px-2 z-10">
        <IconButton onClick={() => setSettingsOpen(true)}>
          <CogIcon className="w-5 h-5" />
        </IconButton>
        <IconButton onClick={() => requestAction('quit')}>
          <ExitIcon className="w-5 h-5" />
        </IconButton>
      </div>
      <ProfileSection />
    </div>
  )
}
