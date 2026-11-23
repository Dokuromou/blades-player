# Blades

A **local-first, 100% offline music player for Android**, styled like a modern phone UI wearing an Xbox 360 dashboard jacket: blade-cut cards, a snapping album carousel, radial playback visualizer, synthesised retro UI sounds, and three dark themes.

No accounts. No network permission. No analytics. Everything — playback, library scanning, lyrics, tags, playlists, equalizer, settings — happens on the device.

```
Kotlin · Jetpack Compose (Material 3) · Media3/ExoPlayer · Room · DataStore · jaudiotagger
minSdk 26 (Android 8.0) · targetSdk 35 · portrait-first · phone-only
```

---

## Table of contents

- [Why this stack](#why-this-stack)
- [Feature map](#feature-map)
- [Screens](#screens)
- [Themes](#themes)
- [Project structure](#project-structure)
- [Build & run](#build--run)
- [Verification status](#verification-status)
- [Permissions](#permissions)
- [How the tricky parts work](#how-the-tricky-parts-work)
- [Known limitations](#known-limitations)
- [License](#license)

---

## Why this stack

**Kotlin + Jetpack Compose, Android-only.** Chosen deliberately, not by default:

| Requirement | Why Android/Compose wins |
|---|---|
| Real local audio playback + background playback | Media3 `ExoPlayer` + `MediaSessionService` is the reference implementation: gapless playback, audio focus, headphone-unplug handling, media notification, lock-screen and Bluetooth transport controls — all for free. |
| Runtime audio permissions | Android has a first-class, well-specified model (`READ_MEDIA_AUDIO` on 13+, `READ_EXTERNAL_STORAGE` on 12-) with a real "permanently denied" state that must be handled. |
| Local file tag **writing** | Writing ID3/Vorbis/MP4/WAV tags requires raw file access and a mature tag library. jaudiotagger does exactly this on Android. On iOS, the sandbox forbids arbitrary file rewriting, so a true tag editor is not possible without escalating to a desktop helper. |
| Built-in equalizer | `android.media.audiofx.Equalizer` is a real system effect instance attached to the audio session — not a DSP approximation. |
| Audio visualizer | `android.media.audiofx.Visualizer` gives real FFT frames of the playing stream. |
| GitHub distribution | A single Gradle project builds an installable APK with `./gradlew assembleDebug`; GitHub Actions workflow included. |

A Flutter build would cover both platforms but would need native plugins for tag writing, the equalizer and the FFT tap anyway — more code, more caveats, and on iOS several of those features are simply unavailable. Given the brief's emphasis on *working* local audio, Android-native was the honest choice. Kotlin/Compose also keeps the UI code compact and declarative, which matters for the motion-heavy blade aesthetic.

---

## Feature map

### Library & playback
- [x] Recursive scan of local storage for **MP3, FLAC, WAV, M4A/AAC, OGG/Opus**
- [x] Two-source indexing: **MediaStore** (fast, correct) merged with a **direct folder sweep** (catches files MediaStore has not indexed yet), de-duplicated by path
- [x] Incremental rescans that preserve favourites and playlist membership
- [x] Play / pause / next / previous, seek bar with smooth interpolation
- [x] Shuffle, repeat off → all → one
- [x] Background playback via foreground `MediaSessionService`
- [x] Lock-screen, notification and Bluetooth media controls (Media3 MediaSession)
- [x] Queue restore after process death (queue, index and position persisted)
- [x] Pause on headphone unplug, audio-focus handling

### Albums as a game library
- [x] Snapping **blade carousel** (`HorizontalPager`) with depth-scaled neighbours and a focus rim
- [x] Live focus shelf showing title, artist, year, track count
- [x] "Recently added" shelf + two-up grid of every album
- [x] Deterministic generated cover art when a release has no embedded artwork (no bundled images, no network)

### Now Playing
- [x] **Circular/radial visualizer** driven by real FFT data (64 log-spaced bands, mirrored, with a low-frequency halo)
- [x] **Low-power fallback**: 12 fps amplitude ring
- [x] Automatic fallback to an idle pulse when the device exposes no visualizer
- [x] Capture only while Now Playing is visible (zero cost during background playback)
- [x] Swipe artwork left/right to skip, swipe down / tap to dismiss
- [x] Inline lyrics and queue panels, quick **UI Sounds on/off** toggle

### Lyrics
- [x] Sidecar `.lrc` with synced timing, plus conventional `Artist - Title.lrc` / `Title.lrc`
- [x] Embedded `LYRICS` tag, parsed as synced if it contains LRC timing
- [x] Multiple timestamps per line, `[offset:±ms]`, `.xx` and `.xxx` fractions
- [x] Active line highlighting with auto-scroll; tap a line to seek to it
- [x] Graceful empty state explaining how to add lyrics

### Equalizer
- [x] Real `android.media.audiofx.Equalizer` on the ExoPlayer audio session
- [x] Presets: **Flat, Bass Boost, Rock, Electronic, Vocal** + Custom
- [x] Presets are *shapes* mapped onto whatever band count the device reports (usually 5, sometimes 7+)
- [x] Hand-drawn vertical band sliders with dB readout and a response-curve preview
- [x] Gains and enabled state persisted; off by default

### Favorites & playlists
- [x] One-tap favourite toggle on every row, in the player and in album detail
- [x] Virtual "Liked tracks" playlist
- [x] Create, rename, delete playlists
- [x] Add tracks through a searchable library picker (de-duplicated)
- [x] Remove tracks; reorder with explicit up/down controls persisted as integer positions in one transaction

### Tag / metadata editor
- [x] Edits **Track #, Disc #, Title, Artist, Album, Album Artist, Genre, Year**
- [x] Writes into the real file (ID3v2 / Vorbis comments / MP4 `ilst` / WAV `INFO`), then re-indexes MediaStore and updates the Room row
- [x] Read-only files, missing files and unsupported containers surface a readable error instead of failing silently
- [x] Shows the target container format and warns that the file on disk is being modified

### Sleep timer
- [x] 15 / 30 / 45 / 60 minutes (default remembered), cancel and +5 min from the player
- [x] **8-second linear fade-out**, then pause, then restore the previous volume
- [x] Live countdown in the player and in settings; lives in the foreground service so it survives screen-off

### Themes & UI sounds
- [x] **Toxic** (Original Xbox acid green), **Neon** (cyan/blue), **Danger** (crimson) — all dark-first, switchable instantly from settings
- [x] Retro UI sounds: navigation tick, selection chime, back cue, confirm arpeggio, error buzz, blade swoosh
- [x] Toggle in settings **and** a quick toggle in the Now Playing header; volume slider; persisted
- [x] Sounds are **synthesised at runtime** as PCM — no bundled audio assets, no decoder, ~5–40 ms latency

---

## Screens

| Screen | What it does |
|---|---|
| **Albums** (start) | Blade carousel of featured albums, recently-added shelf, full grid |
| **Tracks** | Searchable list (title/artist/album/genre) with All / Liked / Recent filters |
| **Playlists** | Liked tracks + custom playlists, create/rename/delete |
| **Settings** | Theme, UI sounds, visualizer, equalizer entry, sleep timer, library stats & rescan |
| **Album detail** | Hero art, play/shuffle, numbered track list |
| **Playlist detail** | Add/remove/reorder tracks, play all / shuffle |
| **Now Playing** | Radial visualizer, transport, seek, lyrics panel, queue panel, sleep timer |
| **Tag editor** | All eight editable fields, saves to the file |
| **Equalizer** | Presets, per-band sliders, response curve |
| **Permission gate** | First-run explainer with denied / permanently-denied handling |

---

## Themes

All three are dark-dominant and defined as one token set (`BladesColors`), so no screen hard-codes a colour.

| Theme | Accent | Intent |
|---|---|---|
| **Toxic** | `#B6FF1A` acid green on near-black | Original Xbox / 360 acid palette |
| **Neon** | `#35E1FF` cyan → `#2B6BFF` blue | Dashboard cyan, cool and clean |
| **Danger** | `#FF2E45` crimson on oxblood | High-contrast red overdrive |

---

## Project structure

Feature-first, as requested:

```
app/src/main/java/app/blades/player/
├── MainActivity.kt              single activity, runtime permission plumbing
├── BladesApp.kt                 Application + app graph accessor
├── core/                        di graph, formatting helpers, settings (DataStore)
├── data/
│   ├── model/Track.kt           TrackEntity, Album, Artist, PlaylistSummary
│   └── db/                      Room entities, DAOs, database
├── library/                     MediaScanner, LibraryRepository, ArtworkLoader,
│                                LyricsRepository, LrcParser, AlbumGrouping
├── player/                      PlaybackService, PlayerController, SleepTimer,
│                                VisualizerTap, PlaybackSnapshot
├── tags/                        TagEditor (jaudiotagger read/write)
├── equalizer/                   PlayerEqualizer (audiofx) + presets
├── permissions/                 MediaPermissions (API-level rules)
├── events/                      UiEventBus
└── ui/
    ├── themes/                  BladesColors (3 palettes), Theme, typography
    ├── components/              blade shape, cards, headers, TrackRow, MiniPlayer
    ├── nav/                     routes, NavHost, bottom blade rail
    ├── screens/                 library, player, playlists, settings, tags, equalizer
    ├── visualizer/              RadialVisualizer (Canvas)
    └── sounds/                  UiSoundEngine (runtime PCM synthesis)
```

Pure logic lives in Android-free files (`LrcParser`, `AlbumGrouping`, `core/Format.kt`) so it is unit-testable on the JVM.

---

## Build & run

### Requirements
- Android Studio Ladybug (2024.2) or newer, **or** just a JDK 17 + Android SDK
- JDK 17
- Android SDK Platform 35 + Build-Tools 34
- A phone running Android 8.0 (API 26) or newer

### From Android Studio
1. **File → Open**, pick the repo root (the folder containing `settings.gradle.kts`).
2. Let Gradle sync (it will resolve Media3, Room, Compose, jaudiotagger from Maven).
3. Select a physical device (recommended — emulators often expose no equalizer or visualizer) and press **Run**.

### From the command line

```bash
# Debug APK → app/build/outputs/apk/debug/app-debug.apk
./gradlew assembleDebug

# Install straight to a connected phone
./gradlew installDebug

# JVM unit tests (LRC parser, album grouping, formatting)
./gradlew testDebugUnitTest

# Release APK (needs signing config, see below)
./gradlew assembleRelease
```

If the Android SDK is not found, create `local.properties`:

```properties
sdk.dir=/path/to/Android/Sdk
```

### Release signing

Create `keystore.properties` in the repo root (it is git-ignored):

```properties
storeFile=/absolute/path/to/release.jks
storePassword=…
keyAlias=…
keyPassword=…
```

Then add a `signingConfigs { create("release") { … } }` block to `app/build.gradle.kts` and reference it from `buildTypes.release`. Release builds run R8 with rules in `app/proguard-rules.pro` that keep jaudiotagger's reflective tag readers.

### CI

`.github/workflows/android.yml` runs unit tests and builds the debug APK on every push/PR, uploading it as a build artifact.

### Try it with music

Any of these will be picked up on the next scan (pull the refresh icon on **Albums**, or **Settings → Rescan storage**):

```bash
adb push ~/Music/album/ /sdcard/Music/album/
```

Then, to see synced lyrics, drop a sidecar next to a file:

```
/sdcard/Music/album/01 Track.mp3
/sdcard/Music/album/01 Track.lrc     ← [00:12.50]First line
```

---

## Verification status

Honest accounting of what was and was not verified in the sandbox this was built in:

| Check | Status |
|---|---|
| `./gradlew :app:compileDebugKotlin` | ✅ **Passes, 0 errors, 0 warnings** |
| `./gradlew :app:testDebugUnitTest` | ✅ **16/16 tests pass** (LRC parser incl. offsets/multi-stamp/ms precision, album grouping & ordering, formatters) |
| Room schema + DAO generation (KSP) | ✅ Generates `BladesDatabase_Impl`, `TrackDao_Impl`, `PlaylistDao_Impl`; DAO SQL validated at compile time |
| Manifest + resource merge (`aapt2`) | ✅ Passes |
| `assembleDebug` (packaging) | ⚠️ **Not run** — the sandbox had 2 GB RAM and one 1.5 GB JVM; Gradle's R8/D8 worker was OOM-killed during dexing. This is an environment limit, not a code error. Run `./gradlew assembleDebug` on a normal machine (4 GB+ free) to produce the APK. |
| On-device runtime behaviour | ⚠️ Not executed — no Android device/emulator available here. |
| `lint` / release R8 build | ⚠️ Not run (same memory limit). |

Two genuine defects were caught and fixed by these checks:
1. an LRC `[offset:±ms]` value was silently ignored (`return@forEach` inside a nested lambda only returned from the inner lambda);
2. the app's permission callback signature was updated to carry the *permanently denied* flag, which previously left the settings fallback unreachable.

---

## Permissions

| Permission | When | Behaviour if denied |
|---|---|---|
| `READ_MEDIA_AUDIO` (API 33+) / `READ_EXTERNAL_STORAGE` (≤ API 32) | First launch, on the permission gate | Gate stays up with an explanation; a second denial is detected as *permanently denied* and the gate sends the user to system settings, then re-checks on return. The app never crashes and never shows an empty "library" pretending to be ready. |
| `POST_NOTIFICATIONS` (API 33+) | Optional, from Settings or when playback starts | Playback still works; only the media notification is hidden. Requested separately because it is purely cosmetic. |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK` | Normal permissions | — |
| `FileProvider` (`${applicationId}.fileprovider`) | Declared in the manifest | Serves audio files as `content://` URIs so the media notification and lock screen can render local album art with no network round-trip. Scoped to read-only URI grants. |
| **`INTERNET`** | **Not declared** | The app literally cannot make a network request. |

---

## How the tricky parts work

**Indexing without duplicates.** `MediaScanner` merges a MediaStore query with a bounded `walkTopDown()` over Music/Downloads/Podcasts/Ringtones plus the app's external files dirs. Results are keyed by absolute path, so a file present in both sources appears once. `LibraryRepository.rescan()` then reconciles: existing rows keep their `id` and `isFavorite` flag, disappeared paths are deleted, new paths inserted. Playlist membership therefore survives rescans.

**Tag writing.** `TagEditor.write()` opens the file with jaudiotagger, sets/deletes each `FieldKey` (so clearing a field really removes the frame), commits, then nudges MediaStore and returns an updated `TrackEntity` that is written back to Room and to the live MediaItem. Failures are returned as data, not thrown.

**Equalizer on an arbitrary device.** Band count, min/max gain and centre frequencies are all read from the effect instance at runtime. Presets are described as a normalised curve (`EqPreset.curveFor`) that gets sampled onto however many bands exist, and the stored preset re-derives itself from the current gains, so a Custom curve is never mislabelled.

**Visualizer without draining the battery.** The service owns a single `VisualizerTap`; capture is `enabled` only while the Now Playing screen is composed and playing, and throttled to 12 fps in low-power mode. The UI never touches audio APIs directly — it reads `StateFlow`s. If construction fails (common on emulators), the renderer silently falls back to an idle pulse.

**Sleep timer with a graceful ending.** One `Handler` ticker in the service; inside the final 8 seconds the player volume ramps linearly to zero, then pauses, then restores the pre-fade volume so the next session is not silent.

**Retro UI sounds with no assets.** `UiSoundEngine` synthesises short PCM buffers (pitch-swept square-ish blips, two-note chords, noise sweeps through a moving one-pole low-pass), writes them to a `MODE_STATIC` `AudioTrack` built for `USAGE_ASSISTANCE_SONIFICATION`, and plays on a single worker coroutine. Clips respect the themed volume setting and cost ~0 ms of main-thread time.

**Album art on the lock screen.** Media3 renders notification artwork from the item's `artworkUri`. Since everything here is local, the service wraps each file in a `FileProvider` URI (read-only grant) instead of a remote image — artwork appears on the lock screen exactly like a streaming app, still with no network permission in the manifest.

**Playlists survive rescans.** Track inserts use Room's `@Upsert` rather than `@Insert(REPLACE)`: `REPLACE` is a delete-then-insert, which fires `ON DELETE CASCADE` on `playlist_tracks` and would empty every playlist on each scan. Deletions of vanished files are issued one path at a time to stay well under SQLite's bound-variable limit.

**Blade shape.** One `GenericShape` with a sliced top-right corner is reused for cards, buttons, artwork and dialogs — the single visual motif that makes the UI read as "360 dashboard" rather than generic dark Material.

---

## Known limitations

- **Android 11+ scoped storage**: writing tags works for files the app can open for write. Files inside another app's private directory, or on a read-only mounted SD card, will report a friendly error instead of saving. Full storage *write* access is intentionally not requested — the app edits only reachable library files.
- **Visualizer and equalizer depend on the device's audio effects stack.** Most physical phones expose both; several emulator images expose neither. Both screens degrade gracefully and say so.
- **DSD/APE/WMA** are not indexed (deliberately: no reliable decoder + tag writer combo).
- **Portrait only**, phone only — by design, per the brief. Tablets work but are not optimised.
- Album artwork is read per-file; very large libraries (10k+ tracks) will scroll fine but the first pass through the grid is I/O bound.

---

## License

MIT — see [LICENSE](LICENSE).
