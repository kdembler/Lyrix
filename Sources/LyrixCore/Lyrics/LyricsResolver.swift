import Foundation

/// Resolves a track to a Genius URL *eagerly*, the moment the track changes, so that
/// clicking the menu bar icon is an instant local lookup rather than a network round-trip.
/// This inversion is the whole point of v3.
@MainActor
final class LyricsResolver {
    private let client: GeniusClient
    private let cache: ResolutionCache
    private var inFlight: Task<Void, Never>?

    private(set) var track: Track?
    private(set) var resolution: Resolution?

    /// How long a click will wait for an in-flight resolution before falling back.
    private let clickGracePeriod: TimeInterval = 0.8

    var onChange: ((Resolution?) -> Void)?

    init(client: GeniusClient, cache: ResolutionCache) {
        self.client = client
        self.cache = cache
    }

    func update(track newTrack: Track?) {
        // Play/pause flips arrive as changes but are the same song — don't re-resolve.
        if let newTrack, newTrack.isSameSong(as: track) {
            track = newTrack
            return
        }

        inFlight?.cancel()
        inFlight = nil
        track = newTrack
        setResolution(nil)

        guard let newTrack else { return }

        if let cached = cache[newTrack.cacheKey] {
            Log.lyrics.info("cache hit for \(newTrack.display, privacy: .public)")
            setResolution(cached)
            return
        }

        inFlight = Task { [weak self] in
            await self?.performResolution(for: newTrack)
        }
    }

    /// The URL to open right now. Never fails — worst case it is a Genius search page.
    func urlToOpen() async -> URL? {
        guard let track else { return nil }

        if let resolution { return resolution.url }

        // Clicked before resolution finished: give it a brief chance rather than
        // immediately degrading to a search page.
        if inFlight != nil {
            let deadline = Date().addingTimeInterval(clickGracePeriod)
            while resolution == nil, inFlight != nil, Date() < deadline {
                try? await Task.sleep(nanoseconds: 40_000_000)
            }
            if let resolution { return resolution.url }
        }

        Log.lyrics.info("falling back to search page for \(track.display, privacy: .public)")
        return GeniusClient.searchPageURL(for: track)
    }

    private func performResolution(for track: Track) async {
        defer { if !Task.isCancelled { inFlight = nil } }

        do {
            let hits = try await client.search(query: track.searchQuery)
            guard !Task.isCancelled else { return }

            let scored = hits
                .map { (hit: $0, score: MatchScorer.score(track: track, hit: $0)) }
                .sorted { $0.score > $1.score }

            guard let best = scored.first, best.score >= MatchScorer.acceptanceThreshold else {
                let topScore = scored.first.map { String(format: "%.2f", $0.score) } ?? "none"
                Log.lyrics.info(
                    "no confident match for \(track.display, privacy: .public) (best \(topScore, privacy: .public)), using search page"
                )
                setResolution(Resolution(
                    url: GeniusClient.searchPageURL(for: track),
                    matchedTitle: track.title,
                    matchedArtist: track.artist,
                    confidence: scored.first?.score ?? 0,
                    isFallback: true
                ))
                return
            }

            let resolved = Resolution(
                url: best.hit.url,
                matchedTitle: best.hit.title,
                matchedArtist: best.hit.artist,
                confidence: best.score,
                isFallback: false
            )
            Log.lyrics.info(
                "matched \(track.display, privacy: .public) → \(resolved.matchedDisplay, privacy: .public) (\(String(format: "%.2f", best.score), privacy: .public))"
            )
            cache[track.cacheKey] = resolved
            setResolution(resolved)
        } catch {
            guard !Task.isCancelled else { return }
            Log.lyrics.error("search failed for \(track.display, privacy: .public): \(String(describing: error), privacy: .public)")
            setResolution(Resolution(
                url: GeniusClient.searchPageURL(for: track),
                matchedTitle: track.title,
                matchedArtist: track.artist,
                confidence: 0,
                isFallback: true
            ))
        }
    }

    private func setResolution(_ new: Resolution?) {
        resolution = new
        onChange?(new)
    }
}
