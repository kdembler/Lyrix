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

const purifyTitle = (rawTitle: string) => {
  const filters = [/ \(feat\. .*\)/i, / \(with .*\)/i, / - .* (re)?mix$/i, / - .* version$/i, / - remastered \d*$/i]

  const filteredTitle = filters.reduce((acc, filter) => {
    return acc.replace(filter, '')
  }, rawTitle)

  return filteredTitle.trim()
}

export const getParsedTrack = ({ item }: RawTrack) => {
  const { album, name } = item
  const artists = item.artists.map((a) => a.name)
  const title = purifyTitle(name)
  return {
    album: album.name,
    rawTitle: name,
    title,
    artists,

    formatted: `${artists.join(', ')} - ${title}`,
  }
}

export type Track = ReturnType<typeof getParsedTrack>
