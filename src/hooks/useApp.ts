import { useCallback } from 'react'

export const useApp = () => {
  const requestQuit = useCallback(() => {
    console.log('App:requestQuit()')
    window.Main.quit()
  }, [])

  return { requestQuit }
}
