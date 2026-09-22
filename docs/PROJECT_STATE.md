# PROJECT_STATE

Last updated: 2026-09-22

## Now
- **Phase:** polish
- **Focus:** Count Clock Wise, the renamed native macOS clock utility; existing bundle identity and preferences preserved.
- **Execution:** [Implementation plan](../IMPLEMENTATION_PLAN.md) S1–S6 locally implemented/verified; external service activation and acceptance remain open.
- **Next:** Decide whether to deploy the prepared `count-clock-wise` feedback registration; finish user, login and notification acceptance. Updates need a signed release feed. Run `/check ship` before public release.

## Readiness
| Area | Status |
|---|---|
| Features | Independent persistent windows, labels/day offsets, timer modes, integer/fractional/DF timecode, favourites and offline city search |
| UI | AppKit settings, stable standard/Controls menus, context menu, status item, global shortcut, borderless/opacity/Spaces controls |
| Testing | 25 automated tests pass, including diagnostics, shortcuts, help/support identity and updater configuration; signed bundle verification |
| Distribution | Signed local Count Clock Wise.app 1.0 (1002) in Applications; Apple silicon, macOS 14+; no public release or notarization |

## Recent
- 2026-09-22 — Renamed to Count Clock Wise with data identity preserved; added System/Light/Dark, shared Help/Feedback/tip integration, configurable shortcut, bounded logs and inactive-until-configured Sparkle updates.
- 2026-09-22 — User passed Tab resizing with Remember Window Frame enabled. Saved the working app and acceptance records in a local Git checkpoint; login and notification delivery remain unverified.
- 2026-09-22 — Refined Tab after user feedback: controls wrap around the current clock area. Fixed autosave restoring the stale full-window size on leaving compact mode; reproduced with Remember Window Frame enabled. All 13 tests pass, including repeated toggles and restoring the updated frame in a new controller.
- 2026-09-22 — Added Tab clock-only mode with frame/toolbar restoration and immediate countdown validation; all 11 tests passed and the fresh installed app was relaunched.
- 2026-09-22 — Refined native toolbar, standard action/status bar and attached duration sheet; added full-string sizing regression coverage for mode switching.

## Notes
- Build: `scripts/build-app.sh`; test: `swift test`. Source remains a Swift package, without an Xcode project.
- Frame timecode is a local display, not LTC/MTC synchronization.
- Login launch is implemented through SMAppService; next-login behavior needs a real login check. Notification delivery depends on user permission.
- Git has no configured remote; the accepted working state is saved locally.
