import { SpotifyApi } from './spotify/api'
import { Keystore } from './spotify/keystore'
import { app } from 'electron'
import { Logger } from './log'
import { sharedLyrixStore } from './store'

export const actions = {
  authorize: () => SpotifyApi.openAuthorizeURL(),
  logout: () => Keystore.clear(),
  quit: () => app.quit(),
  getTrack: () => SpotifyApi.getCurrentTrackInfo(),
  sendState: () => sharedLyrixStore.setState({}),
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
