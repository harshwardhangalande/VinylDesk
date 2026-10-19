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
    @ObservedObject var themeManager = SleeveThemeManager.shared
    var onSizeChanged: (CGSize) -> Void

    public init(onSizeChanged: @escaping (CGSize) -> Void) {
        self.onSizeChanged = onSizeChanged
    }

    public var body: some View {
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

// MARK: - Desktop Widget Panel Controller

@MainActor
public final class DesktopWidgetController {
    public static let shared = DesktopWidgetController()

    public private(set) var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    public enum SnapLocation: String, CaseIterable, Sendable {
        case bottomLeft = "Bottom-Left ↙"
        case bottomRight = "Bottom-Right ↘"
        case topLeft = "Top-Left ↖"
        case topRight = "Top-Right ↗"
        case center = "Center ⏺"
    }

    private init() {
        SleeveThemeManager.shared.$currentTheme
            .map(\.windowPlacement)
            .removeDuplicates()
            .sink { [weak self] placement in
                self?.updateWindowLevel(for: placement)
            }
            .store(in: &cancellables)
    }

    public func show() {
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
        let placement = SleeveThemeManager.shared.currentTheme.windowPlacement
        panel.level = (placement == .floating) ? .floating : .normal
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

    public func updateWindowLevel(for placement: WindowLevelPlacement) {
        guard let panel = self.window else { return }
        panel.level = (placement == .floating) ? .floating : .normal
    }

    public func updateSize(_ newSize: CGSize) {
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
