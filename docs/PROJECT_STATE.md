# PROJECT_STATE

Last updated: 2026-09-22

## Now
- **Phase:** polish
- **Focus:** Native macOS Clock.app with independent clock windows, searchable world clocks, countdown/stopwatch, fractional timecode and desktop controls.
- **Execution:** [Implementation plan](../IMPLEMENTATION_PLAN.md) implemented and locally verified; awaiting acceptance tracked in [TASKS](../TASKS.md).
- **Next:** Tab resizing is user-accepted. Finish broader acceptance, verify Launch at Login through an actual login, and confirm countdown notifications. Run `/check ship` before public release.

## Readiness
| Area | Status |
|---|---|
| Features | Independent persistent windows, labels/day offsets, timer modes, integer/fractional/DF timecode, favourites and offline city search |
| UI | AppKit settings, stable standard/Controls menus, context menu, status item, global shortcut, borderless/opacity/Spaces controls |
| Testing | Thirteen automated tests covering timecode, timers, settings isolation, window controls/menu validation, resized Tab-mode frame restoration with autosaving enabled/disabled and city search; signed bundle verification |
| Distribution | Signed local Clock.app in Applications; no public release or notarization |

## Recent
- 2026-09-22 — User passed Tab resizing with Remember Window Frame enabled. Saved the working app and acceptance records in a local Git checkpoint; login and notification delivery remain unverified.
- 2026-09-22 — Refined Tab after user feedback: controls wrap around the current clock area. Fixed autosave restoring the stale full-window size on leaving compact mode; reproduced with Remember Window Frame enabled. All 13 tests pass, including repeated toggles and restoring the updated frame in a new controller.
- 2026-09-22 — Added Tab clock-only mode with frame/toolbar restoration and immediate countdown validation; all 11 tests passed and the fresh installed app was relaunched.
- 2026-09-22 — Refined native toolbar, standard action/status bar and attached duration sheet; added full-string sizing regression coverage for mode switching.
- 2026-09-22 — Added direct mode tabs and timer buttons/click-to-pause; replaced the scaling footer with a full-width fixed-size, toggleable status line.

## Notes
- Build: `scripts/build-app.sh`; test: `swift test`. Source remains a Swift package, without an Xcode project.
- Frame timecode is a local display, not LTC/MTC synchronization.
- Login launch is implemented through SMAppService; next-login behavior needs a real login check. Notification delivery depends on user permission.
- Git has no configured remote; the accepted working state is saved locally.
