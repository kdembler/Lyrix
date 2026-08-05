import AppKit
import Foundation

/// Describes a music app that posts distributed notifications about playback.
struct DesktopAppDescriptor {
    let identifier: String
    let bundleID: String
    let notificationName: Notification.Name
    /// Returns "state|||name|||artist|||album|||id", or "" when nothing is loaded.
    ///
    /// NB: do not name AppleScript variables `st`, `nd`, `rd` or `th` — they are
    /// reserved as ordinal suffixes (`1st`, `2nd`) and produce a -2741 compile error.
    let trackInfoScript: String

    static let spotify = DesktopAppDescriptor(
        identifier: "spotify",
        bundleID: "com.spotify.client",
        notificationName: Notification.Name("com.spotify.client.PlaybackStateChanged"),
        trackInfoScript: """
        tell application id "com.spotify.client"
            try
                set playerStateText to player state as text
                set theTrack to current track
                return playerStateText & "|||" & (name of theTrack) & "|||" & (artist of theTrack) & "|||" & (album of theTrack) & "|||" & (id of theTrack)
            on error
                return ""
            end try
        end tell
        """
    )

    static let music = DesktopAppDescriptor(
        identifier: "music",
        bundleID: "com.apple.Music",
        notificationName: Notification.Name("com.apple.Music.playerInfo"),
        trackInfoScript: """
        tell application id "com.apple.Music"
            try
                set playerStateText to player state as text
                set theTrack to current track
                return playerStateText & "|||" & (name of theTrack) & "|||" & (artist of theTrack) & "|||" & (album of theTrack) & "|||" & (persistent ID of theTrack)
            on error
                return ""
            end try
        end tell
        """
    )
}

/// Tracks a desktop music app via distributed notifications, falling back to AppleScript
/// for the cold-start snapshot and for notifications that arrive without a usable payload.
///
/// Steady state costs nothing: no polling, no network, and no Automation prompt — the
/// notification payload carries the track. AppleScript is only touched at launch.
final class DesktopAppSource: NowPlayingSource {
    let identifier: String

    private let descriptor: DesktopAppDescriptor
    private var observerToken: NSObjectProtocol?
    private var workspaceTokens: [NSObjectProtocol] = []

    private(set) var current: Track? {
        didSet {
            guard current != oldValue else { return }
            onChange?(current)
        }
    }

    var onChange: ((Track?) -> Void)?

    init(descriptor: DesktopAppDescriptor) {
        self.descriptor = descriptor
        self.identifier = descriptor.identifier
    }

    var isAppRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: descriptor.bundleID).isEmpty
    }

    func start() {
        observerToken = DistributedNotificationCenter.default().addObserver(
            forName: descriptor.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handle(note)
        }

        // Quitting the app should clear the track; launching it should populate one.
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didTerminateApplicationNotification, NSWorkspace.didLaunchApplicationNotification] {
            let token = workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                guard let self,
                      let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      app.bundleIdentifier == self.descriptor.bundleID
                else { return }

                if name == NSWorkspace.didTerminateApplicationNotification {
                    Log.nowPlaying.info("\(self.identifier, privacy: .public) quit, clearing track")
                    self.current = nil
                } else {
                    self.refreshFromApp()
                }
            }
            workspaceTokens.append(token)
        }

        refreshFromApp()
    }

    func stop() {
        if let observerToken {
            DistributedNotificationCenter.default().removeObserver(observerToken)
        }
        observerToken = nil
        for token in workspaceTokens {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        workspaceTokens.removeAll()
    }

    // MARK: - Notification payload

    private func handle(_ note: Notification) {
        guard let info = note.userInfo else {
            Log.nowPlaying.debug("\(self.identifier, privacy: .public): payload-less notification, querying app")
            refreshFromApp()
            return
        }

        let state = (info["Player State"] as? String) ?? ""
        if state.caseInsensitiveCompare("stopped") == .orderedSame {
            current = nil
            return
        }

        guard let title = info["Name"] as? String, !title.isEmpty,
              let artist = info["Artist"] as? String, !artist.isEmpty
        else {
            // Some notifications omit the track (e.g. bare state flips). Ask the app.
            Log.nowPlaying.debug("\(self.identifier, privacy: .public): incomplete payload, querying app")
            refreshFromApp()
            return
        }

        current = Track(
            title: title,
            artist: artist,
            album: info["Album"] as? String,
            sourceID: info["Track ID"] as? String,
            isPlaying: state.caseInsensitiveCompare("playing") == .orderedSame
        )
        Log.nowPlaying.info("\(self.identifier, privacy: .public) → \(self.current?.display ?? "nil", privacy: .public)")
    }

    // MARK: - AppleScript fallback

    /// Never call unguarded: `tell application` would *launch* the app if it is closed.
    private func refreshFromApp() {
        guard isAppRunning else {
            current = nil
            return
        }

        AppleScriptRunner.run(descriptor.trackInfoScript) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let raw):
                let parsed = Self.parse(raw)
                Log.nowPlaying.info(
                    "\(self.identifier, privacy: .public) cold start → \(parsed?.display ?? "nothing loaded", privacy: .public)"
                )
                self.current = parsed
            case .failure(.notPermitted):
                Log.nowPlaying.error(
                    "\(self.identifier, privacy: .public): Automation permission denied — cold-start snapshot unavailable, will populate on next track change"
                )
            case .failure(let error):
                Log.nowPlaying.error("\(self.identifier, privacy: .public): AppleScript failed — \(String(describing: error), privacy: .public)")
            }
        }
    }

    static func parse(_ raw: String) -> Track? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.components(separatedBy: "|||")
        guard parts.count >= 5 else { return nil }

        let state = parts[0]
        guard state.caseInsensitiveCompare("stopped") != .orderedSame else { return nil }

        let title = parts[1].trimmingCharacters(in: .whitespaces)
        let artist = parts[2].trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, !artist.isEmpty else { return nil }

        let album = parts[3].trimmingCharacters(in: .whitespaces)
        let id = parts[4].trimmingCharacters(in: .whitespaces)

        return Track(
            title: title,
            artist: artist,
            album: album.isEmpty ? nil : album,
            sourceID: id.isEmpty ? nil : id,
            isPlaying: state.caseInsensitiveCompare("playing") == .orderedSame
        )
    }
}
