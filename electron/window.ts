import { BrowserWindow } from 'electron'
import isDev from 'electron-is-dev'
import path from 'path'
import { Logger } from './log'

export class LyrixWindow {
  window: BrowserWindow

  constructor() {
    this.window = new BrowserWindow({
      width: 250,
      height: 150,
      show: false,
      frame: false,
      fullscreenable: false,
      resizable: false,
      webPreferences: {
        // devTools: isDev,
        devTools: true,
        preload: path.join(__dirname, 'preload.js'),
      },
    })

    const port = process.env.PORT || 3000
    const url = isDev ? `http://localhost:${port}` : path.join(__dirname, '../src/out/index.html')

    if (isDev) {
      this.window.loadURL(url)
      this.window.webContents.openDevTools({ mode: 'detach' })
    } else {
      this.window.on('blur', () => this.hide())
      this.window.loadFile(url)
      this.window.webContents.openDevTools({ mode: 'detach' })
    }

    Logger.debug('window', 'created window')
  }

  sendMessageToApp(channel: string, value: any) {
    Logger.info('window', `sending message on '${channel}'`)
    Logger.debug('window', `message: ${value}`)
    this.window.webContents.send(channel, value)
  }

  private showAt(x: number, y: number) {
    Logger.debug('window', 'showing window')
    this.window.setPosition(x, y, false)
    this.prompt()
  }

  private hide() {
    Logger.debug('window', 'hiding window')
    this.window.hide()
  }

  toggle(x: number, y: number) {
    this.window.isVisible() ? this.hide() : this.showAt(x, y)
  }

  prompt() {
    this.window.show()
    this.window.focus()
  }

  getBounds = () => this.window.getBounds()
}
