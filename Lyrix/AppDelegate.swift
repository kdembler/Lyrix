import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var barItem: NSStatusItem
    var actionItem: NSMenuItem!

    var spotifyApi: SpotifyApi?

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

        if Store.shared.spotifyApiDetailsSet {
            spotifyApi = SpotifyApi()
        }
        let isAuthenticated = spotifyApi?.isAuthenticated ?? false
        if isAuthenticated {
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

    func startTrackUpdateTimer() {
        trackUpdateTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateTrackInfo), userInfo: nil, repeats: true)
    }

    func stopTrackUpdateTimer() {
        trackUpdateTimer?.invalidate()
        trackUpdateTimer = nil
    }

    @objc func handleURLCallback(event: NSAppleEventDescriptor) {
        guard let spotifyApi = self.spotifyApi else {
            print("handleURLCallback without spotifyApi")
            return
        }
        spotifyApi.handleAuthCallback(event)
    }

    @objc func handlePreferencesSaved() {
        if Store.shared.spotifyApiDetailsSet {
            spotifyApi = SpotifyApi()
            refreshMenu()
        }
    }

    func refreshMenu() {
        let menu = NSMenu()

        actionItem = NSMenuItem()

        let isAuthenticated = spotifyApi?.isAuthenticated ?? false

        if isAuthenticated {
            actionItem.title = "Get track"
            actionItem.action = #selector(openSongLyrics)
        } else if Store.shared.spotifyApiDetailsSet {
            actionItem.title = "Login"
            actionItem.action = #selector(loginToSpotify)
        } else {
            actionItem.title = "Spotify API details missing"
        }
        menu.addItem(actionItem)

        menu.addItem(NSMenuItem.separator())

        if isAuthenticated {
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
        guard let spotifyApi = self.spotifyApi else {
            print("loginToSpotify without spotifyApi")
            return
        }
        spotifyApi.authorize() { result in
            if case .success = result {
                self.refreshMenu()
                self.updateTrackInfo()
                self.startTrackUpdateTimer()
            }
        }
    }

    @objc func logoutFromSpotify() {
        guard let spotifyApi = self.spotifyApi else {
            print("logoutFromSpotify without spotifyApi")
            return
        }
        spotifyApi.logout() {
            self.stopTrackUpdateTimer()
            self.refreshMenu()
        }
    }

    @objc func updateTrackInfo() {
        guard let spotifyApi = self.spotifyApi else {
            print("updateTrackInfo without spotifyApi")
            return
        }
        DispatchQueue.main.async {
            spotifyApi.getCurrentTrackInfo() { result in
                switch result {
                case .success(let track):
                    let status = "\(track.name) by \(track.artists.joined(separator: ", "))"
                    self.actionItem.title = status
                    self.track = track
                case .failure(let reason):
                    switch reason {
                    case .noPlayerAvailable:
                        self.actionItem.title = "No player available"
                    default:
                        self.actionItem.title = "Error"
                        print("Getting track info failed")
                    }
                }
            }
        }
    }

    @objc func openSongLyrics() {
        GeniusApi.getLyricsLink(track: track!) {result in
            switch result {
            case .success(let songUrlString):
                print("Got URL")
                print(songUrlString)
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
