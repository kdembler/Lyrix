import Foundation

// M0 spike: prove that Spotify/Music actually post distributed notifications with a
// usable track payload on a real track change. Everything in the app's steady-state
// design depends on this. Run it, then play/skip a track.
//
//   swiftc -o /tmp/dnspike Tools/DNSpike/main.swift && /tmp/dnspike

let names = [
    "com.spotify.client.PlaybackStateChanged",
    "com.apple.Music.playerInfo",
    "com.apple.iTunes.playerInfo",
]

let dnc = DistributedNotificationCenter.default()
var eventCount = 0

for name in names {
    dnc.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { note in
        eventCount += 1
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("\n[\(stamp)] #\(eventCount) \(name)")
        guard let info = note.userInfo, !info.isEmpty else {
            print("    !! no userInfo — payload-less notification, would need AppleScript follow-up")
            fflush(stdout)
            return
        }
        for (k, v) in info.sorted(by: { "\($0.key)" < "\($1.key)" }) {
            print("    \(k) = \(String(describing: v).prefix(100))")
        }
        fflush(stdout)
    }
}

print("Listening on \(names.count) notification names.")
print("→ Play or skip a track in Spotify (or Music) now.")
print("Ctrl-C to stop.\n")
fflush(stdout)
RunLoop.main.run()
