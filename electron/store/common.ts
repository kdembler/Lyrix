import { Track } from '../spotify/track'
import { Profile } from '../spotify/profile'

export type SharedLyrixState = {
  isAuthorized: boolean
  currentTrack: Track | null
  userProfile: Profile | null
}

export const initialState: SharedLyrixState = {
  isAuthorized: false,
  currentTrack: null,
  userProfile: null,
}
