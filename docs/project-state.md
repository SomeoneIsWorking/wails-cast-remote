# Project state

## Current focus

S005 is the current focus.

## Capability inventory

| ID | Capability or outcome | State | Factual dependency | Goals |
| --- | --- | --- | --- | --- |
| S001 | The app discovers Wails Cast hosts over mDNS and supports manual authenticated connection | partial | — | G001 |
| S002 | Users browse the remote library, refresh it, and submit arbitrary media URLs | partial | S001 | G001 |
| S003 | Users select output device, video, audio, subtitle, and quality before playback | partial | S001, S002 | G001 |
| S004 | Now Playing provides live position, play, pause, stop, seek, volume, and mute controls | partial | S003 | G001 |
| S005 | Subtitle translation, status, retranslation, and synced playback preferences work end to end | partial | S003 | G001 |
| S006 | Android and iOS releases are qualified against the shipping desktop API | missing | S001, S002, S003, S004, S005 | G001 |

## Capability details

### S001 — Host connection

The Flutter client implements `_wailscast._tcp` discovery, manual host/port/token entry, and persistence
of the last connection.

Gap: discovery, reconnect, auth refusal, and host-version behavior lack a real-device protocol gate.

### S002 — Library and URL playback

The client implements library browsing, refresh, and arbitrary URL submission against the desktop API.

Gap: large-library, empty, error, and reconnect states are not durably verified.

### S003 — Playback selection

The UI exposes Chromecast/local targets and video, audio, subtitle, and quality choices.

Gap: adapter and media-source combinations remain unqualified end to end.

### S004 — Live transport controls

The app polls Now Playing state and exposes play, pause, stop, skip, scrubber seek, volume, and mute.

Gap: control acknowledgement, stale-state, and disconnect behavior need real-host verification.

### S005 — Subtitles and preferences

The app exposes translation, retranslation, progress, subtitle selection, burn-in, quality, and language
settings synchronized with the desktop.

Gap: translation completion and settings round-trip are not verified on a shipping phone/host pair.

### S006 — Qualified mobile releases

Missing capability: no recorded Android/iOS release matrix proves installation and the complete companion
workflow against a named Wails Cast desktop release.
