# Session Index

| Date | Focus | Outcome |
|---|---|---|
| 2026-09-22 | Polish, rename and prepare Count Clock Wise for release | Public source and README gallery are live; website-registration branch is pushed; 25 tests pass. Next: notarization, Sparkle, website activation and external acceptance. |
| 2026-09-21 | Put Clock under version control | `git init` + `.gitignore`, root commit `3f84a45` with the full app + docs. No remote yet. |
| 2026-09-20 | Build fast macOS CEST clock app, then add resizable/closable window + Preferences | Working SwiftPM/AppKit app: fullscreen clock → titled/resizable window; added `Settings` (UserDefaults) + `PreferencesWindowController` covering Display, Time Zone, Appearance, Window (incl. always-on-top, remember frame, launch-at-login via SMAppService). Next: package as `.app` bundle. |
