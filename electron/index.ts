import path from 'path'

import { app, ipcMain, IpcMainEvent } from 'electron'
import { LyrixTray } from './tray'
import { SpotifyApi } from './spotify/api'
import { LyrixWindow } from './window'
import { Action, runAction } from './actions'
import { serializeState, sharedLyrixStore } from './store'
import { Logger } from './log'

let lyrixTray: LyrixTray
let lyrixWindow: LyrixWindow

app.whenReady().then(() => {
  app.setActivationPolicy('accessory')

  lyrixWindow = new LyrixWindow()
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  lyrixTray = new LyrixTray(lyrixWindow)

  sharedLyrixStore.subscribe((state) => {
    const serializedState = serializeState(state)
    Logger.debug('Index', 'sending state update', serializedState)
    lyrixWindow.sendMessageToApp('state_update', serializedState)
  })
})

app.on('open-url', (event, url) => {
  event.preventDefault()
  SpotifyApi.handleAuthCallback(url)
  lyrixWindow.prompt()
})

ipcMain.on('requestAction', (_: IpcMainEvent, actionType: Action) => {
  runAction(actionType)
})

if (process.defaultApp) {
  if (process.argv.length >= 2) {
    app.setAsDefaultProtocolClient('lyrix', process.execPath, [path.resolve(process.argv[1])])
  }
} else {
  app.setAsDefaultProtocolClient('lyrix')
}
