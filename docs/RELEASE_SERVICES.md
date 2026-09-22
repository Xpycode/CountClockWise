# Release service activation — prepared, not deployed

## Feedback and tip personalization

The shared public roster at `https://apps.lucesumbrarum.com/apps.json` does not yet contain Count Clock Wise (read-only check, 2026-09-22). `feedback-submit.php` validates the app field against this roster, so the native form's `app=count-clock-wise` submissions cannot be accepted until registration is deployed. Do not send test submissions as part of an automated build.

Proposed minimal entry in the existing `apps` array:

```json
{
  "slug": "count-clock-wise",
  "name": "Count Clock Wise",
  "category": "UtilitiesApplication",
  "portalPage": false,
  "titleExample": "e.g. 'Countdown notification did not appear'"
}
```

No `site`, release date, download, catalogue part number or public product page is proposed. The current portal code filters its catalogue to `portalPage` or `site`, so this entry enables feedback selection and tip personalization without advertising a download. Review the current website checkout and live state before applying; do not overwrite a roster changed since this check.

Target owned website source: `3-Websites/App-Websites/APPS/apps.lucesumbrarum.com/public/apps.json`. Deployment is separate from this app-only execution. Until activated, Email Support opens a draft in the user's mail app; the generic Leave a Tip destination is already reachable (HTTP 200).

## Signed automatic updates

Sparkle 2.10.0 is embedded and signed. App-side integration is complete, but the channel is deliberately inactive until a real feed and key are configured. Check for Updates explains this status; the automatic-check checkbox is disabled.

Before activation:

1. Choose the final Count Clock Wise release URL. The approved public name is Count Clock Wise and prepared service slug is `count-clock-wise`; bundle identity remains `com.lucesumbrarum.Clock` to preserve user data.
2. Create/use an app-specific Sparkle Ed25519 key in Keychain. Only its public key goes into the built app.
3. Set `CLOCK_FEED_URL` to the published HTTPS appcast and `CLOCK_UPDATE_PUBLIC_KEY` to the public key when running `scripts/build-app.sh`.
4. Increment `Release.plist` Build for each distributed artifact, sign and notarize the final app, and generate signed release metadata using Sparkle's tools.
5. Publish the appcast and archive, then verify a real older-to-newer update with that artifact. Do not claim a fixture or missing-channel check proves delivery.

See the [official Sparkle setup instructions](https://sparkle-project.org/documentation/).

## Remaining acceptance

- macOS 14 / clean-user installation (the development Mac runs macOS 27.2).
- Actual Launch at Login with the installed app enabled.
- Notification permission, successful delivery and denied-permission feedback.
- User review of Appearance, Help, Feedback, tip handoff and custom shortcut use.
- Public-release Gatekeeper acceptance after notarization/stapling.
