import { ipcRenderer, contextBridge } from 'electron'
import { Action } from './actions'

declare global {
  interface Window {
    Main: typeof api
  }
}

export const api = {
  requestAction: (actionType: Action) => {
    ipcRenderer.send('requestAction', actionType)
  },

  on: (channel: string, callback: (_: unknown, data: unknown) => void) => {
    ipcRenderer.on(channel, callback)
  },

  off: (channel: string, callback: (_: unknown, data: unknown) => void) => {
    ipcRenderer.off(channel, callback)
  },
}
contextBridge.exposeInMainWorld('Main', api)
