import path from 'path'

import { app, ipcMain, IpcMainEvent } from 'electron'
import { LyrixTray } from './tray'
import { SpotifyApi } from './spotify'
import { LyrixWindow } from './window'
import { Keystore } from './keystore'

let lyrixTray: LyrixTray
let lyrixWindow: LyrixWindow

app.whenReady().then(() => {
  app.setActivationPolicy('accessory')

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  lyrixWindow = new LyrixWindow()
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  lyrixTray = new LyrixTray(lyrixWindow)

  Keystore.onAuthorizedChange = (value) => {
    lyrixWindow.sendMessageToApp('authorized_change', value)
  }
})

app.on('open-url', (event, url) => {
  event.preventDefault()
  SpotifyApi.handleAuthCallback(url)
})

ipcMain.on('authorize', (_: IpcMainEvent, __: any) => {
  SpotifyApi.openAuthorizeURL()
})

ipcMain.on('refresh', (_: IpcMainEvent, __: any) => {
  Keystore.refreshStatus()
})

ipcMain.on('logout', (_: IpcMainEvent, __: any) => {
  Keystore.clear()
})

ipcMain.on('quit', (_: IpcMainEvent, __: any) => {
  app.quit()
})

if (process.defaultApp) {
  if (process.argv.length >= 2) {
    app.setAsDefaultProtocolClient('lyrix', process.execPath, [path.resolve(process.argv[1])])
  }
} else {
  app.setAsDefaultProtocolClient('lyrix')
}
