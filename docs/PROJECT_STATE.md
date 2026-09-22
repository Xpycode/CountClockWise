# PROJECT_STATE

Last updated: 2026-09-22

## Now
- **Phase:** shipping
<!-- Phase changed: 2026-09-22 -->
- **Focus:** Finish public README media and release handoff for Count Clock Wise; bundle identity and existing preferences remain preserved.
- **Execution:** [Implementation plan](../IMPLEMENTATION_PLAN.md) S1–S6 verified and merged; notarization, Sparkle activation, website activation and external acceptance remain open.
- **Next:** Add the user's README screenshots; then rotate the flagged notarization API key, configure the signed Sparkle feed, activate the prepared website roster entry and complete release acceptance.

## Readiness
| Area | Status |
|---|---|
| Features | Independent persistent windows, labels/day offsets, timer modes, integer/fractional/DF timecode, favourites and offline city search |
| UI | AppKit settings, stable standard/Controls menus, context menu, status item, global shortcut, borderless/opacity/Spaces controls |
| Testing | 25 automated tests pass, including diagnostics, shortcuts, help/support identity and updater configuration; signed bundle verification |
| Distribution | Public source repository and signed local 1.0 (1002) build; Apple silicon, macOS 14+; no notarized downloadable release yet |

## Recent
- 2026-09-22 — Added the real app icon to the public README; screenshot capture is reserved for the user and remains the only incomplete README-media step.
- 2026-09-22 — Published the tested source repository publicly; prepared and pushed an inactive App-Websites registration branch; confirmed notarization, Sparkle and external acceptance gates remain.
- 2026-09-22 — Renamed to Count Clock Wise with data identity preserved; added System/Light/Dark, shared Help/Feedback/tip integration, configurable shortcut, bounded logs and inactive-until-configured Sparkle updates.
- 2026-09-22 — User passed Tab resizing with Remember Window Frame enabled. Saved the working app and acceptance records in a local Git checkpoint; login and notification delivery remain unverified.
- 2026-09-22 — Refined Tab after user feedback: controls wrap around the current clock area. Fixed autosave restoring the stale full-window size on leaving compact mode; reproduced with Remember Window Frame enabled. All 13 tests pass, including repeated toggles and restoring the updated frame in a new controller.

## Notes
- Build: `scripts/build-app.sh`; test: `swift test`. Source remains a Swift package, without an Xcode project.
- Frame timecode is a local display, not LTC/MTC synchronization.
- Login launch is implemented through SMAppService; next-login behavior needs a real login check. Notification delivery depends on user permission.
- Public source: `https://github.com/Xpycode/CountClockWise`; `main` is the accepted working state.
