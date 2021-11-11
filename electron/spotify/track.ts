export type RawTrack = {
  item: {
    album: {
      name: string
    }
    artists: {
      name: string
    }[]
    name: string
  }
}

export const getParsedTrack = ({ item }: RawTrack) => {
  const { album, name } = item
  const artists = item.artists.map((a) => a.name)
  return {
    album: album.name,
    name,
    artists,

    formatted: `${artists.join(', ')} - ${name}`,
  }
}

export type Track = ReturnType<typeof getParsedTrack>
