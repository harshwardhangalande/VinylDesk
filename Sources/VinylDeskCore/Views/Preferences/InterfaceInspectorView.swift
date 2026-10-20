import SwiftUI

public struct InterfaceInspectorView: View {
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
                    HStack {
                        Text("Visibility")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }

                    Text("Choose where Vinyl appears on your screen:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

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
                            VStack(spacing: 5) {
                                Image(systemName: "menubar.dock.rectangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeManager.currentTheme.visibility == .desktopOnly ? .cyan : .secondary)
                                Text("On Desktop")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
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
                            VStack(spacing: 5) {
                                Image(systemName: "macwindow.on.rectangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeManager.currentTheme.visibility == .showEverywhere ? .cyan : .secondary)
                                Text("Above Windows")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(themeManager.currentTheme.visibility == .desktopOnly
                             ? "Pinned to your desktop wallpaper, resting beneath other application windows."
                             : "Floats on top of all application windows so it is always accessible.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }

                // Backdrop Material
                VinylSectionCard {
                    Text("Backdrop Material")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 8) {
                        ForEach(BackdropMaterial.allCases, id: \.self) { material in
                            Button(action: {
                                themeManager.currentTheme.backdropMaterial = material
                                themeManager.saveCurrentTheme()
                            }) {
                                Text(material.rawValue)
                                    .font(.system(size: 12, weight: themeManager.currentTheme.backdropMaterial == material ? .bold : .regular))
                                    .foregroundColor(themeManager.currentTheme.backdropMaterial == material ? .white : .primary.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeManager.currentTheme.backdropMaterial == material ? Color.blue : Color(white: 0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeManager.currentTheme.backdropMaterial == material ? Color.cyan : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    if themeManager.currentTheme.backdropMaterial != .clear {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Backdrop Corner Radius")
                                    .font(.system(size: 12))
                                Spacer()
                                Text("\(Int(themeManager.currentTheme.backdropCornerRadius)) pt")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { themeManager.currentTheme.backdropCornerRadius },
                                    set: { themeManager.currentTheme.backdropCornerRadius = $0; themeManager.saveCurrentTheme() }
                                ),
                                in: 0...36,
                                step: 2
                            )
                        }
                        .padding(.top, 4)
                    }
                }

                // Background Opacity
                VinylSectionCard {
                    HStack {
                        Text("Background Opacity")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\(Int(round(themeManager.currentTheme.widgetOpacity * 100)))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Text("Adjust background card transparency without affecting text and album artwork:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { themeManager.currentTheme.widgetOpacity },
                                set: {
                                    themeManager.currentTheme.widgetOpacity = $0
                                    themeManager.saveCurrentTheme()
                                }
                            ),
                            in: 0.0...1.0,
                            step: 0.05
                        )

                        HStack {
                            Text("0% (Transparent)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("100% (Solid)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }

                // Playback Controls
                VinylSectionCard {
                    Text("Playback Controls")
                        .font(.system(size: 13, weight: .semibold))

                    Toggle("Show playback controls", isOn: Binding(
                        get: { themeManager.currentTheme.showPlaybackControls },
                        set: { themeManager.currentTheme.showPlaybackControls = $0; themeManager.saveCurrentTheme() }
                    ))
                    .toggleStyle(SwitchToggleStyle())

                    if themeManager.currentTheme.showPlaybackControls {
                        Text("Placement")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.top, 4)

                        HStack(spacing: 12) {
                            VinylOptionCard(
                                title: "On artwork hover",
                                isSelected: themeManager.currentTheme.controlsPlacement == .onHover,
                                action: {
                                    themeManager.currentTheme.controlsPlacement = .onHover
                                    themeManager.saveCurrentTheme()
                                }
                            ) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.4)).frame(width: 32, height: 32)
                                    Image(systemName: "cursorarrow.rays")
                                        .foregroundColor(.white)
                                }
                            }

                            VinylOptionCard(
                                title: "Inline with text",
                                isSelected: themeManager.currentTheme.controlsPlacement == .inlineWithText,
                                action: {
                                    themeManager.currentTheme.controlsPlacement = .inlineWithText
                                    themeManager.saveCurrentTheme()
                                }
                            ) {
                                VStack(spacing: 4) {
                                    Rectangle().fill(Color.white.opacity(0.8)).frame(width: 28, height: 3)
                                    HStack(spacing: 3) {
                                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }

                        Text("Control Size")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.top, 4)

                        HStack(spacing: 8) {
                            ForEach(ControlsSize.allCases, id: \.self) { size in
                                Button(action: {
                                    themeManager.currentTheme.controlsSize = size
                                    themeManager.saveCurrentTheme()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "backward.fill").font(.system(size: size.iconSize * 0.7))
                                        Image(systemName: "play.fill").font(.system(size: size.iconSize * 0.9))
                                        Image(systemName: "forward.fill").font(.system(size: size.iconSize * 0.7))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeManager.currentTheme.controlsSize == size ? Color.blue : Color(white: 0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeManager.currentTheme.controlsSize == size ? Color.cyan : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        Toggle("Show progress timeline", isOn: Binding(
                            get: { themeManager.currentTheme.showProgressBar },
                            set: { themeManager.currentTheme.showProgressBar = $0; themeManager.saveCurrentTheme() }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    }
                }
            }
            .padding(16)
        }
    }

    private func descriptionForMode(_ mode: ExperienceMode) -> String {
        switch mode {
        case .dual:
            return "Active interactive screen overlay AND native macOS Sonoma/Sequoia desktop widgets."
        case .overlayOnly:
            return "Interactive floating canvas with live shaders, turntable disc, and freeform dragging."
        case .widgetOnly:
            return "Hide floating overlay and use native macOS Desktop Widget gallery on wallpaper."
        }
    }
}
