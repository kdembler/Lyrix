import XCTest
@testable import LyrixCore

/// Parsing of the AppleScript cold-start snapshot. The delimiter is "|||" because a
/// tab inside an AppleScript string literal is fragile to embed from Swift.
final class DesktopAppSourceTests: XCTestCase {
    func testParsesFullResponse() {
        let track = DesktopAppSource.parse(
            "playing|||Fool|||Djo|||Twenty Twenty|||spotify:track:56sDw3DIGcUStBO5SguYPK"
        )
        XCTAssertEqual(track?.title, "Fool")
        XCTAssertEqual(track?.artist, "Djo")
        XCTAssertEqual(track?.album, "Twenty Twenty")
        XCTAssertEqual(track?.sourceID, "spotify:track:56sDw3DIGcUStBO5SguYPK")
        XCTAssertEqual(track?.isPlaying, true)
    }

    func testPausedTrackIsStillReturned() {
        // Pausing to go read the lyrics is the exact moment this app is useful.
        let track = DesktopAppSource.parse("paused|||Fool|||Djo|||Twenty Twenty|||spotify:track:abc")
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.isPlaying, false)
    }

    func testStoppedYieldsNil() {
        XCTAssertNil(DesktopAppSource.parse("stopped|||||||||"))
    }

    func testEmptyResponseYieldsNil() {
        XCTAssertNil(DesktopAppSource.parse(""))
        XCTAssertNil(DesktopAppSource.parse("   \n "))
    }

    func testTruncatedResponseYieldsNil() {
        XCTAssertNil(DesktopAppSource.parse("playing|||Fool"))
    }

    func testMissingTitleOrArtistYieldsNil() {
        XCTAssertNil(DesktopAppSource.parse("playing||||||Album|||id"))
        XCTAssertNil(DesktopAppSource.parse("playing|||Title||||||id"))
    }

    func testMissingAlbumAndIDAreOptional() {
        let track = DesktopAppSource.parse("playing|||Fool|||Djo||||||")
        XCTAssertEqual(track?.title, "Fool")
        XCTAssertNil(track?.album)
        XCTAssertNil(track?.sourceID)
    }
}
