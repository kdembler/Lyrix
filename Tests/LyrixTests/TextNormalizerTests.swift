import XCTest
@testable import LyrixCore

final class TextNormalizerTests: XCTestCase {
    func testStripsRemasterSuffix() {
        XCTAssertEqual(TextNormalizer.searchableTitle("Karma Police - Remastered 2016"), "Karma Police")
        XCTAssertEqual(TextNormalizer.searchableTitle("Come Together - Remastered"), "Come Together")
    }

    func testStripsFeaturedArtists() {
        XCTAssertEqual(TextNormalizer.searchableTitle("Sunflower (feat. Swae Lee)"), "Sunflower")
        XCTAssertEqual(TextNormalizer.searchableTitle("Forever (ft. Drake)"), "Forever")
        XCTAssertEqual(TextNormalizer.searchableTitle("Stay (with Justin Bieber)"), "Stay")
    }

    func testStripsVersionAndMixSuffixes() {
        XCTAssertEqual(TextNormalizer.searchableTitle("Blinding Lights - Radio Edit"), "Blinding Lights")
        XCTAssertEqual(TextNormalizer.searchableTitle("One More Time - Club Mix"), "One More Time")
        XCTAssertEqual(TextNormalizer.searchableTitle("Alive - Live at Wembley"), "Alive")
    }

    func testStripsBracketedNoise() {
        XCTAssertEqual(TextNormalizer.searchableTitle("Song (Deluxe Edition)"), "Song")
        XCTAssertEqual(TextNormalizer.searchableTitle("Song (Bonus Track)"), "Song")
    }

    /// A title that is *entirely* noise must not normalise to an empty query.
    func testNeverReturnsEmpty() {
        XCTAssertFalse(TextNormalizer.searchableTitle("(feat. Someone)").isEmpty)
        XCTAssertFalse(TextNormalizer.searchableTitle("- Remastered 2011").isEmpty)
    }

    func testLeavesOrdinaryTitlesAlone() {
        XCTAssertEqual(TextNormalizer.searchableTitle("Paranoid Android"), "Paranoid Android")
        // "Mix" as a real word in a title should survive, since it is not a suffix.
        XCTAssertEqual(TextNormalizer.searchableTitle("Mixed Emotions"), "Mixed Emotions")
    }

    func testComparableFlattensCasePunctuationAndDiacritics() {
        XCTAssertEqual(TextNormalizer.comparable("Björk!"), "bjork")
        XCTAssertEqual(TextNormalizer.comparable("Simon & Garfunkel"), "simon and garfunkel")
        XCTAssertEqual(TextNormalizer.comparable("  Hello,   World  "), "hello world")
    }
}

final class TrackTests: XCTestCase {
    private func track(title: String, artist: String, id: String? = nil) -> Track {
        Track(title: title, artist: artist, album: nil, sourceID: id, isPlaying: true)
    }

    func testPrimaryArtistTakesFirstOfCollaboration() {
        XCTAssertEqual(track(title: "x", artist: "Djo, Someone Else").primaryArtist, "Djo")
        XCTAssertEqual(track(title: "x", artist: "Post Malone & Swae Lee").primaryArtist, "Post Malone")
        XCTAssertEqual(track(title: "x", artist: "Calvin Harris feat. Rihanna").primaryArtist, "Calvin Harris")
    }

    func testCacheKeyPrefersStableSourceID() {
        let withID = track(title: "Fool", artist: "Djo", id: "spotify:track:abc")
        XCTAssertEqual(withID.cacheKey, "spotify:track:abc")
    }

    func testCacheKeyFallsBackToNormalisedText() {
        let a = track(title: "Fool!", artist: "Djo")
        let b = track(title: "fool", artist: "DJO")
        XCTAssertEqual(a.cacheKey, b.cacheKey, "punctuation and case must not split the cache")
    }

    func testSameSongIgnoresPlaybackState() {
        var playing = track(title: "Fool", artist: "Djo", id: "spotify:track:abc")
        var paused = playing
        paused.isPlaying = false
        playing.isPlaying = true
        XCTAssertTrue(playing.isSameSong(as: paused), "pausing must not trigger a re-resolve")
    }
}
