//
//  AppDelegate.swift
//  SpotifyBar
//
//  Created by Klaudiusz Dembler on 26/01/2018.
//  Copyright © 2018 Klaudiusz Dembler. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu : NSMenu = NSMenu()
    var trackInfoMenuItem : NSMenuItem =  NSMenuItem()
    var timer : Timer = Timer()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: -1)
        statusBarItem.menu = menu
        statusBarItem.title = "SpotifyBar"
        statusBarItem.highlightMode = true
        
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
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func fetch() {
        var v = ""
        do {
            let (artist, track) = try SpotifyApi.getArtistAndTitle()
            v = "\(track) by \(artist)"
        } catch {
            v = "Fetch error"
        }
        trackInfoMenuItem.title = v
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
    
    static func executeScript(_ query: String) throws -> String {
        let script = NSAppleScript(source: "\(prefix) \(query)")
        var err : NSDictionary?
        let result = script?.executeAndReturnError(&err)
        if let output = result?.stringValue {
            return output
        }
        throw ApiError.fetch
    }
}


