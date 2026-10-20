import SwiftUI
import AppKit
import Combine

// MARK: - Widget Size Preference Key

public struct WidgetSizeKey: PreferenceKey {
    public static var defaultValue: CGSize = .zero
    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

// MARK: - Widget Wrapper View

public struct DesktopWidgetWrapperView: View {
    @ObservedObject var coordinator = MusicCoordinator.shared
    @ObservedObject var themeManager = VinylThemeManager.shared
    var onSizeChanged: (CGSize) -> Void

    public init(onSizeChanged: @escaping (CGSize) -> Void) {
        self.onSizeChanged = onSizeChanged
    }

    public var body: some View {
        VinylWidgetView(coordinator: coordinator, theme: themeManager.currentTheme)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { _ in
                        DesktopWidgetController.shared.handleDragChanged()
                    }
                    .onEnded { _ in
                        DesktopWidgetController.shared.handleDragEnded()
                    }
            )
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

// MARK: - Desktop Widget Panel Controller

@MainActor
public final class DesktopWidgetController {
    public static let shared = DesktopWidgetController()

    public private(set) var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()
    private var dragStartMouseLocation: CGPoint? = nil
    private var dragStartWindowOrigin: CGPoint? = nil

    public func handleDragChanged() {
        guard let panel = self.window else { return }
        let currentMouse = NSEvent.mouseLocation
        if dragStartMouseLocation == nil {
            dragStartMouseLocation = currentMouse
            dragStartWindowOrigin = panel.frame.origin
        }
        guard let startMouse = dragStartMouseLocation,
              let startOrigin = dragStartWindowOrigin else { return }
        let dx = currentMouse.x - startMouse.x
        let dy = currentMouse.y - startMouse.y
        panel.setFrameOrigin(CGPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
    }

    public func handleDragEnded() {
        if let panel = self.window {
            UserDefaults.standard.set(panel.frame.origin.x, forKey: "VinylDesk.WidgetOrigin.X")
            UserDefaults.standard.set(panel.frame.origin.y, forKey: "VinylDesk.WidgetOrigin.Y")
        }
        dragStartMouseLocation = nil
        dragStartWindowOrigin = nil
    }

    public enum SnapLocation: String, CaseIterable, Sendable {
        case bottomLeft = "Bottom-Left ↙"
        case bottomRight = "Bottom-Right ↘"
        case topLeft = "Top-Left ↖"
        case topRight = "Top-Right ↗"
        case center = "Center ⏺"
    }

    private init() {
        VinylThemeManager.shared.$currentTheme
            .map { ($0.visibility, $0.windowPlacement) }
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] visibility, placement in
                self?.applyVisibility(visibility, fallbackPlacement: placement)
            }
            .store(in: &cancellables)
    }

    public func applyVisibility(_ visibility: WidgetVisibility, fallbackPlacement: WindowLevelPlacement? = nil) {
        guard let panel = self.window else { return }
        let isEverywhere = (visibility == .showEverywhere) || (fallbackPlacement == .floating)
        if isEverywhere {
            // Show everywhere: floating above all application windows
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            // Show only on desktop: rests directly on desktop wallpaper beneath normal app windows
            panel.level = NSWindow.Level(rawValue: -1)
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        }
        // Always keep panel ordered front in the window hierarchy (never hidden)
        panel.orderFront(nil)
    }

    public func updateVisibility(mode: ExperienceMode, isVisible: Bool) {
        guard let panel = self.window else { return }
        if !isVisible {
            panel.orderOut(nil)
        } else {
            applyVisibility(VinylThemeManager.shared.currentTheme.visibility)
        }
    }

    public func show() {
        if window != nil {
            let theme = VinylThemeManager.shared.currentTheme
            applyVisibility(theme.visibility, fallbackPlacement: theme.windowPlacement)
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
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.alphaValue = 1.0

        let wrapper = DesktopWidgetWrapperView { [weak self] newSize in
            self?.updateSize(newSize)
        }

        let hostingView = NSHostingView(rootView: wrapper)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        // Position on desktop (saved origin if visible on screen, or bottom-left default)
        var initialOrigin: CGPoint? = nil
        if let savedX = UserDefaults.standard.object(forKey: "VinylDesk.WidgetOrigin.X") as? CGFloat,
           let savedY = UserDefaults.standard.object(forKey: "VinylDesk.WidgetOrigin.Y") as? CGFloat {
            let candidate = CGPoint(x: savedX, y: savedY)
            let isVisible = NSScreen.screens.contains { screen in
                screen.frame.contains(candidate)
            }
            if isVisible {
                initialOrigin = candidate
            }
        }

        if let origin = initialOrigin {
            panel.setFrameOrigin(origin)
        } else if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = CGPoint(x: visible.minX + 60, y: visible.minY + 60)
            panel.setFrameOrigin(origin)
        }

        self.window = panel

        let theme = VinylThemeManager.shared.currentTheme
        applyVisibility(theme.visibility, fallbackPlacement: theme.windowPlacement)
    }

    public func updateWindowLevel(for placement: WindowLevelPlacement) {
        let vis: WidgetVisibility = (placement == .floating) ? .showEverywhere : .desktopOnly
        applyVisibility(vis, fallbackPlacement: placement)
    }

    public func updateSize(_ newSize: CGSize) {
        guard let panel = self.window else { return }
        let currentFrame = panel.frame
        let targetW = ceil(newSize.width)
        let targetH = ceil(newSize.height)

        if abs(currentFrame.width - targetW) > 1 || abs(currentFrame.height - targetH) > 1 {
            var newX = currentFrame.minX
            var newY = currentFrame.minY

            if let screen = panel.screen ?? NSScreen.main {
                let visible = screen.visibleFrame
                // Ensure right edge doesn't go off screen
                if newX + targetW > visible.maxX {
                    newX = max(visible.minX, visible.maxX - targetW)
                }
                // Ensure left edge doesn't go off screen
                if newX < visible.minX {
                    newX = visible.minX
                }
                // Ensure top edge doesn't go off screen
                if newY + targetH > visible.maxY {
                    newY = max(visible.minY, visible.maxY - targetH)
                }
                // Ensure bottom edge doesn't go off screen
                if newY < visible.minY {
                    newY = visible.minY
                }
            }

            let newFrame = NSRect(
                x: newX,
                y: newY,
                width: targetW,
                height: targetH
            )
            panel.setFrame(newFrame, display: true, animate: false)
        }
    }

    public func snap(to location: SnapLocation) {
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
