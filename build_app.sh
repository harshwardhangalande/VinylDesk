#!/bin/bash
set -e

echo "🔨 Building VinylDesk & VinylDeskWidgets..."
swift build -c release --product VinylDesk
swift build -c release --product VinylDeskWidgets

BUILD_DIR=".build/release"
APP_BUNDLE="VinylDesk.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
PLUGINS="$CONTENTS/PlugIns"
WIDGET_APPEX="$PLUGINS/VinylDeskWidgets.appex"
WIDGET_CONTENTS="$WIDGET_APPEX/Contents"
WIDGET_MACOS="$WIDGET_CONTENTS/MacOS"
WIDGET_RESOURCES="$WIDGET_CONTENTS/Resources"

echo "📦 Packaging $APP_BUNDLE with Dual Mode Native Widget Extension..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"
mkdir -p "$WIDGET_MACOS"
mkdir -p "$WIDGET_RESOURCES"

# Copy main binary
cp "$BUILD_DIR/VinylDesk" "$MACOS/VinylDesk"

# Copy WidgetKit extension binary
cp "$BUILD_DIR/VinylDeskWidgets" "$WIDGET_MACOS/VinylDeskWidgets"

# Main App Info.plist
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
    <string>VinylDesk connects to Spotify and Apple Music to display current track metadata and artwork on your desktop.</string>
</dict>
</plist>
EOF

# WidgetKit Extension Info.plist
cat <<EOF > "$WIDGET_CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VinylDeskWidgets</string>
    <key>CFBundleIdentifier</key>
    <string>com.vinyldesk.app.widgets</string>
    <key>CFBundleName</key>
    <string>VinylDeskWidgets</string>
    <key>CFBundleDisplayName</key>
    <string>VinylDesk</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
EOF

# Ad-hoc sign app bundle and plugin
echo "🔏 Signing application bundle and WidgetKit extension..."
codesign --force --deep -s - "$APP_BUNDLE"

# Register plugin with macOS pluginkit
pluginkit -a "$WIDGET_APPEX" 2>/dev/null || true

echo "✅ Successfully built Dual-Mode $APP_BUNDLE!"
echo "👉 Launch with: open $APP_BUNDLE"
