import SwiftUI
import AppKit
import VinylDeskCore

@main
struct VinylDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            TurntableView()
                .frame(width: 460, height: 360)
                .background(Color.clear)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        MenuBarExtra("VinylDesk", systemImage: "record.circle.fill") {
            Button("Toggle Play/Pause") {
                MusicCoordinator.shared.togglePlayPause()
            }
            Button("Next Track") {
                MusicCoordinator.shared.nextTrack()
            }
            Divider()
            Button("Reset Position") {
                MusicCoordinator.shared.seek(to: 0)
            }
            Divider()
            Button("Quit VinylDesk") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        // Make window draggable by background and styled nicely
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                if window.className.contains("SwiftUI") || window.title.isEmpty {
                    window.isMovableByWindowBackground = true
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.backgroundColor = .clear
                    window.isOpaque = false
                    window.hasShadow = true
                    window.center()
                }
            }
        }
    }
}
