//
//  AppDelegate.swift
//  SpotifyBar
//
//  Created by Klaudiusz Dembler on 26/01/2018.
//  Copyright © 2018 Klaudiusz Dembler. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var trackInfoMenuItem: NSMenuItem =  NSMenuItem()
    var timer: Timer = Timer()
    var artist = ""
    var track = ""
    var bearerToken = "8W9Uq9vyoFPNTiIL3djSBxhrcSdO9J2oWRiuhqynWcr44W3Dy1i3q8DqcPFR34zd"
    let defaults = UserDefaults.standard
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let appBundleIdentifier = "com.kdembler.SpotifyBarHelper"
        let autoLaunch = true
        if SMLoginItemSetEnabled(appBundleIdentifier as CFString, autoLaunch) {
            NSLog("Successfully add login item.")
        } else {
            NSLog("Failed to add login item.")
        }
        if let defaultToken = defaults.string(forKey: "bearerToken") {
            bearerToken = defaultToken
        }
        statusBarItem = NSStatusBar.system.statusItem(withLength: -1)
        statusBarItem.image = #imageLiteral(resourceName: "Icon")
        statusBarItem.highlightMode = true
        statusBarItem.menu = menu
        
        trackInfoMenuItem.title = "SpotifyBar"
        menu.addItem(trackInfoMenuItem)
        fetch()
        timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(fetch), userInfo: nil, repeats: true)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem()
        quitItem.title = "Quit"
        quitItem.action = #selector(quit)
        menu.addItem(quitItem)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        timer.invalidate()
    }
    
    func removeFeat(_ val: String) -> String {
        var str = val
        if let range = val.lowercased().range(of: " (feat.") {
            str = String(val.prefix(upTo: range.lowerBound))
        } else if let range = val.lowercased().range(of: " feat.") {
            str = String(val.prefix(upTo: range.lowerBound))
        }
        return str
    }
    
    @objc func getLyrics() {
        let escaped = "\(artist) \(track)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let apiPrefix = "https://api.genius.com/search?q=\(escaped)"
        guard let searchURL = URL(string: apiPrefix) else { return }
        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let result = data {
                // parse JSON response
                guard let json = try? JSONSerialization.jsonObject(with: result, options: []) else { return }
                if let dict = json as? [String: Any] {
                    if let resp = dict["response"] as? [String: Any] {
                        if let hits = resp["hits"] as? [Any] {
                            if hits.count > 0 {
                                if let hit = hits[0] as? [String: Any] {
                                    if let info = hit["result"] as? [String: Any] {
                                        if let songPath = info["api_path"] as? String {
                                            if let songURL = URL(string: "https://genius.com" + songPath) {
                                                // I really hope there is some way to do this with less nesting
                                                NSWorkspace.shared.open(songURL)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func fetch() {
        DispatchQueue.main.async {
            var v = ""
            do {
                (self.artist, self.track) = try SpotifyApi.getArtistAndTitle()
                self.artist = self.removeFeat(self.artist)
                self.track = self.removeFeat(self.track)
                v = "\(self.track) by \(self.artist)"
                self.trackInfoMenuItem.action = #selector(self.getLyrics)
            } catch {
                v = "Fetch error"
                self.trackInfoMenuItem.action = nil
            }
            Swift.print(v)
            self.trackInfoMenuItem.title = v
        }
    }
}

struct SpotifyApi {
    enum ApiError: Error {
        case fetch
    }
    static let prefix = "tell application \"Spotify\" to"
    
    static func getArtistAndTitle() throws -> (String, String) {
        let artist = try executeScript("artist of current track as string")
        let title = try executeScript("name of current track as string")
        return (artist, title)
    }
    
    static private func executeScript(_ query: String) throws -> String {
        let script = NSAppleScript(source: "\(prefix) \(query)")
        var err : NSDictionary?
        let result = script?.executeAndReturnError(&err)
        if let output = result?.stringValue {
            return output
        }
        throw ApiError.fetch
    }
}


