#!/bin/bash
set -e

echo "🔨 Building VinylDesk..."
swift build -c release --product VinylDesk

BUILD_DIR=".build/release"
APP_BUNDLE="VinylDesk.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "📦 Packaging $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

cp "$BUILD_DIR/VinylDesk" "$MACOS/VinylDesk"

cat <<EOF > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VinylDesk</string>
    <key>CFBundleIdentifier</key>
    <string>com.vinyldesk.app</string>
    <key>CFBundleName</key>
    <string>VinylDesk</string>
    <key>CFBundleDisplayName</key>
    <string>VinylDesk</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>VinylDesk connects to Spotify and Apple Music to display current track metadata and artwork on the vintage turntable.</string>
</dict>
</plist>
EOF

echo "✅ Successfully built $APP_BUNDLE!"
echo "👉 Launch with: open $APP_BUNDLE"
