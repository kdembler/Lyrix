import React from 'react'
import { useSharedState } from '../hooks/useSharedState'
import { useApp } from '../hooks/useApp'
import { IconButton } from './IconButton'
import { ReactComponent as CloseIcon } from '../icons/close.svg'

export const SettingsOverlay: React.FC = () => {
  const { settingsOpen, autolaunchEnabled, setSettingsOpen } = useSharedState()
  const { requestAction } = useApp()

  const handleAutolaunchChange = () => {
    if (autolaunchEnabled) {
      requestAction('disableAutolaunch')
    } else {
      requestAction('enableAutolaunch')
    }
  }

  return settingsOpen ? (
    <div className="absolute inset-0" aria-modal="true">
      <div className="absolute inset-0 bg-green-700 opacity-95" />
      <div className="absolute inset-0 px-4 py-3">
        <h1 className="text-2xl font-bold text-white">Settings</h1>
        <IconButton className="absolute top-4 right-3" onClick={() => setSettingsOpen(false)}>
          <CloseIcon className="text-white fill-current" />
        </IconButton>
        <div className="relative flex items-start mt-3">
          <div className="flex items-center h-5">
            <input
              id="autolaunch"
              aria-describedby="autolaunch-description"
              name="autolaunch"
              type="checkbox"
              className="h-4 w-4 text-green-400 border-gray-300 rounded"
              checked={autolaunchEnabled}
              onChange={handleAutolaunchChange}
            />
          </div>
          <div className="ml-3 text-sm">
            <label htmlFor="autolaunch" className="font-medium text-gray-200">
              Launch at startup
            </label>
            <p id="autolaunch-description" className="text-gray-300">
              Start Lyrix when your system boots up
            </p>
          </div>
        </div>
      </div>
    </div>
  ) : null
}
