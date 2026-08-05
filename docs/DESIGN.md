# Design notes

Why Lyrix works the way it does. Mostly this is a record of things that were verified
rather than assumed, so the next person (or the next rewrite) doesn't have to
rediscover them.

## The interaction is the feature

The Electron version put a popover between you and the link:

```
click tray → popover renders → click "Open lyrics" → API call → browser opens
```

Two clicks, with the network round-trip happening *after* the second one. That is
barely cheaper than searching Genius by hand, which is why it never became a habit.

Everything here follows from inverting that: resolve the URL when the **track**
changes, not when you click. The click then does one thing, instantly, and the icon
itself is the button.

## Track detection

Verified July 2026 on macOS 26.5.2:

| Approach | Result |
|---|---|
| MediaRemote private framework | **Unusable.** Symbols still resolve, but `MRMediaRemoteGetNowPlayingInfo` returns an empty dictionary — from a bare binary *and* from a signed `.app` with a bundle identifier. Entitlement-gated since macOS 15.4. |
| `com.spotify.client.PlaybackStateChanged` | Fires on every real track change with `Name`, `Artist`, `Album`, `Player State` and `Track ID` in `userInfo`. Unentitled, no permission prompt. |
| Spotify AppleScript dictionary | Intact. Exposes `name`, `artist`, `album`, `spotify url`, `player state`. |

MediaRemote is the only route to *system-wide* now-playing (browsers, VLC, anything
using the now-playing centre). It is closed, so this app covers the Spotify and Music
desktop apps and nothing else.

Distributed notifications carry the whole track, so steady state needs no polling, no
network and no Automation permission. AppleScript is used for exactly one thing: the
snapshot at launch of what is already playing. Declining that prompt degrades
gracefully — the app starts working at the next track change.

Sources sit behind the `NowPlayingSource` protocol. A Spotify Web API source, for
playback on a phone or another device, would slot in there without touching anything
downstream. It is deliberately not built: it costs OAuth, token refresh, polling
latency and rate limits, which is most of what made the Electron version heavy.

Two footguns worth knowing:

- `tell application "Spotify"` **launches Spotify** if it isn't running. Every
  AppleScript call is guarded by an `NSRunningApplication` check first.
- Do not name an AppleScript variable `st`, `nd`, `rd` or `th` — they're reserved as
  ordinal suffixes (`1st`, `2nd`) and produce a `-2741` compile error. Because these
  scripts are Swift string literals, the compiler can't catch it, so the test suite
  compiles them via `compileAndReturnError`.

## Matching

The Electron version opened Genius's first search hit unconditionally. That silently
returns the wrong page whenever the song isn't on Genius. A real query for
`Djo Fool` returns, in order: the correct song, an Italian translation page, and
`Why Do Fools Fall in Love` — so a blind `hits[0]` on any track Genius doesn't have
lands somewhere confidently wrong.

`MatchScorer` scores each hit as:

```
title × (artistFloor + (1 - artistFloor) × artist)
```

Multiplicative, not a weighted sum. "The same song" means the artist *and* the title
match — a conjunction. A weighted sum lets a perfect title compensate for a completely
wrong artist, which scored covers (`Yesterday` by Toni Braxton) as though they were
the track you were listening to. Below `acceptanceThreshold` the app opens a Genius
search page instead of guessing.

String similarity blends token-set overlap with edit distance, and containment is
checked **token-wise rather than by substring** — raw `contains` treats `Fool` as
matching `Why Do Fools Fall in Love`.

Translation pages (`Genius Traduzioni Italiane` and friends) and instrumentals are
penalised explicitly.

## Never do nothing

A click always opens something. If resolution failed, is uncertain, or hasn't finished
yet, the fallback is a plain `genius.com/search?q=` URL, which requires no API and
cannot fail to construct. The Electron version logged Genius errors and left the button
inert, which reads as a broken app.

Confident resolutions are cached to disk, keyed by the source's stable track ID.
Fallbacks are deliberately *not* cached — they represent a failed lookup, and the next
play should retry rather than permanently remember the failure.

## Not built

- Global hotkey
- Settings window, including optional Genius API token entry
- Developer ID signing and notarization
