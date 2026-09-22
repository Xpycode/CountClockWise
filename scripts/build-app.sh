#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --arch arm64
clock_bin_dir="$(swift build -c release --arch arm64 --show-bin-path)"
clock_version="$(plutil -extract Version raw Release.plist)"
clock_build="$(plutil -extract Build raw Release.plist)"
if ! [[ "$clock_build" =~ ^[1-9][0-9]*$ ]]; then
    echo "Release.plist Build must be a positive integer." >&2
    exit 1
fi
if [ -n "${CLOCK_FEED_URL:-}" ] || [ -n "${CLOCK_UPDATE_PUBLIC_KEY:-}" ]; then
    if [[ "${CLOCK_FEED_URL:-}" != https://* ]] || [ -z "${CLOCK_UPDATE_PUBLIC_KEY:-}" ]; then
        echo "Supply both an HTTPS CLOCK_FEED_URL and CLOCK_UPDATE_PUBLIC_KEY." >&2
        exit 1
    fi
fi
clock_app="$PWD/build/Count Clock Wise.app"
mkdir -p "$clock_app/Contents/MacOS" "$clock_app/Contents/Resources" "$clock_app/Contents/Frameworks"
cp "$clock_bin_dir/Clock" "$clock_app/Contents/MacOS/Clock"
for clock_resource in "$clock_bin_dir"/*.bundle; do
    [ -d "$clock_resource" ] || continue
    ditto "$clock_resource" "$clock_app/Contents/Resources/$(basename "$clock_resource")"
done
clock_sparkle="$PWD/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
ditto "$clock_sparkle" "$clock_app/Contents/Frameworks/Sparkle.framework"
swift scripts/make-icon.swift "$PWD/build/Clock.iconset"
iconutil -c icns "$PWD/build/Clock.iconset" -o "$clock_app/Contents/Resources/Clock.icns"
cat > "$clock_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.lucesumbrarum.Clock</string>
<key>CFBundleName</key><string>Count Clock Wise</string>
<key>CFBundleDisplayName</key><string>Count Clock Wise</string>
<key>CFBundleExecutable</key><string>Clock</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>Clock</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Luces Umbrarum. All rights reserved.</string>
</dict></plist>
PLIST
plutil -replace CFBundleShortVersionString -string "$clock_version" "$clock_app/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$clock_build" "$clock_app/Contents/Info.plist"
if [ -n "${CLOCK_FEED_URL:-}" ]; then
    plutil -insert SUFeedURL -string "$CLOCK_FEED_URL" "$clock_app/Contents/Info.plist"
    plutil -insert SUPublicEDKey -string "$CLOCK_UPDATE_PUBLIC_KEY" "$clock_app/Contents/Info.plist"
    plutil -insert SUEnableAutomaticChecks -bool YES "$clock_app/Contents/Info.plist"
    plutil -insert SUAutomaticallyUpdate -bool NO "$clock_app/Contents/Info.plist"
fi
cp THIRD_PARTY_NOTICES.md "$clock_app/Contents/Resources/"
cp .build/artifacts/sparkle/Sparkle/LICENSE "$clock_app/Contents/Resources/Sparkle-LICENSE"
# Prefer this team's installed Developer ID; permit ad-hoc local builds on other machines.
clock_identity="${CLOCK_SIGNING_IDENTITY:-}"
if [ -z "$clock_identity" ]; then
    clock_identity="$(security find-identity -v -p codesigning | awk '/Developer ID Application/ && /FDMSRXXN73/ {print $2; exit}')"
fi
clock_framework="$clock_app/Contents/Frameworks/Sparkle.framework/Versions/B"
for clock_component in "$clock_framework/XPCServices/Downloader.xpc" "$clock_framework/XPCServices/Installer.xpc" "$clock_framework/Autoupdate" "$clock_framework/Updater.app" "$clock_app/Contents/Frameworks/Sparkle.framework"; do
    codesign --force --sign "${clock_identity:--}" --options runtime --preserve-metadata=entitlements "$clock_component"
done
codesign --force --sign "${clock_identity:--}" --options runtime "$clock_app"
codesign --verify --deep --strict "$clock_app"
plutil -lint "$clock_app/Contents/Info.plist"
printf '%s\n' "$clock_app"
