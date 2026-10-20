import SwiftUI
import AppKit
import VinylDeskCore

@main
struct VinylDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            VinylPreferencesView(
                themeManager: VinylThemeManager.shared,
                coordinator: MusicCoordinator.shared
            )
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
            button.image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "VinylDesk")
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
        let themeManager = VinylThemeManager.shared

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

        // User Themes (My Themes)
        if !themeManager.userThemes.isEmpty {
            let myThemesHeader = NSMenuItem(title: "My Themes", action: nil, keyEquivalent: "")
            myThemesHeader.isEnabled = false
            themesMenu.addItem(myThemesHeader)

            for userTheme in themeManager.userThemes {
                let item = NSMenuItem(title: "  " + userTheme.name, action: #selector(selectThemePreset(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = userTheme
                if themeManager.currentTheme.id == userTheme.id {
                    item.state = .on
                }
                themesMenu.addItem(item)
            }
            themesMenu.addItem(NSMenuItem.separator())

            let presetsHeader = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
            presetsHeader.isEnabled = false
            themesMenu.addItem(presetsHeader)
        }

        for preset in themeManager.presets {
            let titlePrefix = themeManager.userThemes.isEmpty ? "" : "  "
            let item = NSMenuItem(title: titlePrefix + preset.name, action: #selector(selectThemePreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset
            if themeManager.currentTheme.id == preset.id {
                item.state = .on
            }
            themesMenu.addItem(item)
        }
        let themesParentItem = NSMenuItem(title: "Themes", action: nil, keyEquivalent: "")
        themesParentItem.submenu = themesMenu
        menu.addItem(themesParentItem)

        // Source Submenu
        let sourceMenu = NSMenu(title: "Source")

        let autoItem = NSMenuItem(title: "Auto (Active Player)", action: #selector(selectAutoSource), keyEquivalent: "")
        autoItem.target = self
        if coordinator.preferredSource == nil {
            autoItem.state = .on
        }
        sourceMenu.addItem(autoItem)
        sourceMenu.addItem(NSMenuItem.separator())

        for src in MusicSource.allCases where src != .none {
            let item = NSMenuItem(title: src.rawValue, action: #selector(selectMusicSource(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = src
            if coordinator.preferredSource == src || (coordinator.preferredSource == nil && coordinator.currentTrack.source == src) {
                item.state = .on
            }
            sourceMenu.addItem(item)
        }
        let currentTitle = coordinator.preferredSource != nil ? "\(coordinator.preferredSource!.rawValue)" : (coordinator.currentTrack.source != .none ? coordinator.currentTrack.source.rawValue : "Auto")
        let sourceParentItem = NSMenuItem(title: "Source: \(currentTitle)", action: nil, keyEquivalent: "")
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

        menu.addItem(NSMenuItem.separator())

        // Visibility Submenu
        let visMenu = NSMenu(title: "Visibility")
        for vis in WidgetVisibility.allCases {
            let item = NSMenuItem(title: vis.rawValue, action: #selector(selectWidgetVisibility(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = vis
            if themeManager.currentTheme.visibility == vis {
                item.state = .on
            }
            visMenu.addItem(item)
        }
        let visParentItem = NSMenuItem(title: "Visibility: \(themeManager.currentTheme.visibility.rawValue)", action: nil, keyEquivalent: "")
        visParentItem.submenu = visMenu
        menu.addItem(visParentItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences...
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit VinylDesk", action: #selector(quitApp), keyEquivalent: "q")
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
        if let preset = sender.representedObject as? VinylThemeConfig {
            VinylThemeManager.shared.selectPreset(preset)
        }
    }

    @objc private func selectAutoSource() {
        MusicCoordinator.shared.preferredSource = nil
        MusicCoordinator.shared.refreshTrack()
    }

    @objc private func selectMusicSource(_ sender: NSMenuItem) {
        if let src = sender.representedObject as? MusicSource {
            MusicCoordinator.shared.preferredSource = src
            MusicCoordinator.shared.refreshTrack()
        }
    }

    @objc private func snapToPosition(_ sender: NSMenuItem) {
        if let loc = sender.representedObject as? DesktopWidgetController.SnapLocation {
            DesktopWidgetController.shared.snap(to: loc)
        }
    }

    @objc private func selectWidgetVisibility(_ sender: NSMenuItem) {
        if let vis = sender.representedObject as? WidgetVisibility {
            VinylThemeManager.shared.currentTheme.visibility = vis
            VinylThemeManager.shared.currentTheme.windowPlacement = (vis == .desktopOnly) ? .desktop : .floating
            VinylThemeManager.shared.saveCurrentTheme()
        }
    }

    @objc private func toggleFloatingOverlay() {
        VinylThemeManager.shared.currentTheme.isFloatingOverlayVisible.toggle()
        VinylThemeManager.shared.saveCurrentTheme()
    }

    @objc private func selectExperienceMode(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? ExperienceMode {
            VinylThemeManager.shared.currentTheme.experienceMode = mode
            VinylThemeManager.shared.saveCurrentTheme()
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

        let preferencesView = VinylPreferencesView(
            themeManager: VinylThemeManager.shared,
            coordinator: MusicCoordinator.shared
        )

        let hostingController = NSHostingController(rootView: preferencesView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.center()
        newWindow.title = "VinylDesk Preferences"
        newWindow.minSize = NSSize(width: 560, height: 600)
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = newWindow
    }
}
