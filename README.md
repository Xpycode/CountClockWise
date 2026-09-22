# Count Clock Wise

A native macOS desktop clock with independent, resizable windows. This build supports Apple silicon Macs running macOS 14 or later. Intel and macOS 13 are not supported by this release configuration.

## Use

- **File → New Clock** creates another clock. Each window remembers its own time zone, label, display and window settings.
- **Tab** shows or hides the controls around the clock’s current size and position. Resizing in either view carries through to the other, subject to minimum window sizes. It hides all window chrome without changing the saved controls/status preferences. Tab remains normal field navigation in Settings and sheets.
- The native toolbar’s **Clock / Countdown / Stopwatch** selector switches modes directly. Timer buttons start/pause/reset; click the displayed time to start or pause. **Set Duration…** opens a window-attached Hours / Minutes / Seconds sheet. Space starts/pauses the active timer.
- **Controls** or **right-click** switches between Clock, Countdown and Stopwatch; starts/pauses/resets a timer; sets a countdown; and changes display options.
- **Show Status Bar** toggles the fixed-size date/time-zone/FPS line. **Show Controls** toggles the toolbar and timer buttons; both are in Settings → Display and right-click.
- **Settings… (⌘,)** edits the active clock. Search cities, countries, regions and abbreviations in Time Zone; favourite commonly used zones. City names outside the IANA identifiers are included through offline GeoNames data.
- **Appearance → Match System / Light / Dark** changes the app-wide interface appearance. Per-clock background/text colors remain in Settings → Appearance.
- **Help → Count Clock Wise Help** opens searchable bundled help (Command-?). **Send Feedback…** opens the shared feedback form; **Leave a Tip** opens the optional tip page. **Email Support…** provides a mail-composer fallback. No message or payment is sent automatically.
- **Settings → Window** controls opacity, borderless mode, Always on Top, all Spaces and Launch at Login. Borderless clocks can be dragged anywhere; right-click → Borderless restores the title bar.
- **Control–Option–Command–C** shows/hides all clocks by default. Record, clear or reset this shortcut in Settings → Window. A conflicting replacement is rejected while retaining the previous shortcut. The menu-bar icon offers the same action.
- Closing the last window leaves the app available in the menu bar. Quit with **⌘Q**. Open windows and running timers are restored when the app relaunches; switching timer modes pauses the previous mode.
- Countdown duration accepts seconds, MM:SS or HH:MM:SS, up to seven days. Completion turns the display red, plays a sound and requests attention. System notifications require permission, requested when starting a countdown.

## Timecode

Rates: 23.976, 24, 25, 29.97 NDF/DF, 30, 50, 59.94 NDF/DF and 60 FPS. Fractional rates use exact rational values (24000/1001, 30000/1001 and 60000/1001).

Clock-mode timecode is anchored at local midnight; timers use elapsed or remaining duration. Fractional non-drop-frame timecode intentionally differs from civil time. Drop-frame skips labels (not rendered video frames) at minute boundaries except each tenth minute; a semicolon identifies DF. Timecode uses 24-hour formatting. The display follows the Mac's clock and scheduling; it is **not an LTC/MTC source or a video synchronization device**. System clock corrections and daylight-saving changes affect wall-clock mode.

## Build and test

```sh
swift test
scripts/build-app.sh
open "build/Count Clock Wise.app"
```

The build script creates the app icon, resource bundles and embedded Sparkle framework, then signs and verifies `build/Count Clock Wise.app`. It prefers the installed Luces Umbrarum Developer ID certificate; set `CLOCK_SIGNING_IDENTITY` to override it. This does not notarize or publish the app. Dependencies are pinned in `Package.resolved`; shared Help/Feedback/citizenship sources are vendored with provenance under `Vendor/`.

`Release.plist` owns the marketing version and build number (currently 1.0 / 1002). Increment Build for every distributable build; never reuse or decrease it across published releases. Build the final artifact after the final source change.

Sparkle integration uses `CLOCK_FEED_URL` (HTTPS) and `CLOCK_UPDATE_PUBLIC_KEY` (base64 Ed25519 public key) at build time. Until both are configured, Check for Updates explains that the local build has no update channel and automatic checks remain off. Publishing a signed appcast and verifying an actual old-to-new update remain release gates. Never embed the private signing key.

Count Clock Wise's `count-clock-wise` slug still needs registration in the live shared `apps.json` roster for web feedback and a personalized tip page. The app-side feedback form is implemented; live submission remains unverified. Do not send test submissions without authorization.

Diagnostic logs rotate between two 128 KiB files in `~/Library/Application Support/Clock`. Help → Show Diagnostic Log reveals them. Events exclude clock labels, selected cities, timer values and raw error descriptions; optional feedback attachment requires explicit opt-in.

Keep the app in a stable location (normally `/Applications/Count Clock Wise.app`) before enabling Launch at Login. macOS may require approval in System Settings → General → Login Items. Actual launch at the next login is a separate manual check.

Existing standalone Clock preferences are migrated on first bundled launch. Additional clock windows use separate preferences. Clocks and city search work offline; update checks and explicitly submitted feedback use the network.

## Data credits

City data: [GeoNames](https://www.geonames.org/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); over 34,000 records downloaded 2026-09-22. Country/time-zone mapping: IANA public-domain data. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The public app name is Count Clock Wise. The Swift target/executable `Clock`, bundle ID `com.lucesumbrarum.Clock`, preference domains, frame keys and diagnostic directory remain unchanged to preserve existing installations.
