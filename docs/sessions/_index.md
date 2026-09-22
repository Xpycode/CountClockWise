# Session Index

| Date | Focus | Outcome |
|---|---|---|
| 2026-09-22 | Polish and rename Count Clock Wise | Tab accepted; 25 tests pass. Added appearance, shared Help/Feedback/tip, shortcuts, diagnostics and update preparation. Signed renamed app installed; identity preserved. Next: service-registration approval and external acceptance. |
| 2026-09-21 | Put Clock under version control | `git init` + `.gitignore`, root commit `3f84a45` with the full app + docs. No remote yet. |
| 2026-09-20 | Build fast macOS CEST clock app, then add resizable/closable window + Preferences | Working SwiftPM/AppKit app: fullscreen clock → titled/resizable window; added `Settings` (UserDefaults) + `PreferencesWindowController` covering Display, Time Zone, Appearance, Window (incl. always-on-top, remember frame, launch-at-login via SMAppService). Next: package as `.app` bundle. |
