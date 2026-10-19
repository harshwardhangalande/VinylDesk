import SwiftUI

public struct InterfaceInspectorView: View {
    @ObservedObject var themeManager: SleeveThemeManager

    @MainActor
    public init(themeManager: SleeveThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Backdrop Material
                SleeveSectionCard {
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

                // Playback Controls
                SleeveSectionCard {
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
                            SleeveOptionCard(
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

                            SleeveOptionCard(
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

                        Toggle("Show 'Favorite' control (heart)", isOn: Binding(
                            get: { themeManager.currentTheme.showLikeControl },
                            set: { themeManager.currentTheme.showLikeControl = $0; themeManager.saveCurrentTheme() }
                        ))
                        .toggleStyle(SwitchToggleStyle())

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
}
