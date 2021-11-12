import React from 'react'
import { useSharedState } from '../hooks/useSharedState'

export const MainView: React.FC = () => {
  const { currentTrack } = useSharedState()

  return (
    <div className="w-full h-full flex flex-col relative">
      <div
        className="absolute inset-0 flex items-center justify-center z-10 bg-blue-50 rounded opacity-0 hover:opacity-80 focus:opacity-80 transition-opacity cursor-pointer"
        role="button"
        tabIndex={0}
      >
        <span className="font-bold text-xl uppercase tracking-tight max-w-xs">Get Lyrics</span>
      </div>
      <h3 className="text-xs mb-1 uppercase font-semibold tracking-wide text-gray-700 select-none">Now playing:</h3>
      {currentTrack ? (
        <div className="flex flex-col">
          <span className="text-md leading-5 line-clamp-2">{currentTrack.title}</span>
          <span className="text-sm leading-4 line-clamp-2">{currentTrack.artists.join(', ')}</span>
        </div>
      ) : (
        <span className="text-sm">Nothing</span>
      )}
    </div>
  )
}
