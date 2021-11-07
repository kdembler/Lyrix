import React from 'react'
import { useSpotify } from '../hooks/useSpotify'

export const MainView: React.FC = () => {
  const { requestLogout } = useSpotify()

  return (
    <div className="w-full h-full grid grid-flow-row justify-center content-center">
      <h1 className="text-center text-xl">MainView</h1>
      <button
        onClick={requestLogout}
        className="bg-gray-300 hover:bg-gray-400 transition-colors rounded-2xl px-4 py-2 mt-5"
      >
        Logout
      </button>
    </div>
  )
}
