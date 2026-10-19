import SwiftUI
import AppKit
import VinylDeskCore

@main
struct VinylDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SleevePreferencesView(
                themeManager: SleeveThemeManager.shared,
                coordinator: MusicCoordinator.shared
            )
        }
    }
}

// MARK: - Widget Size Preference Key

struct WidgetSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

// MARK: - Widget Wrapper View

struct DesktopWidgetWrapperView: View {
    @ObservedObject var coordinator = MusicCoordinator.shared
    @ObservedObject var themeManager = SleeveThemeManager.shared
    var onSizeChanged: (CGSize) -> Void

    var body: some View {
        SleeveWidgetView(coordinator: coordinator, theme: themeManager.currentTheme)
            .fixedSize()
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: WidgetSizeKey.self, value: geo.size)
                }
            )
            .onPreferenceChange(WidgetSizeKey.self) { size in
                if size.width > 20 && size.height > 20 {
                    onSizeChanged(size)
                }
            }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.async {
            DesktopWidgetController.shared.show()
            StatusItemManager.shared.setup()
        }
    }
}

// MARK: - Desktop Widget Panel Controller

@MainActor
final class DesktopWidgetController {
    static let shared = DesktopWidgetController()

    private(set) var window: NSPanel?

    func show() {
        if let existing = window {
            existing.orderFront(nil)
            return
        }

        let initialRect = NSRect(x: 100, y: 100, width: 280, height: 160)
        let panel = NSPanel(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let wrapper = DesktopWidgetWrapperView { [weak self] newSize in
            self?.updateSize(newSize)
        }

        let hostingView = NSHostingView(rootView: wrapper)
        panel.contentView = hostingView

        // Position on desktop (bottom-left area with padding)
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = CGPoint(x: visible.minX + 60, y: visible.minY + 60)
            panel.setFrameOrigin(origin)
        }

        panel.orderFront(nil)
        self.window = panel
    }

    func updateSize(_ newSize: CGSize) {
        guard let panel = self.window else { return }
        let currentFrame = panel.frame
        let targetW = ceil(newSize.width)
        let targetH = ceil(newSize.height)

        if abs(currentFrame.width - targetW) > 1 || abs(currentFrame.height - targetH) > 1 {
            // Anchor to current bottom-left position so it expands smoothly without covering folders
            let newFrame = NSRect(
                x: currentFrame.minX,
                y: currentFrame.minY,
                width: targetW,
                height: targetH
            )
            panel.setFrame(newFrame, display: true, animate: false)
        }
    }

    public enum SnapLocation: String, CaseIterable, Sendable {
        case bottomLeft = "Bottom-Left ↙"
        case bottomRight = "Bottom-Right ↘"
        case topLeft = "Top-Left ↖"
        case topRight = "Top-Right ↗"
        case center = "Center ⏺"
    }

    func snap(to location: SnapLocation) {
        guard let panel = self.window, let screen = panel.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let w = panel.frame.width
        let h = panel.frame.height
        let margin: CGFloat = 40

        var newOrigin: CGPoint
        switch location {
        case .bottomLeft:
            newOrigin = CGPoint(x: visible.minX + margin, y: visible.minY + margin)
        case .bottomRight:
            newOrigin = CGPoint(x: visible.maxX - w - margin, y: visible.minY + margin)
        case .topLeft:
            newOrigin = CGPoint(x: visible.minX + margin, y: visible.maxY - h - margin)
        case .topRight:
            newOrigin = CGPoint(x: visible.maxX - w - margin, y: visible.maxY - h - margin)
        case .center:
            newOrigin = CGPoint(x: visible.midX - w / 2, y: visible.midY - h / 2)
        }

        panel.setFrameOrigin(newOrigin)
    }
}

// MARK: - Native Status Bar Item Manager

@MainActor
final class StatusItemManager: NSObject, NSMenuDelegate {
    static let shared = StatusItemManager()

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    func setup() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "Sleeve")
        }
        menu.delegate = self
        statusItem?.menu = menu
        refreshMenu()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refreshMenu()
    }

    func refreshMenu() {
        menu.removeAllItems()

        let coordinator = MusicCoordinator.shared
        let themeManager = SleeveThemeManager.shared

        // Header: Track title and artist
        let trackTitle = coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title
        let trackArtist = coordinator.currentTrack.artist.isEmpty ? "" : " - \(coordinator.currentTrack.artist)"
        let headerItem = NSMenuItem(title: "\(trackTitle)\(trackArtist)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Play/Pause
        let playTitle = coordinator.currentTrack.isPlaying ? "Pause" : "Play"
        let playItem = NSMenuItem(title: playTitle, action: #selector(togglePlayPause), keyEquivalent: " ")
        playItem.target = self
        menu.addItem(playItem)

        // Next
        let nextItem = NSMenuItem(title: "Next Track", action: #selector(nextTrack), keyEquivalent: "")
        nextItem.target = self
        menu.addItem(nextItem)

        // Previous
        let prevItem = NSMenuItem(title: "Previous Track", action: #selector(prevTrack), keyEquivalent: "")
        prevItem.target = self
        menu.addItem(prevItem)

        menu.addItem(NSMenuItem.separator())

        // Themes Submenu
        let themesMenu = NSMenu(title: "Themes")
        for preset in themeManager.presets {
            let item = NSMenuItem(title: preset.name, action: #selector(selectThemePreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset
            if themeManager.currentTheme.name == preset.name {
                item.state = .on
            }
            themesMenu.addItem(item)
        }
        let themesParentItem = NSMenuItem(title: "Themes", action: nil, keyEquivalent: "")
        themesParentItem.submenu = themesMenu
        menu.addItem(themesParentItem)

        // Source Submenu
        let sourceMenu = NSMenu(title: "Source")
        for src in MusicSource.allCases {
            let item = NSMenuItem(title: src.rawValue, action: #selector(selectMusicSource(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = src
            if coordinator.currentTrack.source == src {
                item.state = .on
            }
            sourceMenu.addItem(item)
        }
        let sourceParentItem = NSMenuItem(title: "Source: \(coordinator.currentTrack.source.rawValue)", action: nil, keyEquivalent: "")
        sourceParentItem.submenu = sourceMenu
        menu.addItem(sourceParentItem)

        // Position Submenu
        let posMenu = NSMenu(title: "Position")
        for loc in DesktopWidgetController.SnapLocation.allCases {
            let item = NSMenuItem(title: loc.rawValue, action: #selector(snapToPosition(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = loc
            posMenu.addItem(item)
        }
        let posParentItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        posParentItem.submenu = posMenu
        menu.addItem(posParentItem)

        // Liquid Glass Submenu
        let glassMenu = NSMenu(title: "Liquid Glass")
        for level in LiquidGlassLevel.allCases {
            let item = NSMenuItem(title: level.displayName, action: #selector(selectLiquidGlassLevel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = level
            if themeManager.currentTheme.liquidGlassLevel == level && (themeManager.currentTheme.backdropMaterial == .liquidGlass || themeManager.currentTheme.backdropMaterial == .glass) {
                item.state = .on
            }
            glassMenu.addItem(item)
        }
        glassMenu.addItem(NSMenuItem.separator())

        let pulseItem = NSMenuItem(title: "Fluid Breathing Pulse", action: #selector(toggleLiquidGlassPulse), keyEquivalent: "")
        pulseItem.target = self
        if themeManager.currentTheme.liquidGlassFluidPulse {
            pulseItem.state = .on
        }
        glassMenu.addItem(pulseItem)

        glassMenu.addItem(NSMenuItem.separator())
        let tintHeader = NSMenuItem(title: "Tint Mode:", action: nil, keyEquivalent: "")
        tintHeader.isEnabled = false
        glassMenu.addItem(tintHeader)

        for tint in LiquidGlassTint.allCases {
            let item = NSMenuItem(title: "  " + tint.rawValue, action: #selector(selectLiquidGlassTint(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tint
            if themeManager.currentTheme.liquidGlassTint == tint {
                item.state = .on
            }
            glassMenu.addItem(item)
        }

        let glassParentItem = NSMenuItem(title: "💧 Liquid Glass", action: nil, keyEquivalent: "")
        glassParentItem.submenu = glassMenu
        menu.addItem(glassParentItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences...
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Sleeve", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func togglePlayPause() {
        MusicCoordinator.shared.togglePlayPause()
    }

    @objc private func nextTrack() {
        MusicCoordinator.shared.nextTrack()
    }

    @objc private func prevTrack() {
        MusicCoordinator.shared.previousTrack()
    }

    @objc private func selectThemePreset(_ sender: NSMenuItem) {
        if let preset = sender.representedObject as? SleeveThemeConfig {
            SleeveThemeManager.shared.selectPreset(preset)
        }
    }

    @objc private func selectMusicSource(_ sender: NSMenuItem) {
        if let src = sender.representedObject as? MusicSource {
            switch src {
            case .spotify:
                MusicCoordinator.shared.isDemoModeForced = false
                MusicCoordinator.shared.refreshTrack()
            case .appleMusic:
                MusicCoordinator.shared.isDemoModeForced = false
                MusicCoordinator.shared.refreshTrack()
            case .demo:
                MusicCoordinator.shared.isDemoModeForced = true
                MusicCoordinator.shared.currentTrack = TrackInfo.demoTrack
            }
        }
    }

    @objc private func snapToPosition(_ sender: NSMenuItem) {
        if let loc = sender.representedObject as? DesktopWidgetController.SnapLocation {
            DesktopWidgetController.shared.snap(to: loc)
        }
    }

    @objc private func selectLiquidGlassLevel(_ sender: NSMenuItem) {
        if let level = sender.representedObject as? LiquidGlassLevel {
            SleeveThemeManager.shared.currentTheme.backdropMaterial = .liquidGlass
            SleeveThemeManager.shared.currentTheme.liquidGlassLevel = level
            SleeveThemeManager.shared.currentTheme.liquidGlassCustomOpacity = 0
            SleeveThemeManager.shared.currentTheme.liquidGlassCustomBlur = 0
            SleeveThemeManager.shared.currentTheme.liquidGlassRimShine = 0
            SleeveThemeManager.shared.saveCurrentTheme()
        }
    }

    @objc private func toggleLiquidGlassPulse() {
        SleeveThemeManager.shared.currentTheme.liquidGlassFluidPulse.toggle()
        SleeveThemeManager.shared.saveCurrentTheme()
    }

    @objc private func selectLiquidGlassTint(_ sender: NSMenuItem) {
        if let tint = sender.representedObject as? LiquidGlassTint {
            SleeveThemeManager.shared.currentTheme.liquidGlassTint = tint
            SleeveThemeManager.shared.saveCurrentTheme()
        }
    }

    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Preferences Window Controller

@MainActor
final class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = SleevePreferencesView(
            themeManager: SleeveThemeManager.shared,
            coordinator: MusicCoordinator.shared
        )

        let hostingController = NSHostingController(rootView: preferencesView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.center()
        newWindow.title = "Sleeve Preferences"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = newWindow
    }
}
