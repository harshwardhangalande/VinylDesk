import SwiftUI
import AppKit
import VinylDeskCore

@main
struct VinylDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = SleeveThemeManager.shared
    @StateObject private var coordinator = MusicCoordinator.shared

    var body: some Scene {
        // Desktop Floating Accessory Window
        Window("Sleeve", id: "sleeve-widget") {
            SleeveWidgetView(coordinator: coordinator, theme: themeManager.currentTheme)
                .background(Color.clear)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)

        // Menu Bar Extra with quick controls & theme presets
        MenuBarExtra {
            // Track Info Header
            Text("\(coordinator.currentTrack.title) - \(coordinator.currentTrack.artist)")
                .font(.headline)

            Divider()

            // Playback Controls
            Button(coordinator.currentTrack.isPlaying ? "Pause" : "Play") {
                coordinator.togglePlayPause()
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("Next Track") {
                coordinator.nextTrack()
            }

            Button("Previous Track") {
                coordinator.previousTrack()
            }

            Divider()

            // Theme Preset Switcher
            Menu("Themes") {
                ForEach(themeManager.presets) { preset in
                    Button(action: {
                        themeManager.selectPreset(preset)
                    }) {
                        HStack {
                            if themeManager.currentTheme.name == preset.name {
                                Text("✓ \(preset.name)")
                            } else {
                                Text(preset.name)
                            }
                        }
                    }
                }
            }

            // Music Source Selector
            Menu("Source: \(coordinator.currentTrack.source.rawValue)") {
                Button("Spotify") {
                    coordinator.isDemoModeForced = false
                    coordinator.refreshTrack()
                }
                Button("Apple Music") {
                    coordinator.isDemoModeForced = false
                    coordinator.refreshTrack()
                }
                Button("Demo Player") {
                    coordinator.isDemoModeForced = true
                    coordinator.currentTrack = TrackInfo.demoTrack
                }
            }

            Divider()

            Button("Preferences...") {
                PreferencesWindowController.shared.show()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Sleeve") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "record.circle.fill")
        }
    }
}

// MARK: - App Delegate & Window Management

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.configureWidgetWindow()
        }
    }

    func configureWidgetWindow() {
        for window in NSApp.windows {
            if window.title == "Sleeve" || window.className.contains("SwiftUI") {
                window.isMovableByWindowBackground = true
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = false
                window.level = .floating

                // Position in bottom-left or center
                if let screen = NSScreen.main {
                    let frame = screen.visibleFrame
                    window.setFrameOrigin(CGPoint(x: frame.minX + 40, y: frame.minY + 40))
                }
            }
        }
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
