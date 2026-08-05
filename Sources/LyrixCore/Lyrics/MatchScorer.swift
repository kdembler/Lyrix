import Foundation

enum MatchScorer {
    /// Below this we refuse to claim a match and send the user to a search page instead.
    /// v2's bug was having no threshold at all — it opened `hits[0]` unconditionally.
    static let acceptanceThreshold = 0.60

    /// Floor on the artist factor. A title-only match still scores enough to be *ranked*
    /// against its peers, but cannot reach `acceptanceThreshold` on its own.
    private static let artistFloor = 0.35

    static func score(track: Track, hit: GeniusHit) -> Double {
        let artistScore = similarity(track.primaryArtist, hit.artist)
        let titleScore = similarity(TextNormalizer.searchableTitle(track.title), hit.title)

        // Multiplicative, not additive. "The same song" means the artist *and* the title
        // match — a conjunction. A weighted sum let a perfect title compensate for an
        // entirely wrong artist, scoring covers ("Yesterday" by Toni Braxton) as though
        // they were the track you are listening to.
        var total = titleScore * (artistFloor + (1 - artistFloor) * artistScore)

        // Genius hosts translation pages ("Genius Traduzioni Italiane") that often rank
        // just under the real song and would otherwise score on title alone.
        if isTranslationPage(hit) && !TextNormalizer.comparable(track.primaryArtist).contains("genius") {
            total *= 0.25
        }

        // An instrumental page has nothing to read.
        if hit.isInstrumental {
            total *= 0.5
        }

        return total
    }

    private static func isTranslationPage(_ hit: GeniusHit) -> Bool {
        let artist = TextNormalizer.comparable(hit.artist)
        guard artist.contains("genius") else { return false }
        let markers = ["translation", "traduzioni", "traduccion", "traductions", "ubersetzungen", "romanization"]
        return markers.contains { artist.contains($0) }
    }

    /// Blend of token-set overlap (robust to word order and extra words) and edit
    /// distance (robust to typos and punctuation).
    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let left = TextNormalizer.comparable(lhs)
        let right = TextNormalizer.comparable(rhs)

        guard !left.isEmpty, !right.isEmpty else { return 0 }
        if left == right { return 1.0 }

        let leftTokens = TextNormalizer.tokens(lhs)
        let rightTokens = TextNormalizer.tokens(rhs)

        // One side being a whole-word subset of the other is a strong signal
        // ("Post Malone" vs "Post Malone & Swae Lee"). Deliberately token-wise rather
        // than substring: raw `contains` would treat "Fool" as matching
        // "Why Do Fools Fall in Love", which is how you end up on the wrong page.
        if leftTokens.isSubset(of: rightTokens) || rightTokens.isSubset(of: leftTokens) {
            return 0.88
        }

        let intersection = Double(leftTokens.intersection(rightTokens).count)
        let union = Double(leftTokens.union(rightTokens).count)
        let tokenScore = union > 0 ? intersection / union : 0

        let editScore = editRatio(left, right)

        return max(tokenScore, editScore * 0.9)
    }

    /// 1.0 for identical, approaching 0 as strings diverge.
    static func editRatio(_ lhs: String, _ rhs: String) -> Double {
        let a = Array(lhs), b = Array(rhs)
        guard !a.isEmpty, !b.isEmpty else { return 0 }

        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }

        let distance = Double(previous[b.count])
        let longest = Double(max(a.count, b.count))
        return max(0, 1.0 - distance / longest)
    }
}
