# Clock desktop utility implementation

Authorized scope: all improvements proposed and accepted on 2026-09-22.

- [x] Independent persistent clock windows, labels and date differences.
- [x] Borderless mode, opacity, global show/hide shortcut and complete menus.
- [x] Favourite zones and offline city search with attribution.
- [x] Countdown and stopwatch with start/pause/reset and completion feedback.
- [x] Rational fractional frame rates and tested drop-frame numbering.
- [x] Signed local app bundle, icon, login-item integration and settings migration.
- [x] Automated checks, app verification, documentation and fresh launch.

No publishing or notarization requested. Preserve the existing clock settings.

Accepted on 2026-09-22: Tab compact/full resizing preserves the current clock area, including with Remember Window Frame enabled.

Acceptance remaining: broader user review of the expanded app, real login launch, and notification delivery after user permission. Public release/notarization remain out of scope.

## Shipping should-fix batch — authorized 2026-09-22

Goal: complete the shipping-audit should-fixes, explicitly including Appearance, Help, Send Feedback and Leave a Tip. Preserve accepted Tab geometry and existing clock preferences. Notarization, publication, live feedback submissions and real logout/login are not authorized by this batch.

### Wave 1 — independent foundations
- [x] **S1 Logging and notification feedback.** Owns `DiagnosticLogger.swift`, `ClockNotifications.swift`, and new notification/logger tests. Interface: existing notification calls preserved; bounded diagnostic log and recent-tail API. No dependencies. Validate isolated logger tests, error handling and full build. Real notification permission/delivery remains external.
- [x] **S2 Editable visibility shortcut.** Owns `GlobalShortcut.swift`, `ShortcutPreferencesView.swift`, and new shortcut tests. Interface: existing `init(action:)` and `register()` preserved; native preferences view; persisted key and modifiers, clear/reset, conflict feedback. No dependencies. Validate registration/state tests and full build; coordinator wires preferences/menu.
- [x] **S3 Shared Help/citizenship and update preparation.** Coordinator owns Package.swift, vendor packages, help resources, support/update adapters, release scripts/docs. Shared components require macOS 14, approved by the user. Update delivery requires a real HTTPS appcast and signing configuration; no placeholder success claims. Validate dependency resolution, signed bundle packaging and local configuration/error paths.

### Wave 2 — serial integration (depends on S1/S2/S3)
- [x] **S4 Appearance and menus/preferences.** Coordinator owns `main.swift`, `Settings.swift`, `PreferencesWindowController.swift`, `ClockView.swift`, appearance adapter/tests. App-wide System/Light/Dark, preserve per-clock colors; native menu/preferences wiring for Help, Send Feedback, Leave a Tip, editable shortcut, updates and diagnostic access. Validate build/tests and actual app controls. User approved System/Light/Dark.
- [x] **S5 Release preparation.** Coordinator owns version/build metadata, changelog, support policy and acceptance notes. Make build numbering explicit and increasing; declare architecture/minimum OS honestly. Validate bundled metadata, signatures and resource availability.

### Wave 3 — verification and handoff (depends on S4/S5)
- [x] **S6 Integration verification.** Coordinator is sole writer of shared build/test output and Git. Run Swift tests, signed release build, gracefully install/relaunch fresh artifact and inspect actual UI. Commit validated scoped work. Required external checks remain unchecked.

### External checks
- **E1:** Resolved: user approved macOS 14 and shared component integration.
- **E2:** Feedback app registration, tip destination, published signed appcast and real updater round trip gate respective live-service acceptance. Inspect available configuration first; do not publish or send messages without authorization.
- **E3:** Actual login, notification permission/delivery, minimum-OS and clean-Mac testing gate release acceptance, not independent implementation.

### Execution log
- 2026-09-22: Started should-fix batch from clean `main` checkpoint. S1/S2 delegated with exclusive file ownership; coordinator handles S3 and integration. UI controls follow existing native AppKit settings/menu patterns. No new passing evidence yet.
- 2026-09-22: S1/S2 implemented by logging_notifications/editable_shortcut agents and cross-reviewed; coordinator integrated S3–S6. User approved macOS 14 and System/Light/Dark. All 25 tests pass; native menus/preferences, Help and feedback form inspected without submitting. Signed production bundle built and installed. Shared Help emits one upstream deprecation warning. Live feedback registration and update feed remain unconfigured; E2/E3 keep the overall plan open.
- 2026-09-22: User confirmed Count Clock Wise rename. Serial coordinator change updates bundle/display/menu/Help/preferences/support names and prepared `count-clock-wise` service slug. Retained executable, bundle ID, settings domains and frame keys. Version 1.0 (1002) built/signed; 25 tests pass and added Help/support-name assertions pass. Website registration remains undeployed pending approval. Installed app renamed in place and fresh artifact launched.
- 2026-09-22: Public README media is complete. The real 1024×1024 app icon and four selected user-supplied captures show the clock, countdown, offline city search and window/global-shortcut settings. All assets retain transparency and dimensions, all README targets resolve, and the public GitHub copies were verified. No synthetic or agent-captured screenshot was used.
