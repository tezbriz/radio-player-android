# Radio

A simple, ad-free, telemetry-free internet radio player for Android, built with Flutter.

This is the Android counterpart to a matching desktop app (GTK3/Python) — same dark-gold
theme, same station source, same philosophy: it talks to exactly one external service
([radio-browser.info](https://www.radio-browser.info/), a free public station directory)
and whatever stream you choose to play. No ads, no analytics, no accounts, no tracking.

## Installing

No Play Store account needed — grab the signed APK from the
[latest release](https://github.com/tezbriz/radio-player-android/releases/latest) and
sideload it directly from your phone:

1. Open the release page above **on the phone** and tap the `.apk` file to download it.
2. Open the downloaded file (from the download notification, or the Files/Downloads app).
3. Android will show an **"Install unknown apps"** warning the first time — this is
   expected for anything not from the Play Store. Tap through it; it'll offer to take you
   straight to the permission toggle for whichever app you downloaded it with (e.g. Chrome).
   It's a one-time step per app used to install.
4. It may also show a **Play Protect** scan warning, also expected for a non-Play-Store
   APK — tap "Install anyway".
5. Tap **Install**, then **Open**.
6. On first launch, allow the **notification permission** if prompted — it's needed for
   the lock-screen/media playback controls.

That's it. No Google account, no Play Store, nothing else required. Since the APK is
self-signed rather than store-issued, it will never show as "verified" the way a Play
Store app does — the warning in step 4 is expected, not a sign anything's wrong.

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
