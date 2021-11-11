import React from 'react'
import { useSharedState } from '../hooks/useSharedState'

export const MainView: React.FC = () => {
  const { currentTrack } = useSharedState()

  return (
    <div className="flex flex-col p-5">
      <h3 className="text-sm font-semibold">Currently playing:</h3>
      <span className="text-sm text-gray-800">{currentTrack ? currentTrack.formatted : 'Nothing'}</span>
      {/*<Button onClick={() => requestAction('logout')} className="mt-5">*/}
      {/*  Logout*/}
      {/*</Button>*/}
      {/*<Button onClick={() => requestAction('getTrack')} className="mt-5">*/}
      {/*  Request track*/}
      {/*</Button>*/}
    </div>
  )
}
