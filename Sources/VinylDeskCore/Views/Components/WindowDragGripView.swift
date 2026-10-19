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
    @StateObject private var hoverState = WidgetHoverState()

    public init() {}

    public var body: some View {
        ZStack {
            // Background Glass Grip Dot
            Circle()
                .fill(
                    hoverState.isHovered
                        ? Color.white.opacity(0.28)
                        : Color.white.opacity(0.12)
                )
                .overlay(
                    Circle()
                        .stroke(
                            hoverState.isHovered
                                ? Color.white.opacity(0.50)
                                : Color.white.opacity(0.20),
                            lineWidth: 1
                        )
                )
                .frame(width: 18, height: 18)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

            // 4-Dot Grip Pattern
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Circle().fill(dotColor).frame(width: 2.2, height: 2.2)
                    Circle().fill(dotColor).frame(width: 2.2, height: 2.2)
                }
                HStack(spacing: 2) {
                    Circle().fill(dotColor).frame(width: 2.2, height: 2.2)
                    Circle().fill(dotColor).frame(width: 2.2, height: 2.2)
                }
            }

            // Native NSView with open-hand cursor & performDrag
            NativeDragHandleRepresentable()
                .frame(width: 22, height: 22)
        }
        .frame(width: 22, height: 22)
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoverState.isHovered = hovering
            }
        }
        .help("Drag to reposition widget anywhere on your screen")
    }

    private var dotColor: Color {
        hoverState.isHovered ? Color.white : Color.white.opacity(0.65)
    }
}
