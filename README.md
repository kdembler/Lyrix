<div align="center">
  <img height="128" width="128" alt="Lyrix" src="Resources/icon.png"/>

  <strong>Lyrix — a Genius link, always in your menu bar</strong>
</div>

Click the menu bar icon and the lyrics for whatever you're playing open in your
browser. That's the whole app.

A native macOS menu bar app for Spotify and Music. No account, no login, no polling —
it listens for the playback notifications those apps already broadcast, finds the
Genius page the moment the track changes, and caches it. By the time you click, the
link is already resolved.

## Install

```sh
./Scripts/build-app.sh
cp -r build/Lyrix.app /Applications/
```

Requires macOS 14+ and Swift 6. There's no Xcode project — it's a Swift package, and
the script assembles the `.app` around the built executable.

The build is ad-hoc signed, so macOS may ask for Automation permission again after
each rebuild.

## Usage

- **Left-click** the icon — opens the lyrics.
- **Right-click** — current track, what it matched, copy link, search on Genius,
  launch at login, quit.

The icon is dimmed when nothing is playing.

## How it works

Spotify and Music broadcast a distributed notification on every track change,
carrying the title, artist, album and a stable track ID. Lyrix listens for those, so
steady-state operation costs no polling, no network and no permission prompt. A single
AppleScript query at launch covers what's already playing — that's the only part that
needs Automation access, and if you decline it the app simply starts working at the
next track change.

Each track is scored against Genius search results before opening anything. Below the
confidence threshold it opens a Genius *search* page rather than guessing, so it
either takes you to the right song or admits it isn't sure.

See [docs/DESIGN.md](docs/DESIGN.md) for why it works this way.

## Development

```sh
swift test                                                  # unit tests, no network
LYRIX_INTEGRATION=1 swift test --filter GeniusIntegration    # hits the real API
```

`Tools/DNSpike` prints the raw playback notifications, which is the quickest way to
debug anything track-detection related.

## Credentials

Ships with no API token. It uses Genius's tokenless search endpoint and falls back to
a plain `genius.com/search?q=` URL that needs no API at all.

## History

The original was written in Swift, then rewritten in Electron (`v1.0.0`, preserved on
the `old_electron` branch). This is a ground-up native rewrite; the earlier versions
are tagged if you want them.

## Credits

Icon from [iconmonstr](https://iconmonstr.com/).

## License

ISC
