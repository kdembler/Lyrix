import Foundation
import XCTest
@testable import LyrixCore

/// The embedded AppleScript is a string literal, so a typo in it is invisible to the
/// Swift compiler and only shows up at runtime. `compileAndReturnError` checks syntax
/// without executing anything — no app is launched and no Automation prompt appears.
///
/// This exists because `set st to player state` shipped and failed with -2741:
/// `st` is reserved as an ordinal suffix (1st, 2nd, 3rd).
final class AppleScriptCompileTests: XCTestCase {
    private func assertCompiles(_ source: String, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let script = NSAppleScript(source: source) else {
            return XCTFail("\(label): NSAppleScript could not be constructed", file: file, line: line)
        }
        var error: NSDictionary?
        let compiled = script.compileAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? -1
            let message = error[NSAppleScript.errorMessage] as? String ?? "unknown"
            XCTFail("\(label): AppleScript failed to compile (\(code)) — \(message)", file: file, line: line)
        }
        XCTAssertTrue(compiled, "\(label): expected a successful compile", file: file, line: line)
    }

    func testSpotifyScriptCompiles() {
        assertCompiles(DesktopAppDescriptor.spotify.trackInfoScript, "spotify")
    }

    func testMusicScriptCompiles() {
        assertCompiles(DesktopAppDescriptor.music.trackInfoScript, "music")
    }

    /// Guards the specific trap directly, so the reason the tests above exist stays legible.
    func testAppleScriptOrdinalSuffixesAreReserved() {
        guard let script = NSAppleScript(source: "set st to 1\nreturn st") else {
            return XCTFail("could not construct script")
        }
        var error: NSDictionary?
        _ = script.compileAndReturnError(&error)
        XCTAssertNotNil(error, "`st` is a reserved ordinal suffix; if this ever compiles, the workaround can be dropped")
    }
}
