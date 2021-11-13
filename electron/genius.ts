import { createScopedLogger } from './log'
import { sharedLyrixStore } from './store'
import { GENIUS_CONFIG } from './constants'
import axios from 'axios'
import { shell } from 'electron'

type SearchResponse = {
  response: {
    hits: {
      type: string
      result: {
        url: string
      }
    }[]
  }
}

class _GeniusApi {
  private logger = createScopedLogger('Genius')

  async openLyricsURL() {
    const { currentTrack } = sharedLyrixStore.getState()

    if (!currentTrack) {
      this.logger.warn('Tried open lyrics without any track playing')
      return
    }

    try {
      const searchQuery = `${currentTrack.artists[0]} ${currentTrack.title}`
      const url = new URL('search', GENIUS_CONFIG.apiBaseUrl)
      url.searchParams.set('q', searchQuery)
      const response = await axios.get<SearchResponse>(url.toString(), {
        headers: {
          Authorization: `Bearer ${GENIUS_CONFIG.accessToken}`,
        },
      })

      const { hits } = response.data.response
      const filteredHits = hits && hits.filter((h) => h.type === 'song')
      if (!filteredHits || !filteredHits.length) {
        this.logger.warn('Found no results', { searchQuery })
        return
      }

      const firstHitUrl = filteredHits[0].result.url
      shell.openExternal(firstHitUrl)
    } catch (e) {
      this.logger.error('Failed to get search results', e)
    }
  }
}

export const GeniusApi = new _GeniusApi()
