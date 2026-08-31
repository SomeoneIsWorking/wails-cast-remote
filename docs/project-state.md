# Project state

## Comparison baseline

The baseline is returning to the Wails Cast desktop for every library, track-selection, subtitle, and
transport action. WailsCast Remote intends the same authenticated workflow from Android and iOS,
including discovery, pre-play choices, live controls, subtitle translation, and synchronized settings.

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
| S007 | The client discovers desktop hosts over mDNS and also accepts manual host, port, and token entry | partial | S001 | G001 |
| S008 | The remote library can be browsed and refreshed, and arbitrary media URLs can be submitted | partial | S001 | G001 |
| S009 | Users choose the output device, video track, audio track, subtitle track, and quality before play | partial | S002 | G001 |
| S010 | Now Playing shows live position and supports play, pause, stop, skip, scrubber seek, volume, and mute | partial | S003 | G001 |
| S011 | Subtitle translation status, retranslation, selection, burn-in, and language preferences are available | partial | S003 | G001 |
| S012 | The last authenticated desktop connection persists across app restarts | partial | S001 | G001 |

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

### S007 — Host discovery and manual connection

mDNS discovery and manual host, port, and token entry are implemented. Gap: discovery, reconnect,
authentication refusal, and host-version behavior need a real-device protocol gate.

### S008 — Library browsing and URL submission

The client implements library browsing, refresh, and arbitrary URL submission. Gap: large-library,
empty, error, and reconnect states remain unverified.

### S009 — Pre-play selection

The UI exposes output device, video, audio, subtitle, and quality choices. Gap: adapter and media-source
combinations remain unqualified end to end.

### S010 — Now Playing controls

The client polls live state and exposes play, pause, stop, skip, scrubber seek, volume, and mute. Gap:
acknowledgement, stale-state, and disconnect behavior need real-host verification.

### S011 — Subtitle translation and preferences

Translation, retranslation, progress, selection, burn-in, quality, and language settings are exposed.
Gap: completion and settings round-trip are unverified on a shipping phone/host pair.

### S012 — Persisted connection

The last host, port, and token selection persists across app starts. Gap: secure persistence, invalid
credentials, and reconnect behavior lack a release-device gate.
