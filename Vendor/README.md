# Shared component snapshots

Copied on 2026-09-22 from the user's shared packages. Sources are unchanged; package manifests retain only the libraries used by Clock and pin their external dependency.

- HelpMenu: `1-macOS/appHELP/01_Project/Sources/HelpMenu` (local source snapshot; no Git revision available).
- AppCitizenshipKit: `zPackages/AppCitizenshipKit`, revision `a6c06af92e2d813429e5aa878e858018b8af27eb`.
- FeedbackKit: `zPackages/FeedbackKit`, revision `8a240f1da8ce2281bb8522fa78d5273955387553`.

Vendoring makes Clock buildable without machine-specific package paths. These shared components require macOS 14; the user approved raising Clock's minimum accordingly. Refresh deliberately from their owners rather than editing a shared package outside this repository.
