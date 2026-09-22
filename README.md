# Clock

A native macOS desktop clock with independent, resizable windows. Requires macOS 13 or later.

## Use

- **File → New Clock** creates another clock. Each window remembers its own time zone, label, display and window settings.
- **Tab** shows or hides the controls around the clock’s current size and position. Resizing in either view carries through to the other, subject to minimum window sizes. It hides all window chrome without changing the saved controls/status preferences. Tab remains normal field navigation in Settings and sheets.
- The native toolbar’s **Clock / Countdown / Stopwatch** selector switches modes directly. Timer buttons start/pause/reset; click the displayed time to start or pause. **Set Duration…** opens a window-attached Hours / Minutes / Seconds sheet. Space starts/pauses the active timer.
- **Controls** or **right-click** switches between Clock, Countdown and Stopwatch; starts/pauses/resets a timer; sets a countdown; and changes display options.
- **Show Status Bar** toggles the fixed-size date/time-zone/FPS line. **Show Controls** toggles the toolbar and timer buttons; both are in Settings → Display and right-click.
- **Settings… (⌘,)** edits the active clock. Search cities, countries, regions and abbreviations in Time Zone; favourite commonly used zones. City names outside the IANA identifiers are included through offline GeoNames data.
- **Settings → Window** controls opacity, borderless mode, Always on Top, all Spaces and Launch at Login. Borderless clocks can be dragged anywhere; right-click → Borderless restores the title bar.
- **Control–Option–Command–C** shows/hides all clocks. The menu-bar icon offers the same action. A shortcut collision is reported rather than silently ignored.
- Closing the last window leaves the app available in the menu bar. Quit with **⌘Q**. Open windows and running timers are restored when the app relaunches; switching timer modes pauses the previous mode.
- Countdown duration accepts seconds, MM:SS or HH:MM:SS, up to seven days. Completion turns the display red, plays a sound and requests attention. System notifications require permission, requested when starting a countdown.

## Timecode

Rates: 23.976, 24, 25, 29.97 NDF/DF, 30, 50, 59.94 NDF/DF and 60 FPS. Fractional rates use exact rational values (24000/1001, 30000/1001 and 60000/1001).

Clock-mode timecode is anchored at local midnight; timers use elapsed or remaining duration. Fractional non-drop-frame timecode intentionally differs from civil time. Drop-frame skips labels (not rendered video frames) at minute boundaries except each tenth minute; a semicolon identifies DF. Timecode uses 24-hour formatting. The display follows the Mac's clock and scheduling; it is **not an LTC/MTC source or a video synchronization device**. System clock corrections and daylight-saving changes affect wall-clock mode.

## Build and test

```sh
swift test
scripts/build-app.sh
open build/Clock.app
```

The build script creates the app icon and resource bundle, then signs and verifies `build/Clock.app`. It prefers the installed Luces Umbrarum Developer ID certificate; set `CLOCK_SIGNING_IDENTITY` to override it. It falls back to an ad-hoc local signature if the certificate is unavailable. This does not notarize or publish the app.

Keep the app in a stable location (normally `/Applications/Clock.app`) before enabling Launch at Login. macOS may require approval in System Settings → General → Login Items. Actual launch at the next login is a separate manual check.

Existing standalone Clock preferences are migrated on first bundled launch. Additional clock windows use separate preferences. The app has no network dependency at runtime.

## Data credits

City data: [GeoNames](https://www.geonames.org/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); over 34,000 records downloaded 2026-09-22. Country/time-zone mapping: IANA public-domain data. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
