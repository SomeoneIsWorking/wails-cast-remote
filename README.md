# WailsCast Remote

A Flutter companion app that remote-controls the [wails-cast](https://github.com/SomeoneIsWorking/wails-cast)
desktop media player over your local network. Browse the library, pick an output
device (the desktop or a Chromecast), choose tracks, and drive playback — all
from your phone.

## Features

- **Auto-discovery** of wails-cast desktops on the LAN via mDNS (`_wailscast._tcp`),
  plus manual host/port/token connection.
- **Output device selector** — cast to a discovered Chromecast or play on the
  desktop itself ("local").
- **Library browsing** and **Play URL** for arbitrary media.
- **Pre-play options** — choose video / audio / subtitle track and quality.
- **Now Playing controls** — play/pause, seek (±10s / ±30s + scrubber), volume,
  mute, and stop, with live position.
- **Per-episode subtitle translation** — see whether a translation already
  exists and trigger one with live progress.
- **Settings** — subtitle font size, burn-in, default quality, default
  translation language (synced to the desktop).

## Requirements

- A running [wails-cast](https://github.com/SomeoneIsWorking/wails-cast) desktop
  instance with the **Remote API enabled** in its settings.
- The phone and desktop on the same network.
- Flutter SDK `>=3.44.0` (Dart `>=3.12.0`) and Android SDK API 36 to build
  the Android client.

## Getting started

```bash
flutter pub get
flutter run        # with a device/emulator attached
# or build a debug APK:
flutter build apk --debug
```

On first launch, either tap a discovered server or enter the desktop's host, the
Remote API port (default `9999`), and the optional auth token.

## How it talks to the desktop

The app is a thin client over the desktop's HTTP remote API
(`/devices`, `/library`, `/track-info`, `/play`, `/control`, `/state`,
`/translate`, `/settings`, …). If a token is configured on the desktop, it is
sent as the `X-Cast-Token` header.
