import SwiftUI

public struct PositionInspectorView: View {
    @ObservedObject var themeManager: SleeveThemeManager

    @MainActor
    public init(themeManager: SleeveThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Window Placement
                SleeveSectionCard {
                    Text("Window Placement")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 12) {
                        SleeveOptionCard(
                            title: "Keep on Desktop",
                            isSelected: themeManager.currentTheme.windowPlacement == .desktop,
                            action: {
                                themeManager.currentTheme.windowPlacement = .desktop
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.3)).frame(width: 48, height: 32)
                                RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: 20, height: 16)
                            }
                        }

                        SleeveOptionCard(
                            title: "Above all windows",
                            isSelected: themeManager.currentTheme.windowPlacement == .floating,
                            action: {
                                themeManager.currentTheme.windowPlacement = .floating
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)).frame(width: 48, height: 32)
                                RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: 20, height: 16)
                                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                        }
                    }

                    Toggle("Float on track change", isOn: Binding(
                        get: { themeManager.currentTheme.floatOnTrackChange },
                        set: { themeManager.currentTheme.floatOnTrackChange = $0; themeManager.saveCurrentTheme() }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                    .padding(.top, 4)
                }

                // Desktop Pinning Presets
                SleeveSectionCard {
                    Text("Quick Desktop Pinning")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Click a corner to instantly snap the widget to that area on your primary screen:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        Button("Top-Left ↖") {
                            snapWidget(to: .topLeft)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        Button("Top-Right ↗") {
                            snapWidget(to: .topRight)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        Button("Bottom-Left ↙") {
                            snapWidget(to: .bottomLeft)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        Button("Bottom-Right ↘") {
                            snapWidget(to: .bottomRight)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))
                    }
                }
            }
            .padding(16)
        }
    }

    private enum ScreenCorner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func snapWidget(to corner: ScreenCorner) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        for window in NSApp.windows where !window.title.contains("Preferences") && window.className.contains("SwiftUI") {
            var newOrigin = window.frame.origin
            let winWidth = window.frame.width
            let winHeight = window.frame.height

            switch corner {
            case .topLeft:
                newOrigin = CGPoint(x: screenFrame.minX + 30, y: screenFrame.maxY - winHeight - 30)
            case .topRight:
                newOrigin = CGPoint(x: screenFrame.maxX - winWidth - 30, y: screenFrame.maxY - winHeight - 30)
            case .bottomLeft:
                newOrigin = CGPoint(x: screenFrame.minX + 30, y: screenFrame.minY + 30)
            case .bottomRight:
                newOrigin = CGPoint(x: screenFrame.maxX - winWidth - 30, y: screenFrame.minY + 30)
            }

            window.setFrameOrigin(newOrigin)
        }
    }
}
