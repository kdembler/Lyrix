# Development

Lyrix is a Swift package with no Xcode project. `Scripts/build-app.sh` builds a
universal (arm64 + x86_64) executable and assembles `Lyrix.app` around it. Requires
Swift 6 and macOS 14+.

## Build and run

```sh
./Scripts/build-app.sh
ditto build/Lyrix.app /Applications/Lyrix.app
```

## Tests

```sh
swift test                                                  # unit tests, no network
LYRIX_INTEGRATION=1 swift test --filter GeniusIntegration    # hits the real API
```

`Tools/DNSpike` prints the raw playback notifications from Spotify and Music, which
is the quickest way to debug anything track-detection related.

## Signing

The script signs with the first code-signing identity it finds in your keychain:
Developer ID Application, then Apple Development, then ad-hoc. Set
`LYRIX_SIGN_IDENTITY` to pick one explicitly, or `-` to force ad-hoc.

With a real identity the signature stays the same across rebuilds, so macOS remembers
the Automation permission. An ad-hoc build may ask again after every rebuild.

## Notarization

Building for other Macs needs a Developer ID Application identity and a `notarytool`
keychain profile. Create the profile once, preferably from an App Store Connect API
key with the Developer role, which can't touch your iCloud data the way an
app-specific password can:

```sh
xcrun notarytool store-credentials lyrix \
    --key AuthKey_<KEYID>.p8 --key-id <KEYID> --issuer <ISSUER_ID>
```

Then:

```sh
LYRIX_NOTARY_PROFILE=lyrix ./Scripts/build-app.sh
```

That notarizes, staples the ticket, checks the result with Gatekeeper and leaves a
distributable `build/Lyrix.zip`.

## Releasing

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`
   and merge it to `main`.
2. Build a notarized copy from `main` as above.
3. Tag and publish:

   ```sh
   cp build/Lyrix.zip build/Lyrix-<version>.zip
   git tag -a v<version> -m "Lyrix <version>" && git push origin v<version>
   gh release create v<version> build/Lyrix-<version>.zip --title "Lyrix <version>"
   ```

## Credentials

Lyrix ships with no API token. It uses Genius's tokenless search endpoint and falls
back to a plain `genius.com/search?q=` URL that needs no API at all.
