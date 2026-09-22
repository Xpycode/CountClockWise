#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
clock_bin_dir="$(swift build -c release --show-bin-path)"
clock_app="$PWD/build/Clock.app"
mkdir -p "$clock_app/Contents/MacOS" "$clock_app/Contents/Resources"
cp "$clock_bin_dir/Clock" "$clock_app/Contents/MacOS/Clock"
cp -R "$clock_bin_dir/Clock_Clock.bundle" "$clock_app/Contents/Resources/"
swift scripts/make-icon.swift "$PWD/build/Clock.iconset"
iconutil -c icns "$PWD/build/Clock.iconset" -o "$clock_app/Contents/Resources/Clock.icns"
cat > "$clock_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.lucesumbrarum.Clock</string>
<key>CFBundleName</key><string>Clock</string>
<key>CFBundleDisplayName</key><string>Clock</string>
<key>CFBundleExecutable</key><string>Clock</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>Clock</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Luces Umbrarum. All rights reserved.</string>
</dict></plist>
PLIST
cp THIRD_PARTY_NOTICES.md "$clock_app/Contents/Resources/"
# Prefer this team's installed Developer ID; permit ad-hoc local builds on other machines.
clock_identity="${CLOCK_SIGNING_IDENTITY:-}"
if [ -z "$clock_identity" ]; then
    clock_identity="$(security find-identity -v -p codesigning | awk '/Developer ID Application/ && /FDMSRXXN73/ {print $2; exit}')"
fi
codesign --force --sign "${clock_identity:--}" --options runtime "$clock_app"
codesign --verify --deep --strict "$clock_app"
plutil -lint "$clock_app/Contents/Info.plist"
printf '%s\n' "$clock_app"
