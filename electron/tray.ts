import { app, Menu, MenuItemConstructorOptions, Tray } from 'electron'
import { join } from 'path'
import { LyrixWindow } from './window'

export class LyrixTray {
  tray: Tray
  lyrixWindow: LyrixWindow

  constructor(lyrixWindow: LyrixWindow) {
    this.lyrixWindow = lyrixWindow

    const assetsPath = app.isPackaged ? join(process.resourcesPath, 'assets') : join(__dirname, '../assets')
    this.tray = new Tray(join(assetsPath, 'IconTemplate.png'))
    this.tray.setIgnoreDoubleClickEvents(true)

    this.tray.on('click', () => this.toggleLyrixWindow())
    this.tray.on('right-click', () => this.openContextMenu())
  }

  private toggleLyrixWindow() {
    const windowBounds = this.lyrixWindow.getBounds()
    const trayBounds = this.tray.getBounds()
    const x = Math.round(trayBounds.x + trayBounds.width / 2 - windowBounds.width / 2)
    const y = Math.round(trayBounds.y + trayBounds.height)
    this.lyrixWindow.toggle(x, y)
  }

  private openContextMenu() {
    const menu: MenuItemConstructorOptions[] = [
      {
        label: 'Quit',
        role: 'quit',
        accelerator: 'Command+Q',
      },
    ]
    this.tray.popUpContextMenu(Menu.buildFromTemplate(menu))
  }
}
