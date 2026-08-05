import Foundation

/// Merges several sources into a single "what am I listening to" answer.
///
/// A paused track is deliberately kept rather than cleared: pausing to go read the
/// lyrics is exactly the moment you reach for this app.
final class NowPlayingMonitor {
    private let sources: [NowPlayingSource]
    private var lastUpdate: [String: Date] = [:]

    private(set) var current: Track? {
        didSet {
            guard current != oldValue else { return }
            onChange?(current)
        }
    }

    var onChange: ((Track?) -> Void)?

    init(sources: [NowPlayingSource]) {
        self.sources = sources
    }

    func start() {
        for source in sources {
            source.onChange = { [weak self] _ in
                self?.recompute(changed: source.identifier)
            }
            source.start()
        }
        recompute(changed: nil)
    }

    func stop() {
        sources.forEach { $0.stop() }
    }

    private func recompute(changed: String?) {
        if let changed {
            lastUpdate[changed] = Date()
        }

        let candidates = sources.compactMap { source -> (id: String, track: Track)? in
            guard let track = source.current else { return nil }
            return (source.identifier, track)
        }

        // An actively playing source always wins. Otherwise fall back to whichever
        // source spoke most recently, so a paused track stays available.
        let playing = candidates.filter { $0.track.isPlaying }
        let pool = playing.isEmpty ? candidates : playing

        current = pool.max { lhs, rhs in
            (lastUpdate[lhs.id] ?? .distantPast) < (lastUpdate[rhs.id] ?? .distantPast)
        }?.track
    }
}
