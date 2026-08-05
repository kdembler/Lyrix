import Foundation

struct Track: Equatable {
    var title: String
    var artist: String
    var album: String?
    /// Stable identifier from the source app, e.g. "spotify:track:56sDw3DIGcUStBO5SguYPK".
    var sourceID: String?
    var isPlaying: Bool

    /// Key used for caching lyric resolutions. Prefers the source's stable ID, since
    /// it survives title punctuation differences and re-releases.
    var cacheKey: String {
        if let sourceID, !sourceID.isEmpty { return sourceID }
        return "\(TextNormalizer.comparable(artist))|\(TextNormalizer.comparable(title))"
    }

    /// What we send to Genius: the title stripped of remaster/feature/version noise.
    var searchQuery: String {
        "\(primaryArtist) \(TextNormalizer.searchableTitle(title))"
    }

    /// Spotify reports collaborations as "A, B" or "A & B" in one string; the first is
    /// the one Genius files the song under.
    var primaryArtist: String {
        let separators = [", ", " & ", " feat. ", " ft. ", " featuring ", " with "]
        var result = artist
        for separator in separators {
            if let range = result.range(of: separator, options: .caseInsensitive) {
                result = String(result[result.startIndex..<range.lowerBound])
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    var display: String { "\(artist) — \(title)" }

    /// Two tracks are "the same song" for resolution purposes even if playback state differs.
    func isSameSong(as other: Track?) -> Bool {
        guard let other else { return false }
        return cacheKey == other.cacheKey
    }
}
