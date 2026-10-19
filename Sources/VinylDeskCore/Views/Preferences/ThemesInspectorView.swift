import SwiftUI

public struct ThemesInspectorView: View {
    @ObservedObject var themeManager: VinylThemeManager
    @StateObject private var state = ThemesInspectorState()

    @MainActor
    public init(themeManager: VinylThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - My Themes (Custom User Themes)
                VinylSectionCard {
                    HStack {
                        Text("My Themes")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Button(action: {
                            state.newThemeName = "\(themeManager.currentTheme.name) Custom"
                            state.showSaveCustomModal = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Save Current as New")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if themeManager.userThemes.isEmpty {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("No custom themes saved yet. Customize any preset and click 'Save Current as New' to save it to My Themes!")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.16)))
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(themeManager.userThemes) { userTheme in
                                ZStack(alignment: .topTrailing) {
                                    Button(action: {
                                        themeManager.applyTheme(userTheme, preserveUserPreferences: true)
                                    }) {
                                        VStack(spacing: 6) {
                                            presetIcon(for: userTheme)
                                            Text(userTheme.name)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(themeManager.currentTheme.id == userTheme.id ? Color(red: 0.15, green: 0.40, blue: 0.65) : Color(white: 0.18))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(themeManager.currentTheme.id == userTheme.id ? Color.cyan : Color.white.opacity(0.1), lineWidth: 1.5)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // Delete custom theme button
                                    Button(action: {
                                        themeManager.deleteCustomTheme(id: userTheme.id)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.red.opacity(0.85))
                                            .background(Circle().fill(Color.black))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(4)
                                }
                            }
                        }
                    }

                    if state.showSaveCustomModal {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name your custom theme:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)

                            HStack {
                                TextField("Theme Name", text: $state.newThemeName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())

                                Button("Save") {
                                    themeManager.saveCurrentAsCustomTheme(name: state.newThemeName)
                                    state.showSaveCustomModal = false
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 5).fill(Color.blue))
                                .foregroundColor(.white)

                                Button("Cancel") {
                                    state.showSaveCustomModal = false
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.15)))
                        .transition(.opacity)
                    }
                }

                // MARK: - Included Presets
                VinylSectionCard {
                    Text("Included Presets")
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
                                            .fill(themeManager.currentTheme.id == preset.id ? Color(red: 0.15, green: 0.40, blue: 0.65) : Color(white: 0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(themeManager.currentTheme.id == preset.id ? Color.cyan : Color.white.opacity(0.1), lineWidth: 1.5)
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

                VinylSectionCard {
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
    private func presetIcon(for preset: VinylThemeConfig) -> some View {
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
        case .splitCard:
            Image(systemName: "rectangle.righthalf.filled").font(.system(size: 18)).foregroundColor(.indigo)
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
