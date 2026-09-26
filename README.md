# Radio

A simple, ad-free, telemetry-free internet radio player for Android, built with Flutter.

This is the Android counterpart to a matching desktop app (GTK3/Python) — same dark-gold
theme, same station source, same philosophy: it talks to exactly one external service
([radio-browser.info](https://www.radio-browser.info/), a free public station directory)
and whatever stream you choose to play. No ads, no analytics, no accounts, no tracking.

## Features

- Search and browse stations by country (or worldwide)
- Favourites, saved locally on-device
- Background playback with proper Android media-session integration — lock-screen and
  notification controls (play/pause), survives being swiped away from Recents (same as
  Spotify/YouTube Music)
- Live now-playing metadata (ICY song titles) where a station provides them
- Sleep timer
- Volume control with mute
- A–Z sort toggle

## Privacy

The app's own network activity is limited to:

1. `radio-browser.info` — to search/list stations
2. The stream URL of whichever station you choose to play

No other endpoint is contacted. No analytics or crash-reporting SDKs are included. All
local state (favourites, last-played station, volume) is stored on-device via
SharedPreferences and never leaves the phone.

## Building

Requires the Flutter SDK and Android SDK/NDK set up (`flutter doctor` should be clean for
Android). Then:

```bash
flutter pub get
flutter build apk --release   # or: flutter build appbundle --release
```

The release build needs `android/key.properties` (gitignored, not included in this repo)
pointing at a signing keystore — see
[Flutter's docs on signing](https://docs.flutter.dev/deployment/android#signing-the-app)
for how to generate one. Without it, the build falls back to debug signing.

## License

MIT — see [LICENSE](LICENSE).
