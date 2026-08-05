import AppKit

@MainActor
final class AppCoordinator {
    private let monitor: NowPlayingMonitor
    private let resolver: LyricsResolver
    private let statusItem: StatusItemController

    init() {
        monitor = NowPlayingMonitor(sources: [
            DesktopAppSource(descriptor: .spotify),
            DesktopAppSource(descriptor: .music),
        ])
        resolver = LyricsResolver(client: GeniusClient(), cache: ResolutionCache())
        statusItem = StatusItemController()

        wire()
    }

    func start() {
        monitor.start()
        Log.app.info("started")
    }

    private func wire() {
        monitor.onChange = { [weak self] track in
            guard let self else { return }
            self.resolver.update(track: track)
            self.refreshUI()
        }

        resolver.onChange = { [weak self] _ in
            self?.refreshUI()
        }

        statusItem.onOpenLyrics = { [weak self] in
            self?.openLyrics()
        }

        statusItem.onCopyLink = { [weak self] in
            self?.copyLink()
        }

        statusItem.onOpenSearch = { [weak self] in
            guard let track = self?.resolver.track else { return }
            NSWorkspace.shared.open(GeniusClient.searchPageURL(for: track))
        }

        statusItem.onToggleLoginItem = {
            LoginItem.setEnabled(!LoginItem.isEnabled)
        }

        statusItem.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func refreshUI() {
        statusItem.update(
            track: resolver.track,
            resolution: resolver.resolution,
            isResolving: resolver.track != nil && resolver.resolution == nil
        )
    }

    private func openLyrics() {
        Task { [weak self] in
            guard let self, let url = await self.resolver.urlToOpen() else {
                Log.app.info("open requested with nothing playing")
                return
            }
            Log.app.info("opening \(url.absoluteString, privacy: .public)")
            NSWorkspace.shared.open(url)
        }
    }

    private func copyLink() {
        Task { [weak self] in
            guard let self, let url = await self.resolver.urlToOpen() else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
        }
    }
}
