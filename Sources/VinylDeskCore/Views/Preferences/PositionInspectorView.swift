import SwiftUI

public struct PositionInspectorView: View {
    @ObservedObject var themeManager: VinylThemeManager

    @MainActor
    public init(themeManager: VinylThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Visibility
                VinylSectionCard {
                    Text("Visibility")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 12) {
                        VinylOptionCard(
                            title: "Show only on desktop",
                            isSelected: themeManager.currentTheme.visibility == .desktopOnly,
                            action: {
                                themeManager.currentTheme.visibility = .desktopOnly
                                themeManager.currentTheme.windowPlacement = .desktop
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.3)).frame(width: 48, height: 32)
                                RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: 20, height: 16)
                            }
                        }

                        VinylOptionCard(
                            title: "Show everywhere",
                            isSelected: themeManager.currentTheme.visibility == .showEverywhere,
                            action: {
                                themeManager.currentTheme.visibility = .showEverywhere
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
                VinylSectionCard {
                    Text("Quick Desktop Pinning")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Click a corner to instantly snap the widget to that area on your primary screen:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        Button("Top-Left ↖") {
                            DesktopWidgetController.shared.snap(to: .topLeft)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        Button("Top-Right ↗") {
                            DesktopWidgetController.shared.snap(to: .topRight)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        Button("Bottom-Left ↙") {
                            DesktopWidgetController.shared.snap(to: .bottomLeft)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        Button("Bottom-Right ↘") {
                            DesktopWidgetController.shared.snap(to: .bottomRight)
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
}
