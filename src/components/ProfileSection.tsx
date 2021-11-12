import React from 'react'
import { useApp } from '../hooks/useApp'
import { useSharedState } from '../hooks/useSharedState'

export const ProfileSection: React.FC = () => {
  const { requestAction } = useApp()
  const { userProfile } = useSharedState()

  if (!userProfile) {
    return null
  }

  return (
    <div className="p-2 bg-gray-200 flex justify-between items-center select-none">
      <div className="inline-grid grid-flow-col items-center gap-2">
        {userProfile.imageUrl && (
          <img className="rounded-full w-6 h-6 border-2 border-gray-300" src={userProfile.imageUrl} alt="User icon" />
        )}
        <span className="text-xs">{userProfile.name}</span>
      </div>
      <button
        className="text-xs uppercase bg-gray-300 hover:bg-gray-400 transition-colors font-semibold px-2 py-1 rounded"
        onClick={() => requestAction('logout')}
      >
        Log out
      </button>
    </div>
  )
}
