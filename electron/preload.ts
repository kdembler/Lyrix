import { ipcRenderer, contextBridge } from 'electron'

declare global {
  interface Window {
    Main: typeof api
  }
}

export const api = {
  authorize: () => {
    ipcRenderer.send('authorize')
  },

  refresh: () => {
    ipcRenderer.send('refresh')
  },

  logout: () => {
    ipcRenderer.send('logout')
  },

  quit: () => {
    ipcRenderer.send('quit')
  },

  on: (channel: string, callback: (_: unknown, data: any) => void) => {
    ipcRenderer.on(channel, callback)
  },

  off: (channel: string, callback: (_: unknown, data: any) => void) => {
    ipcRenderer.off(channel, callback)
  },
}
contextBridge.exposeInMainWorld('Main', api)
