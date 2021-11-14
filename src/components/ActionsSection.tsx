import React from 'react'
import { IconButton } from './IconButton'
import { ReactComponent as CogIcon } from '../icons/cog.svg'
import { ReactComponent as ExitIcon } from '../icons/exit.svg'
import { Button } from './Button'
import { useSharedState } from '../hooks/useSharedState'
import { useApp } from '../hooks/useApp'

export const ActionsSection: React.FC = () => {
  const { currentTrack, setSettingsOpen } = useSharedState()
  const { requestAction } = useApp()

  return (
    <div className="w-full flex flex-row-reverse justify-between items-center pl-4 pr-2 py-1">
      <div>
        <IconButton onClick={() => setSettingsOpen(true)}>
          <CogIcon className="w-5 h-5" />
        </IconButton>
        <IconButton onClick={() => requestAction('quit')}>
          <ExitIcon className="w-5 h-5" />
        </IconButton>
      </div>
      {currentTrack && (
        <Button variant="primary" tabIndex={1} onClick={() => requestAction('openLyrics')}>
          Open lyrics
        </Button>
      )}
    </div>
  )
}
