import AppKit

@MainActor
public final class DockIconManager {
    public static let shared = DockIconManager()
    private var defaultIcon: NSImage?

    private init() {
        if let img = NSApp?.applicationIconImage {
            self.defaultIcon = img
        } else if let bundleIcon = NSImage(named: NSImage.applicationIconName) {
            self.defaultIcon = bundleIcon
        }
    }

    public func updateDockIcon(artworkData: Data?, isEnabled: Bool) {
        guard isEnabled, let data = artworkData, let sourceImage = NSImage(data: data) else {
            NSApp?.applicationIconImage = defaultIcon ?? NSImage(named: NSImage.applicationIconName)
            return
        }

        // Render continuous rounded squircle dock tile with album artwork
        let iconSize = NSSize(width: 512, height: 512)
        let dockImage = NSImage(size: iconSize)
        dockImage.lockFocus()

        let rect = NSRect(origin: .zero, size: iconSize)
        let squirclePath = NSBezierPath(roundedRect: rect, xRadius: 115, yRadius: 115)
        squirclePath.addClip()
        sourceImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        // Glossy vinyl glass sheen across top corner
        let gradient = NSGradient(colors: [NSColor.white.withAlphaComponent(0.28), NSColor.clear])
        gradient?.draw(from: NSPoint(x: 0, y: 512), to: NSPoint(x: 256, y: 256), options: [])

        dockImage.unlockFocus()
        NSApp?.applicationIconImage = dockImage
    }
}
