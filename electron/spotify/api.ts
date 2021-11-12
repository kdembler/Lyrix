import { URL } from 'url'
import { dialog, shell } from 'electron'
import { createHash, randomBytes } from 'crypto'
import axios, { AxiosError, AxiosResponse } from 'axios'
import qs from 'qs'
import { Keystore } from './keystore'
import { createScopedLogger } from '../log'
import { getParsedTrack, RawTrack } from './track'
import { sharedLyrixStore } from '../store'
import { getParsedProfile, RawProfile } from './profile'

export const SPOTIFY_CONFIG = {
  authorizeUrl: 'https://accounts.spotify.com/authorize',
  accessTokenUrl: 'https://accounts.spotify.com/api/token',
  apiBaseUrl: 'https://api.spotify.com/v1',
  clientId: '0238be12311d40b1a96aea3af50a1d0c',
  scope: 'user-read-currently-playing user-read-playback-state',
  redirectUri: 'lyrix://oauth-callback/spotify',
  pollPeriodSec: 10,
}

class SpotifyUnauthorizedRequest extends Error {
  message = 'Failed to make Spotify request - unauthorized'
}

const getRandomString = (length: number) => {
  const fullString = randomBytes(Math.ceil(length / 2)).toString('hex')
  return fullString.slice(0, length)
}

const generatePkceVerifier = () => {
  const minLength = 43
  const maxLength = 128
  const length = Math.floor(Math.random() * (maxLength - minLength + 1)) + minLength
  return getRandomString(length)
}

const generatePkceChallenge = (verifier: string) => {
  return createHash('sha256').update(verifier).digest('base64url')
}

type TokenResponse = {
  access_token: string
  refresh_token: string
}

class _SpotifyApi {
  readonly pkceVerifier: string
  readonly pkceChallenge: string
  private state = ''
  private logger = createScopedLogger('Spotify')

  constructor() {
    this.pkceVerifier = generatePkceVerifier()
    this.pkceChallenge = generatePkceChallenge(this.pkceVerifier)

    setInterval(() => {
      if (!Keystore.isAuthorized) return
      this.getCurrentTrackInfo()
    }, SPOTIFY_CONFIG.pollPeriodSec * 1000)

    Keystore.initializedPromise.then(() => {
      if (Keystore.isAuthorized) {
        this.getCurrentTrackInfo()
        this.getUserProfile()
      }
    })
  }

  openAuthorizeURL() {
    this.state = getRandomString(32)

    const authURL = new URL(SPOTIFY_CONFIG.authorizeUrl)
    authURL.searchParams.set('client_id', SPOTIFY_CONFIG.clientId)
    authURL.searchParams.set('scope', SPOTIFY_CONFIG.scope)
    authURL.searchParams.set('response_type', 'code')
    authURL.searchParams.set('redirect_uri', SPOTIFY_CONFIG.redirectUri)
    authURL.searchParams.set('code_challenge_method', 'S256')
    authURL.searchParams.set('code_challenge', this.pkceChallenge)
    authURL.searchParams.set('state', this.state)

    shell.openExternal(authURL.toString())
  }

  handleAuthCallback(callbackUrl: string) {
    const parsedUrl = new URL(callbackUrl)
    const error = parsedUrl.searchParams.get('error')
    const code = parsedUrl.searchParams.get('code')
    const state = parsedUrl.searchParams.get('state')

    if (error || !code || !state) {
      // TODO: handle error
      console.error('auth error')
      return
    }

    if (state !== this.state) {
      // TODO: handle state mismatch
      console.error('state mismatch')
      return
    }

    return this.exchangeCodeForToken(code)
  }

  private async exchangeCodeForToken(code: string) {
    const body = {
      client_id: SPOTIFY_CONFIG.clientId,
      grant_type: 'authorization_code',
      code,
      redirect_uri: SPOTIFY_CONFIG.redirectUri,
      code_verifier: this.pkceVerifier,
    }
    await this.makeTokenRequest(body)
  }

  private async tryTokenRefresh(): Promise<boolean> {
    const refreshToken = await Keystore.getRefreshToken()
    if (!refreshToken) return false

    const body = {
      client_id: SPOTIFY_CONFIG.clientId,
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }

    try {
      await this.makeTokenRequest(body)
      return Keystore.isAuthorized
    } catch (e) {
      this.logger.error('Failed to refresh token', e)
      return false
    }
  }

  private async makeTokenRequest(body: Record<string, string>) {
    try {
      const response = await axios.post<TokenResponse>(SPOTIFY_CONFIG.accessTokenUrl, qs.stringify(body))
      const { access_token: accessToken, refresh_token: refreshToken } = response.data
      this.logger.info('authorized')
      await Promise.all([Keystore.setAccessToken(accessToken), Keystore.setRefreshToken(refreshToken)])
      this.getUserProfile()
    } catch (err) {
      console.error('Failed to obtain access token')
      dialog.showErrorBox('error', JSON.stringify({ error: err }))
    }
  }

  public async getCurrentTrackInfo() {
    this.logger.debug('getting current track')
    try {
      const response = await this.makeApiRequest<RawTrack>('me/player/currently-playing')
      if (response.status === 204) {
        this.logger.info('empty track response')
        sharedLyrixStore.getState().setCurrentTrack(null)
      } else if (response.status === 200) {
        const track = getParsedTrack(response.data)
        this.logger.info(`currently playing: ${track.formatted}`)
        sharedLyrixStore.getState().setCurrentTrack(track)
      } else {
        this.logger.error('unknown track response', { status: response.status, data: response.data })
      }
    } catch (e) {
      this.logger.error('failed to get current track info', e)
    }
  }

  public async getUserProfile() {
    this.logger.debug('getting user profile')
    try {
      const response = await this.makeApiRequest<RawProfile>('me')
      const profile = getParsedProfile(response.data)
      this.logger.info(`got user profile: ${profile.name}`)
      const state = sharedLyrixStore.getState()
      this.logger.debug('got store', state)
      state.setUserProfile(profile)
    } catch (e) {
      this.logger.error('failed to get current user info', e)
    }
  }

  private async makeApiRequest<TData>(endpoint: string): Promise<AxiosResponse<TData>> {
    if (!Keystore.isAuthorized) {
      throw SpotifyUnauthorizedRequest
    }

    try {
      const accessToken = await Keystore.getAccessToken()
      return await axios.get<TData>(`${SPOTIFY_CONFIG.apiBaseUrl}/${endpoint}`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      })
    } catch (e) {
      const axiosError = e as AxiosError
      if (axiosError.isAxiosError) {
        if (axiosError.response?.status === 401) {
          this.logger.info('received 401, refreshing token')
          // refresh token and retry
          const refreshed = await this.tryTokenRefresh()
          if (refreshed) {
            return this.makeApiRequest<TData>(endpoint)
          } else {
            throw SpotifyUnauthorizedRequest
          }
        }
      }

      throw e
    }
  }
}

export const SpotifyApi = new _SpotifyApi()
