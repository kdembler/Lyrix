import { SpotifyApi } from './spotify/api'
import { Keystore } from './spotify/keystore'
import { app } from 'electron'
import { Logger } from './log'
import { sharedLyrixStore } from './store'
import { GeniusApi } from './genius'

export const actions = {
  startAuthorize: () => SpotifyApi.openAuthorizeURL(),
  openLyrics: () => GeniusApi.openLyricsURL(),
  sendState: () => sharedLyrixStore.setState({}),
  logout: () => {
    Keystore.clear()
    sharedLyrixStore.setState({
      currentTrack: null,
      userProfile: null,
    })
  },
  enableAutolaunch: () => {
    Logger.info('Actions', 'enabling app login item')
    app.setLoginItemSettings({
      openAtLogin: true,
      openAsHidden: true,
    })
    sharedLyrixStore.getState().setAutolaunchEnabled(true)
  },
  disableAutolaunch: () => {
    Logger.info('Actions', 'disabling app login item')
    app.setLoginItemSettings({
      openAtLogin: false,
      openAsHidden: true,
    })
    sharedLyrixStore.getState().setAutolaunchEnabled(false)
  },
  quit: () => app.quit(),
} as const

export type Action = keyof typeof actions

export const runAction = (actionType: Action) => {
  if (!Object.keys(actions).includes(actionType)) {
    Logger.error('Actions', `trying to run unknown action '${actionType}'`)
    return
  }
  Logger.debug('Actions', `running action '${actionType}'`)

  try {
    const actionHandler = actions[actionType]
    actionHandler()
  } catch (e) {
    Logger.error('Actions', `failed to run action '${actionType}'`, e)
  }
}
