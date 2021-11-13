import React from 'react'
import { useSharedState } from '../hooks/useSharedState'

export const TrackView: React.FC = () => {
  const { currentTrack } = useSharedState()

  return (
    <div className="w-full h-full flex flex-col relative text-whi">
      <h3 className="text-xs mb-1 uppercase font-semibold tracking-wide text-green-800 select-none">Now playing:</h3>
      {currentTrack ? (
        <div className="flex flex-col">
          <span className="text-xl font-bold leading-5 pb-1 line-clamp-2">{currentTrack.title}</span>
          <span className="text-xs line-clamp-1">{currentTrack.artists.join(', ')}</span>
        </div>
      ) : (
        <span className="text-sm">Nothing</span>
      )}
    </div>
  )
}
