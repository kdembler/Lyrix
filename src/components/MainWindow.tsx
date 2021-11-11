import React from 'react'
import { MainView } from './MainView'
import { LoginView } from './LoginView'
import { useApp } from '../hooks/useApp'
import { useSharedState } from '../hooks/useSharedState'
import { IconButton } from './IconButton'
import { ReactComponent as CloseIcon } from '../icons/close.svg'

export const MainWindow: React.FC = () => {
  const { isAuthorized, receivedInitialState, userProfile } = useSharedState()
  const { requestAction } = useApp()

  const isLoading = !receivedInitialState

  return (
    <div className="w-screen h-screen flex flex-col bg-blue-50">
      <div className="flex-grow">
        {isLoading ? <span>Loading...</span> : !isAuthorized ? <LoginView /> : <MainView />}
      </div>
      {!isLoading && (
        <div className="p-2 bg-gray-200 flex flex-row-reverse justify-between">
          <IconButton onClick={() => requestAction('quit')}>
            <CloseIcon />
          </IconButton>
          {userProfile && (
            <div className="inline-grid grid-flow-col items-center gap-2">
              {userProfile.imageUrl && (
                <img
                  className="rounded-full w-6 h-6 border-2 border-gray-300"
                  src={userProfile.imageUrl}
                  alt="User icon"
                />
              )}
              <span className="text-xs">{userProfile.name}</span>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
