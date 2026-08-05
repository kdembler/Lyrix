import XCTest
@testable import LyrixCore

/// Hits the real Genius API. Skipped unless `LYRIX_INTEGRATION=1`, so `swift test`
/// stays hermetic and offline-safe by default.
///
///     LYRIX_INTEGRATION=1 swift test --filter GeniusIntegrationTests
final class GeniusIntegrationTests: XCTestCase {
    private var isEnabled: Bool {
        ProcessInfo.processInfo.environment["LYRIX_INTEGRATION"] == "1"
    }

    private struct Case {
        let title: String
        let artist: String
        /// Fragment expected in the resolved genius.com path.
        let expectedSlug: String
    }

    private let cases: [Case] = [
        .init(title: "Karma Police", artist: "Radiohead", expectedSlug: "radiohead-karma-police"),
        .init(title: "Fool", artist: "Djo", expectedSlug: "djo-fool"),
        .init(title: "Mortal Projections", artist: "Djo", expectedSlug: "djo-mortal-projections"),
        // Release-noise suffixes must not derail the query.
        .init(title: "Bohemian Rhapsody - Remastered 2011", artist: "Queen", expectedSlug: "queen-bohemian-rhapsody"),
        .init(title: "Karma Police - Remastered 2016", artist: "Radiohead", expectedSlug: "radiohead-karma-police"),
        // Featured-artist suffix on our side, combined artist on Genius's side.
        .init(title: "Sunflower (feat. Swae Lee)", artist: "Post Malone", expectedSlug: "sunflower"),
        .init(title: "Blinding Lights", artist: "The Weeknd", expectedSlug: "the-weeknd-blinding-lights"),
    ]

    func testResolvesKnownTracksToCorrectPages() async throws {
        try XCTSkipUnless(isEnabled, "set LYRIX_INTEGRATION=1 to run")

        let client = GeniusClient()
        var failures: [String] = []

        for testCase in cases {
            let track = Track(
                title: testCase.title,
                artist: testCase.artist,
                album: nil,
                sourceID: nil,
                isPlaying: true
            )

            let hits = try await client.search(query: track.searchQuery)
            let scored = hits
                .map { (hit: $0, score: MatchScorer.score(track: track, hit: $0)) }
                .sorted { $0.score > $1.score }

            guard let best = scored.first, best.score >= MatchScorer.acceptanceThreshold else {
                failures.append("\(track.display): no confident match (best \(scored.first?.score ?? 0))")
                continue
            }

            let path = best.hit.url.path.lowercased()
            if !path.contains(testCase.expectedSlug) {
                failures.append("\(track.display): expected slug '\(testCase.expectedSlug)', got \(best.hit.url.path)")
            }
            print(String(format: "  %.2f  %@ → %@", best.score, track.display, best.hit.url.absoluteString))
        }

        XCTAssertTrue(failures.isEmpty, "mismatches:\n" + failures.joined(separator: "\n"))
    }

    /// A song that does not exist must fall back rather than confidently open something wrong.
    func testNonexistentSongFallsBack() async throws {
        try XCTSkipUnless(isEnabled, "set LYRIX_INTEGRATION=1 to run")

        let track = Track(
            title: "Zzzqqx Nonexistent Song Title",
            artist: "Nonexistent Artist Qqzz",
            album: nil,
            sourceID: nil,
            isPlaying: true
        )

        let hits = try await GeniusClient().search(query: track.searchQuery)
        let best = hits
            .map { MatchScorer.score(track: track, hit: $0) }
            .max() ?? 0

        XCTAssertLessThan(best, MatchScorer.acceptanceThreshold,
                          "must not claim a confident match for a song that does not exist")
    }
}
