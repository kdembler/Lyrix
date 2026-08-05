import Foundation

/// Runs AppleScript on a dedicated serial queue.
///
/// `NSAppleScript` is not thread-safe, but confining every use to a single queue is.
/// We keep it off the main thread specifically because the first call can block on a
/// TCC "Lyrix wants to control Spotify" prompt — on the main thread that would beachball
/// the menu bar.
enum AppleScriptRunner {
    private static let queue = DispatchQueue(label: "dev.kdembler.lyrix.applescript")

    enum Failure: Error {
        /// User denied Automation access (or has not granted it yet).
        case notPermitted
        case compileFailed
        case scriptError(code: Int, message: String)
    }

    static func run(_ source: String, completion: @escaping (Result<String, Failure>) -> Void) {
        queue.async {
            let result = runSync(source)
            DispatchQueue.main.async { completion(result) }
        }
    }

    private static func runSync(_ source: String) -> Result<String, Failure> {
        guard let script = NSAppleScript(source: source) else {
            return .failure(.compileFailed)
        }

        var errorInfo: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let code = (errorInfo[NSAppleScript.errorNumber] as? Int) ?? -1
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "unknown error"
            // -1743 errAEEventNotPermitted, -1744 errAEEventWouldRequireUserConsent
            if code == -1743 || code == -1744 {
                return .failure(.notPermitted)
            }
            return .failure(.scriptError(code: code, message: message))
        }

        return .success(descriptor.stringValue ?? "")
    }
}
