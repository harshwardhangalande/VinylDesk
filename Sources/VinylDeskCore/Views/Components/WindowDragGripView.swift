import SwiftUI
import AppKit

// MARK: - Native Drag Handle NSView

public final class DragHandleNSView: NSView {
    public override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    public override func mouseDown(with event: NSEvent) {
        NSCursor.closedHand.push()
        window?.performDrag(with: event)
        NSCursor.pop()
    }
}

public struct NativeDragHandleRepresentable: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> DragHandleNSView {
        let view = DragHandleNSView()
        return view
    }

    public func updateNSView(_ nsView: DragHandleNSView, context: Context) {}
}

// MARK: - Window Drag Grip View

public struct WindowDragGripView: View {
    var isWidgetHovered: Bool = false
    @StateObject private var localHoverState = WidgetHoverState()

    public init(isWidgetHovered: Bool = false) {
        self.isWidgetHovered = isWidgetHovered
    }

    public var body: some View {
        ZStack {
            // Visual Glass Grip Dot (Visible whenever widget is hovered or grip is hovered)
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.60), lineWidth: 1)
                    )
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)

                // 4-Dot Grip Pattern
                VStack(spacing: 2.2) {
                    HStack(spacing: 2.2) {
                        Circle().fill(Color.white).frame(width: 2.2, height: 2.2)
                        Circle().fill(Color.white).frame(width: 2.2, height: 2.2)
                    }
                    HStack(spacing: 2.2) {
                        Circle().fill(Color.white).frame(width: 2.2, height: 2.2)
                        Circle().fill(Color.white).frame(width: 2.2, height: 2.2)
                    }
                }
            }
            .opacity((isWidgetHovered || localHoverState.isHovered) ? 1.0 : 0.0)

            // Native NSView with open-hand cursor & performDrag
            NativeDragHandleRepresentable()
                .frame(width: 26, height: 26)
        }
        .frame(width: 26, height: 26)
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                localHoverState.isHovered = hovering
            }
        }
        .help("Drag to reposition widget anywhere on your screen")
    }
}
