import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    /// Top-level code in main.swift is a nonisolated context; nothing here touches
    /// main-actor state, so construction is safe from it.
    nonisolated override init() { super.init() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator = AppCoordinator()
        coordinator?.start()
    }
}

/// Single public entry point, so the executable target stays a three-line shim and
/// everything else remains testable.
public enum LyrixMain {
    private static var delegate: AppDelegate?

    public static func run() {
        let app = NSApplication.shared
        // Menu bar only: no Dock icon, no app switcher entry.
        app.setActivationPolicy(.accessory)

        let delegate = AppDelegate()
        Self.delegate = delegate  // NSApplication holds its delegate weakly
        app.delegate = delegate
        app.run()
    }
}
