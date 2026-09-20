# PROJECT_STATE

Last updated: 2026-09-21

## Now
- **Phase:** implementation
- **Focus:** Clock — a minimal macOS Swift Package (AppKit) showing the current time, no Xcode project.
- **Next:** package as a real `.app` bundle (needed for a dock icon + working "Launch at login").

## Readiness
| Area | Status |
|---|---|
| Features | 🔶 core clock + preferences working |
| UI | 🔶 functional AppKit UI, no custom app icon |
| Testing | ⬜ manual only, no automated tests |
| Docs | 🔶 this file only |
| Distribution | ⬜ runs via `swift run` / `.build/release/Clock`, not bundled as `.app` |

## Recent
- 2026-09-21 — Initialized git repo, root commit `3f84a45` with the full app + docs.
- 2026-09-20 — Built Preferences window (Display, Time Zone, Appearance, Window tabs) backed by UserDefaults, applied live via NotificationCenter.
- 2026-09-20 — Converted fullscreen borderless window to a normal titled, resizable, closable window.
- 2026-09-20 — Initial app: fullscreen borderless clock hardcoded to Europe/Berlin (CEST).

## Notes
- Git repo initialized 2026-09-21, `main` branch, no remote yet — commits are local-only until a GitHub remote is added.
- Built and run via Swift Package Manager (`swift build -c release`, `./.build/release/Clock`), not an Xcode project.
