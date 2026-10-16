<div align="center">
  <img height="128" width="128" alt="Lyrix" src="Resources/icon.png"/>

  <h1>Lyrix</h1>

  <p><strong>One click from the song you're playing to its lyrics.</strong></p>

  <p><a href="https://github.com/kdembler/Lyrix/releases/latest"><strong>Download for macOS</strong></a></p>
</div>

Lyrix sits in your menu bar and keeps track of what's playing in Spotify or Apple
Music. Click the icon and the Genius lyrics page for that song opens in your browser.
That's the whole app.

- **Instant** — the lyrics link is found as soon as the track changes, so the click
  just opens it.
- **Honest** — if Lyrix isn't sure it found the right song, it opens a Genius search
  instead of the wrong lyrics.
- **Nothing to set up** — no account, no login, no API key.
- **Light** — a small native app that sits idle until the track changes.

## Install

1. Download the latest `Lyrix-<version>.zip` from
   [Releases](https://github.com/kdembler/Lyrix/releases/latest).
2. Unzip it and drag **Lyrix.app** to your Applications folder.
3. Open it. A music-note icon appears in the menu bar.

Requires macOS 14 Sonoma or later. Works on Apple Silicon and Intel Macs.

The first time it starts, macOS asks whether Lyrix may control Spotify or Music. Allow
it so Lyrix can see a song that was already playing when it launched. If you decline,
Lyrix still works; it just picks up from the next track.

To start Lyrix automatically, right-click the icon and choose **Launch at Login**.

## Using it

| | |
|---|---|
| **Click** the icon | Open the lyrics for the current song |
| **Right-click** the icon | See the song and what it matched, copy the link, search Genius yourself, toggle Launch at Login, or quit |

The icon is dimmed when nothing is playing.

## Questions

**It opened a Genius search instead of the lyrics.**
Lyrix only opens a lyrics page when it's confident it's the right song. Live versions,
remixes and songs that aren't on Genius often end up as a search. Pick the right
result from there.

**It doesn't notice what I'm playing.**
Lyrix works with the Spotify and Apple Music desktop apps, not the Spotify web player
or other players. If it misses the song that was playing when it launched, skip to the
next track, or allow it under System Settings → Privacy & Security → Automation.

**What does it send over the network?**
Only the title and artist of each new track, to Genius's search, to find the lyrics
page. Results are cached on your Mac (in `~/Library/Application Support/Lyrix`), so a
song you've played before costs no request at all. There's no analytics or tracking.

**How do I uninstall it?**
Quit it from the right-click menu, then delete Lyrix.app from Applications and,
optionally, `~/Library/Application Support/Lyrix`.

## Building from source

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for building, signing and releasing,
and [docs/DESIGN.md](docs/DESIGN.md) for why Lyrix works the way it does.

## Credits

Icon from [iconmonstr](https://iconmonstr.com/). Lyrics are hosted by
[Genius](https://genius.com); Lyrix isn't affiliated with Genius, Spotify or Apple.

ISC licensed. Earlier Swift and Electron versions are kept on the `old_swift` and
`old_electron` branches.
