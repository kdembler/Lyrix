import { URL } from 'url'
import { dialog, shell } from 'electron'
import { createHash, randomBytes } from 'crypto'
import axios from 'axios'
import qs from 'qs'
import { Keystore } from './keystore'
import { Logger } from './log'

export const SPOTIFY_CONFIG = {
  authorizeUrl: 'https://accounts.spotify.com/authorize',
  accessTokenUrl: 'https://accounts.spotify.com/api/token',
  clientId: '0238be12311d40b1a96aea3af50a1d0c',
  scope: 'user-read-currently-playing user-read-playback-state',
  redirectUri: 'lyrix://oauth-callback/spotify',
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

  constructor() {
    this.pkceVerifier = generatePkceVerifier()
    this.pkceChallenge = generatePkceChallenge(this.pkceVerifier)
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

  private async requestTokenRefresh() {
    const refreshToken = await Keystore.getRefreshToken()
    if (!refreshToken) return

    const body = {
      client_id: SPOTIFY_CONFIG.clientId,
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }
    await this.makeTokenRequest(body)
  }

  private async makeTokenRequest(body: Record<string, string>) {
    try {
      const response = await axios.post<TokenResponse>(SPOTIFY_CONFIG.accessTokenUrl, qs.stringify(body))
      const { access_token: accessToken, refresh_token: refreshToken } = response.data
      Logger.info('Spotify', 'authorized')
      await Promise.all([Keystore.setAccessToken(accessToken), Keystore.setRefreshToken(refreshToken)])
    } catch (err) {
      console.error('Failed to obtain access token')
      dialog.showErrorBox('error', JSON.stringify({ error: err }))
    }
  }

  // public async getCurrentTrackInfo() {
  //   try {
  //     await axios.get('https://api.spotify.com/v1/me/player')
  //   }
  // }
}

export const SpotifyApi = new _SpotifyApi()
