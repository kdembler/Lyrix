import Foundation

/// Successor to v2's `purifyTitle`. Two distinct jobs, deliberately separated:
///
/// - `searchableTitle` strips release noise before we ask Genius ("Song - Remastered 2011" → "Song")
/// - `comparable` flattens a string for *comparison* (case, diacritics, punctuation)
enum TextNormalizer {
    /// Patterns describing decorations Genius does not use in its song titles.
    private static let noisePatterns: [String] = [
        #"\s*[\(\[]\s*feat\.?\s[^)\]]*[\)\]]"#,
        #"\s*[\(\[]\s*ft\.?\s[^)\]]*[\)\]]"#,
        #"\s*[\(\[]\s*featuring\s[^)\]]*[\)\]]"#,
        #"\s*[\(\[]\s*with\s[^)\]]*[\)\]]"#,
        #"\s*[\(\[][^)\]]*\bremaster(ed)?\b[^)\]]*[\)\]]"#,
        #"\s*[\(\[][^)\]]*\bdeluxe\b[^)\]]*[\)\]]"#,
        #"\s*[\(\[][^)\]]*\bbonus track\b[^)\]]*[\)\]]"#,
        #"\s*[\(\[][^)\]]*\bexpanded\b[^)\]]*[\)\]]"#,
        // Trailing " - <something> Mix/Version/Edit/Remaster/Live"
        #"\s+[-–—]\s+[^-–—]*\bremaster(ed)?\b.*$"#,
        #"\s+[-–—]\s+[^-–—]*\bversion\b.*$"#,
        #"\s+[-–—]\s+[^-–—]*\bremix\b.*$"#,
        #"\s+[-–—]\s+[^-–—]*\bedit\b.*$"#,
        #"\s+[-–—]\s+[^-–—]*\bmix\b.*$"#,
        #"\s+[-–—]\s+live\b.*$"#,
        #"\s+[-–—]\s+\d{4}\s+remaster.*$"#,
    ]

    private static let noiseRegexes: [NSRegularExpression] = noisePatterns.compactMap {
        try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
    }

    /// Strips release decorations so the query matches how Genius files songs.
    static func searchableTitle(_ raw: String) -> String {
        var result = raw
        for regex in noiseRegexes {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        // Never strip a title down to nothing — fall back to the original.
        return cleaned.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }

    /// Flattens for comparison: lowercase, diacritic-free, punctuation-free, single-spaced.
    static func comparable(_ raw: String) -> String {
        let folded = raw.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let expanded = folded.replacingOccurrences(of: "&", with: " and ")
        let stripped = expanded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return String(stripped)
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    static func tokens(_ raw: String) -> Set<String> {
        Set(comparable(raw).split(separator: " ").map(String.init))
    }
}
