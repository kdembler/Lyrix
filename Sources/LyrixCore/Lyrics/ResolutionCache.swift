import Foundation

struct Resolution: Codable, Equatable {
    let url: URL
    let matchedTitle: String
    let matchedArtist: String
    let confidence: Double
    /// True when this is a search page rather than a confident song match.
    let isFallback: Bool

    var matchedDisplay: String { "\(matchedArtist) — \(matchedTitle)" }
}

/// Persists confident resolutions so replaying a song costs zero API calls.
///
/// Fallbacks are intentionally *not* cached — they represent a failed lookup, and we
/// want the next play to retry rather than permanently remember the failure.
final class ResolutionCache {
    private var entries: [String: Resolution]
    private let capacity = 500
    private let fileURL: URL

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lyrix", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        self.fileURL = support.appendingPathComponent("resolutions.json")

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: Resolution].self, from: data) {
            self.entries = decoded
            Log.lyrics.info("loaded \(decoded.count) cached resolutions")
        } else {
            self.entries = [:]
        }
    }

    subscript(key: String) -> Resolution? {
        get { entries[key] }
        set {
            guard let newValue, !newValue.isFallback else { return }
            if entries.count >= capacity, entries[key] == nil {
                // Crude but adequate: drop an arbitrary quarter when full.
                for staleKey in entries.keys.prefix(capacity / 4) {
                    entries.removeValue(forKey: staleKey)
                }
            }
            entries[key] = newValue
            persist()
        }
    }

    func clear() {
        entries.removeAll()
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
