# VinylDesk

A beautifully crafted desktop music companion & vintage vinyl widget for macOS Sonoma (14.0+) that syncs seamlessly with Apple Music and Spotify.

---

## 🚀 Download & Installation

### Option 1: Direct Download (Pre-built App)
1. Download the latest `VinylDesk-macOS.zip` from [**GitHub Releases**](https://github.com/harshwardhangalande/VinylDesk/releases).
2. Unzip `VinylDesk-macOS.zip`.
3. Move `VinylDesk.app` to your `/Applications` folder.
4. Open the app and grant Accessibility / Automation permissions for Apple Music & Spotify when prompted.

> **Note for macOS Gatekeeper**: Since the app is ad-hoc signed, if macOS blocks it on first launch, right-click `VinylDesk.app` and choose **Open**, or go to **System Settings → Privacy & Security** and click **Open Anyway**.

---

## ✨ Features

- **Vintage Vinyl & Modern Widget Layouts**:
  - Retro Vinyl turntable with live spinning record
  - Time Dashboard with dynamic live clock
  - Split Card with album art and typography
  - Split Banner, Compact Square, Squircle Card, and Artwork Poster
- **Dual Mode Experience**:
  - Interactive desktop overlay widget (with click-through and drag anywhere support)
  - Native macOS Notification Center & Desktop WidgetKit extension
- **Liquid Glass Materials & Dynamic Lighting**:
  - Ultra, High, Medium, Low, and Clear glass styling
  - Dynamic album art color extraction & blur tints
- **Full Playback Controls**:
  - Previous, Play/Pause, Next controls
  - Interactive scrubbable progress bar
- **Customizable Typography & Appearance**:
  - Custom font designs (Sans, Serif, Rounded, Monospace)
  - Configurable corner radius, materials, and display modes

---

## 🛠 Building from Source

### Prerequisites
- macOS Sonoma 14.0 or newer
- Swift 5.9+ / Xcode Command Line Tools
- Python 3 with `pillow` (for application icon rendering)

### Build & Package
```bash
git clone https://github.com/harshwardhangalande/VinylDesk.git
cd VinylDesk
./build_app.sh
open VinylDesk.app
```

---

## 📄 License
MIT License
