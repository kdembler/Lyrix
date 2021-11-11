import keytar from 'keytar'
import { Logger } from '../log'
import { sharedLyrixStore } from '../store'

const SERVICE_NAME = 'Lyrix_Keystore'

const keymap = {
  spotifyAccessToken: 'spotify_access_token',
  spotifyRefreshToken: 'spotify_refresh_token',
}

class _Keystore {
  get isAuthorized(): boolean {
    return sharedLyrixStore.getState().isAuthorized
  }

  private set isAuthorized(value: boolean) {
    Logger.info('Keystore', `isAuthorized changed to ${value.toString()}`)
    sharedLyrixStore.getState().setIsAuthorized(value)
  }

  initializedPromise: Promise<void>

  constructor() {
    this.initializedPromise = this.refreshStatus()
  }

  getAccessToken = () => keytar.getPassword(SERVICE_NAME, keymap.spotifyAccessToken)
  getRefreshToken = () => keytar.getPassword(SERVICE_NAME, keymap.spotifyRefreshToken)

  refreshStatus = async () => {
    Logger.debug('Keystore', 'reading auth status')
    const accessToken = await this.getAccessToken()
    this.isAuthorized = !!accessToken
  }

  setAccessToken = (token: string) => {
    Logger.debug('Keystore', 'Saving access token')
    return keytar.setPassword(SERVICE_NAME, keymap.spotifyAccessToken, token).then(() => {
      this.isAuthorized = true
    })
  }
  setRefreshToken = (token: string) => keytar.setPassword(SERVICE_NAME, keymap.spotifyRefreshToken, token)

  clear = async () => {
    await Promise.all([
      keytar.deletePassword(SERVICE_NAME, keymap.spotifyAccessToken),
      keytar.deletePassword(SERVICE_NAME, keymap.spotifyRefreshToken),
    ])
    this.isAuthorized = false
  }
}

export const Keystore = new _Keystore()
