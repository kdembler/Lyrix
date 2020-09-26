import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var barItem: NSStatusItem
    var actionItem: NSMenuItem!

    var spotifyApi = SpotifyApi()

    override init() {
        barItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
    }

    var preferencesWindow: NSWindow?
    var trackUpdateTimer: Timer?
    var track: TrackInfo?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURLCallback(event:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreferencesSaved), name: preferencesSavedNotification, object: nil)
        killLauncherApp()

        if spotifyApi.auth.isAuthenticated {
            updateTrackInfo()
            startTrackUpdateTimer()
        }

        guard let button = barItem.button else {
            print("Failed adding status bar icon")
            quit()
            return
        }
        button.image = NSImage(named: "MenuBarIcon")

        refreshMenu()
    }

    func killLauncherApp() {
        let runningApps = NSWorkspace.shared.runningApplications
        let launcherRunning = !runningApps.filter {
            $0.bundleIdentifier == launcherIdentifier
        }.isEmpty

        if launcherRunning {
            DistributedNotificationCenter.default().post(name: killLauncherNotification, object: appIdentifier)
        }
    }

    func startTrackUpdateTimer() {
        trackUpdateTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateTrackInfo), userInfo: nil, repeats: true)
    }

    func stopTrackUpdateTimer() {
        trackUpdateTimer?.invalidate()
        trackUpdateTimer = nil
    }

    @objc func handleURLCallback(event: NSAppleEventDescriptor) {
        spotifyApi.auth.handleAuthCallback(event)
    }

    @objc func handlePreferencesSaved() {
        refreshMenu()
    }

    func refreshMenu() {
        let menu = NSMenu()

        actionItem = NSMenuItem()

        if spotifyApi.auth.isAuthenticated {
            actionItem.title = "Fetching..."
        } else {
            actionItem.title = "Login"
            actionItem.action = #selector(loginToSpotify)
        }
        menu.addItem(actionItem)

        menu.addItem(NSMenuItem.separator())

        if spotifyApi.auth.isAuthenticated {
            let logoutItem = NSMenuItem()
            logoutItem.title = "Logout"
            logoutItem.action = #selector(logoutFromSpotify)
            menu.addItem(logoutItem)
        }

        let preferencesItem = NSMenuItem()
        preferencesItem.title = "Preferences..."
        preferencesItem.action = #selector(showPreferences)
        menu.addItem(preferencesItem)

        let quitItem = NSMenuItem()
        quitItem.title = "Quit"
        quitItem.action = #selector(quit)
        menu.addItem(quitItem)

        barItem.menu = menu
    }

    @objc func loginToSpotify() {
        spotifyApi.auth.authorize() { result in
            if case .success = result {
                self.refreshMenu()
                self.updateTrackInfo()
                self.startTrackUpdateTimer()
            }
        }
    }

    @objc func logoutFromSpotify() {
        spotifyApi.auth.logout() {
            self.stopTrackUpdateTimer()
            self.refreshMenu()
        }
    }

    @objc func updateTrackInfo() {
        DispatchQueue.main.async {
            self.spotifyApi.getCurrentTrackInfo() { result in
                switch result {
                case .success(let track):
                    let status = "\(track.name) by \(track.artists.joined(separator: ", "))"
                    self.actionItem.title = status
                    self.actionItem.action = #selector(self.openSongLyrics)
                    self.track = track
                case .failure(let reason):
                    switch reason {
                    case .noPlayerAvailable:
                        self.actionItem.title = "No player available"
                    default:
                        self.actionItem.title = "Error"
                        print("Getting track info failed")
                    }
                    self.actionItem.action = nil
                }
            }
        }
    }

    @objc func openSongLyrics() {
        GeniusApi.getLyricsLink(track: track!) { result in
            switch result {
            case .success(let songUrlString):
                print("opening lyrics URL: \(songUrlString)")
                let songUrl = URL(string: songUrlString)!
                NSWorkspace.shared.open(songUrl)
            case .failure:
                print("failed")
            }
        }
    }

    @objc func showPreferences() {
        if preferencesWindow == nil {
            let hostingController = NSHostingController(rootView: PreferencesView())
            preferencesWindow = NSWindow(contentViewController: hostingController)
            preferencesWindow!.title = "Lyrix preferences"
            preferencesWindow!.styleMask = [.titled, .closable]
        }
        preferencesWindow!.center()
        preferencesWindow!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApplication.shared.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        stopTrackUpdateTimer()
    }
}
