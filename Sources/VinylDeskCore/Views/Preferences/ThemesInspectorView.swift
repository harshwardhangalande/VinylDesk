import SwiftUI

public struct ThemesInspectorView: View {
    @ObservedObject var themeManager: SleeveThemeManager
    @StateObject private var state = ThemesInspectorState()

    @MainActor
    public init(themeManager: SleeveThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SleeveSectionCard {
                    Text("Included Themes")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Switch between curated themes designed to match different desktop aesthetics:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(themeManager.presets) { preset in
                            Button(action: {
                                themeManager.selectPreset(preset)
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(themeManager.currentTheme.name == preset.name ? Color(red: 0.15, green: 0.40, blue: 0.65) : Color(white: 0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(themeManager.currentTheme.name == preset.name ? Color.cyan : Color.white.opacity(0.1), lineWidth: 1.5)
                                            )

                                        VStack(spacing: 4) {
                                            presetIcon(for: preset)
                                            Text(preset.name)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(height: 70)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                SleeveSectionCard {
                    Text("Theme Management")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 12) {
                        Button("Export Theme JSON") {
                            if let json = themeManager.exportThemeJSON() {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(json, forType: .string)
                                state.exportedJSON = json
                                state.showExportAlert = true
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                        .foregroundColor(.white)

                        Button("Reset to Default") {
                            themeManager.resetToDefault()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.22)))
                        .foregroundColor(.primary)
                    }

                    if state.showExportAlert {
                        Text("✓ Copied theme configuration JSON to your clipboard!")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func presetIcon(for preset: SleeveThemeConfig) -> some View {
        switch preset.layout {
        case .stacked:
            Image(systemName: "square.stack.fill").font(.system(size: 18)).foregroundColor(.cyan)
        case .horizontal:
            Image(systemName: "rectangle.leadinghalf.filled").font(.system(size: 18)).foregroundColor(.blue)
        case .vertical:
            Image(systemName: "rectangle.portrait.fill").font(.system(size: 18)).foregroundColor(.orange)
        case .textOnly:
            Image(systemName: "text.alignleft").font(.system(size: 18)).foregroundColor(.teal)
        case .vintageVinyl:
            Image(systemName: "record.circle").font(.system(size: 18)).foregroundColor(.yellow)
        case .woodenShelf:
            Image(systemName: "archivebox.fill").font(.system(size: 18)).foregroundColor(.brown)
        case .timeDashboard:
            Image(systemName: "timer").font(.system(size: 18)).foregroundColor(.green)
        case .splitBanner:
            Image(systemName: "rectangle.split.2x1.fill").font(.system(size: 18)).foregroundColor(.orange)
        case .artworkPoster:
            Image(systemName: "photo.fill").font(.system(size: 18)).foregroundColor(.red)
        case .compactSquare:
            Image(systemName: "square.fill").font(.system(size: 18)).foregroundColor(.pink)
        case .artworkCard:
            Image(systemName: "app.fill").font(.system(size: 18)).foregroundColor(.purple)
        }
    }
}
