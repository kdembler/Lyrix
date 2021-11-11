import { useCallback } from 'react'
import { Action } from '../../electron/actions'

export const useApp = () => {
  const requestAction = useCallback((actionType: Action) => {
    console.log(`App:requestAction('${actionType}')`)
    window.Main.requestAction(actionType)
  }, [])

  return { requestAction }
}
