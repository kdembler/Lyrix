import XCTest
@testable import LyrixCore

/// The scenarios here are drawn from real Genius responses. v2 took `hits[0]`
/// unconditionally, which is exactly what these tests exist to prevent.
final class MatchScorerTests: XCTestCase {
    private func hit(_ title: String, _ artist: String, instrumental: Bool = false) -> GeniusHit {
        GeniusHit(
            title: title,
            artist: artist,
            url: URL(string: "https://genius.com/x-lyrics")!,
            isInstrumental: instrumental,
            hasLyrics: true
        )
    }

    private func track(_ title: String, _ artist: String) -> Track {
        Track(title: title, artist: artist, album: nil, sourceID: nil, isPlaying: true)
    }

    func testExactMatchScoresHighest() {
        let score = MatchScorer.score(track: track("Fool", "Djo"), hit: hit("Fool", "Djo"))
        XCTAssertGreaterThan(score, 0.95)
        XCTAssertGreaterThanOrEqual(score, MatchScorer.acceptanceThreshold)
    }

    /// The real ranking returned by Genius for "Djo Fool": the correct song is #1 and an
    /// Italian translation page is #2. The translation must not win.
    func testTranslationPageLosesToRealSong() {
        let subject = track("Fool", "Djo")
        let real = MatchScorer.score(track: subject, hit: hit("Fool", "Djo"))
        let translation = MatchScorer.score(
            track: subject,
            hit: hit("Djo - Fool (Traduzione Italiana)", "Genius Traduzioni Italiane")
        )

        XCTAssertGreaterThan(real, translation)
        XCTAssertLessThan(translation, MatchScorer.acceptanceThreshold)
    }

    /// v2's actual failure mode: when the song is not on Genius, the top hit is a
    /// different song that shares a word. It must fall below the threshold so we send
    /// the user to a search page instead of confidently opening the wrong lyrics.
    func testUnrelatedSongFallsBelowThreshold() {
        let score = MatchScorer.score(
            track: track("Fool", "Djo"),
            hit: hit("Why Do Fools Fall in Love", "Frankie Lymon & The Teenagers")
        )
        XCTAssertLessThan(score, MatchScorer.acceptanceThreshold)
    }

    func testRightTitleButWrongArtistIsRejected() {
        let score = MatchScorer.score(
            track: track("Yesterday", "The Beatles"),
            hit: hit("Yesterday", "Toni Braxton")
        )
        XCTAssertLessThan(score, MatchScorer.acceptanceThreshold,
                          "a cover by a different artist is not the song you are listening to")
    }

    func testRemasterSuffixStillMatches() {
        let score = MatchScorer.score(
            track: track("Karma Police - Remastered 2016", "Radiohead"),
            hit: hit("Karma Police", "Radiohead")
        )
        XCTAssertGreaterThanOrEqual(score, MatchScorer.acceptanceThreshold)
    }

    func testFeaturedArtistSuffixStillMatches() {
        let score = MatchScorer.score(
            track: track("Sunflower (feat. Swae Lee)", "Post Malone"),
            hit: hit("Sunflower", "Post Malone & Swae Lee")
        )
        XCTAssertGreaterThanOrEqual(score, MatchScorer.acceptanceThreshold)
    }

    func testDiacriticsAndAmpersandsAreTolerated() {
        let score = MatchScorer.score(
            track: track("Björk & Friends", "Sigur Rós"),
            hit: hit("Bjork and Friends", "Sigur Ros")
        )
        XCTAssertGreaterThanOrEqual(score, MatchScorer.acceptanceThreshold)
    }

    func testInstrumentalIsPenalised() {
        let subject = track("Flim", "Aphex Twin")
        let normal = MatchScorer.score(track: subject, hit: hit("Flim", "Aphex Twin"))
        let instrumental = MatchScorer.score(
            track: subject,
            hit: hit("Flim", "Aphex Twin", instrumental: true)
        )
        XCTAssertLessThan(instrumental, normal)
    }
}
