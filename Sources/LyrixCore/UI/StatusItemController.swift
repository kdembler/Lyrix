import AppKit

/// The entire UI. Left-click opens lyrics; right-click opens a menu.
///
/// v2 put a 300x180 React popover here and made "Open lyrics" a button inside it,
/// which meant two clicks and a network round-trip. The icon *is* the button now.
@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem

    var onOpenLyrics: (() -> Void)?
    var onCopyLink: (() -> Void)?
    var onOpenSearch: (() -> Void)?
    var onToggleLoginItem: (() -> Void)?
    var onQuit: (() -> Void)?

    private var track: Track?
    private var resolution: Resolution?
    private var isResolving = false

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "music.note.list",
                accessibilityDescription: "Lyrix"
            )
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        render()
    }

    func update(track: Track?, resolution: Resolution?, isResolving: Bool) {
        self.track = track
        self.resolution = resolution
        self.isResolving = isResolving
        render()
    }

    private func render() {
        guard let button = statusItem.button else { return }
        // Dim when there is nothing to open, so the icon reflects whether a click will do anything.
        button.alphaValue = track == nil ? 0.45 : 1.0
        button.toolTip = track.map { track in
            if let resolution, !resolution.isFallback {
                return "\(track.display)\n→ \(resolution.matchedDisplay)"
            }
            return track.display
        } ?? "Lyrix — nothing playing"
    }

    @objc private func handleClick() {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
        if isRightClick {
            showMenu()
        } else {
            onOpenLyrics?()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        if let track {
            let header = NSMenuItem(title: track.display, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            let statusTitle: String
            if isResolving {
                statusTitle = "Finding lyrics…"
            } else if let resolution, !resolution.isFallback {
                statusTitle = "→ \(resolution.matchedDisplay)"
            } else {
                statusTitle = "No confident match — will open search"
            }
            let status = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
            status.isEnabled = false
            menu.addItem(status)

            menu.addItem(.separator())
            menu.addItem(item(title: "Open Lyrics", action: #selector(menuOpenLyrics), key: "l"))
            menu.addItem(item(title: "Copy Link", action: #selector(menuCopyLink), key: "c"))
            menu.addItem(item(title: "Search on Genius", action: #selector(menuOpenSearch), key: ""))
        } else {
            let header = NSMenuItem(title: "Nothing playing", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
        }

        menu.addItem(.separator())

        let loginToggle = item(title: "Launch at Login", action: #selector(menuToggleLoginItem), key: "")
        loginToggle.state = LoginItem.isEnabled ? .on : .off
        loginToggle.isEnabled = LoginItem.isAvailable
        menu.addItem(loginToggle)

        menu.addItem(.separator())
        menu.addItem(item(title: "Quit Lyrix", action: #selector(menuQuit), key: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func item(title: String, action: Selector, key: String) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.target = self
        return menuItem
    }

    @objc private func menuOpenLyrics() { onOpenLyrics?() }
    @objc private func menuCopyLink() { onCopyLink?() }
    @objc private func menuOpenSearch() { onOpenSearch?() }
    @objc private func menuToggleLoginItem() { onToggleLoginItem?() }
    @objc private func menuQuit() { onQuit?() }
}
