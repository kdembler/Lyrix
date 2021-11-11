export type RawProfile = {
  display_name: string
  images: {
    url: string
  }[]
  id: string
  href: string
}

export const getParsedProfile = ({ display_name, images, id, href }: RawProfile) => {
  const imageUrl = images.length > 0 ? images[0].url || null : null
  return {
    id,
    href,
    name: display_name,
    imageUrl,
  }
}

export type Profile = ReturnType<typeof getParsedProfile>
