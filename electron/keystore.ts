import keytar from 'keytar'
import { Logger } from './log'

const SERVICE_NAME = 'Lyrix_Keystore'

const keymap = {
  spotifyAccessToken: 'spotify_access_token',
  spotifyRefreshToken: 'spotify_refresh_token',
}

class _Keystore {
  private _isAuthorized = false
  private _onAuthorizedChange: ((authorized: boolean) => void) | null = null

  set onAuthorizedChange(value: (authorized: boolean) => void) {
    this._onAuthorizedChange = value
  }

  get isAuthorized(): boolean {
    return this._isAuthorized
  }

  private set isAuthorized(value: boolean) {
    Logger.info('Keystore', `isAuthorized changed to ${value.toString()}`)
    this._isAuthorized = value
    this._onAuthorizedChange?.(value)
  }

  constructor() {
    this.refreshStatus()
  }

  getAccessToken = () => keytar.getPassword(SERVICE_NAME, keymap.spotifyAccessToken)
  getRefreshToken = () => keytar.getPassword(SERVICE_NAME, keymap.spotifyRefreshToken)

  refreshStatus = async () => {
    Logger.debug('Keystore', 'reading auth status')
    const [accessToken, refreshToken] = await Promise.all([this.getAccessToken(), this.getRefreshToken()])
    this.isAuthorized = !!accessToken && !!refreshToken
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
