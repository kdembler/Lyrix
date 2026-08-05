import Foundation

/// A place tracks can come from. Implemented today by the Spotify and Music desktop
/// apps; a Spotify Web API source (for playback on other devices) would slot in here
/// without touching anything downstream.
protocol NowPlayingSource: AnyObject {
    var identifier: String { get }

    /// Latest track this source knows about, or nil if the app is closed/stopped.
    var current: Track? { get }

    /// Invoked on the main thread whenever `current` changes.
    var onChange: ((Track?) -> Void)? { get set }

    func start()
    func stop()
}
