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
                // Visibility
                SleeveSectionCard {
                    HStack {
                        Text("Visibility")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }

                    Text("Choose where Vinyl appears on your screen:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        SleeveOptionCard(
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

                        SleeveOptionCard(
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

                // Liquid Glass Advanced Controls
                if themeManager.currentTheme.backdropMaterial == .liquidGlass || themeManager.currentTheme.backdropMaterial == .glass {
                    SleeveSectionCard {
                        HStack {
                            Text("Liquid Glass Intensity")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text(themeManager.currentTheme.liquidGlassLevel.displayName)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.cyan)
                        }

                        // Level Selector (System, Low, Medium, High, Ultra)
                        HStack(spacing: 6) {
                            ForEach(LiquidGlassLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    themeManager.currentTheme.liquidGlassLevel = level
                                    // Reset custom overrides when selecting level preset
                                    themeManager.currentTheme.liquidGlassCustomOpacity = 0
                                    themeManager.currentTheme.liquidGlassCustomBlur = 0
                                    themeManager.currentTheme.liquidGlassRimShine = 0
                                    themeManager.saveCurrentTheme()
                                }) {
                                    VStack(spacing: 3) {
                                        Text(level == .system ? "System" : level.rawValue)
                                            .font(.system(size: 11, weight: themeManager.currentTheme.liquidGlassLevel == level ? .bold : .regular))
                                            .foregroundColor(themeManager.currentTheme.liquidGlassLevel == level ? .white : .primary.opacity(0.75))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeManager.currentTheme.liquidGlassLevel == level ? Color.blue : Color(white: 0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeManager.currentTheme.liquidGlassLevel == level ? Color.cyan : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Level Description Callout
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)
                            Text(levelDescription(for: themeManager.currentTheme.liquidGlassLevel))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)

                        Divider().opacity(0.3)

                        // Liquid Tint Mode
                        Text("Liquid Fluid Tint")
                            .font(.system(size: 12, weight: .medium))

                        HStack(spacing: 6) {
                            ForEach(LiquidGlassTint.allCases, id: \.self) { tint in
                                Button(action: {
                                    themeManager.currentTheme.liquidGlassTint = tint
                                    themeManager.saveCurrentTheme()
                                }) {
                                    Text(tint.rawValue)
                                        .font(.system(size: 11, weight: themeManager.currentTheme.liquidGlassTint == tint ? .bold : .regular))
                                        .foregroundColor(themeManager.currentTheme.liquidGlassTint == tint ? .white : .primary.opacity(0.75))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(themeManager.currentTheme.liquidGlassTint == tint ? Color.blue.opacity(0.8) : Color(white: 0.16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(themeManager.currentTheme.liquidGlassTint == tint ? Color.cyan : Color.white.opacity(0.06), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Fluid Living Pulse
                        Toggle("Fluid Specular Breathing (when music plays)", isOn: Binding(
                            get: { themeManager.currentTheme.liquidGlassFluidPulse },
                            set: { themeManager.currentTheme.liquidGlassFluidPulse = $0; themeManager.saveCurrentTheme() }
                        ))
                        .toggleStyle(SwitchToggleStyle())

                        Divider().opacity(0.3)

                        // Fine-Tuning Sliders ("and more")
                        Text("Fine-Tuning & Custom Adjustments")
                            .font(.system(size: 12, weight: .medium))

                        // Custom Opacity Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Glass Opacity")
                                    .font(.system(size: 11))
                                Spacer()
                                let currentVal = themeManager.currentTheme.liquidGlassCustomOpacity > 0.01
                                    ? themeManager.currentTheme.liquidGlassCustomOpacity
                                    : themeManager.currentTheme.liquidGlassLevel.baseOpacity
                                Text("\(Int(currentVal * 100))%")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: {
                                        themeManager.currentTheme.liquidGlassCustomOpacity > 0.01
                                            ? themeManager.currentTheme.liquidGlassCustomOpacity
                                            : themeManager.currentTheme.liquidGlassLevel.baseOpacity
                                    },
                                    set: {
                                        themeManager.currentTheme.liquidGlassCustomOpacity = $0
                                        themeManager.saveCurrentTheme()
                                    }
                                ),
                                in: 0.10...0.90,
                                step: 0.02
                            )
                        }

                        // Custom Rim Shine Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Specular Rim & Edge Shine")
                                    .font(.system(size: 11))
                                Spacer()
                                let currentRim = themeManager.currentTheme.liquidGlassRimShine > 0.01
                                    ? themeManager.currentTheme.liquidGlassRimShine
                                    : themeManager.currentTheme.liquidGlassLevel.rimShine
                                Text("\(Int(currentRim * 100))%")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: {
                                        themeManager.currentTheme.liquidGlassRimShine > 0.01
                                            ? themeManager.currentTheme.liquidGlassRimShine
                                            : themeManager.currentTheme.liquidGlassLevel.rimShine
                                    },
                                    set: {
                                        themeManager.currentTheme.liquidGlassRimShine = $0
                                        themeManager.saveCurrentTheme()
                                    }
                                ),
                                in: 0.05...1.0,
                                step: 0.05
                            )
                        }

                        // System Accessibility Indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ? Color.orange : Color.green)
                                .frame(width: 7, height: 7)
                            Text(
                                NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
                                    ? "macOS Reduce Transparency: Active (Using High-Contrast Glass)"
                                    : "macOS Transparency: Full Vibrancy Active"
                            )
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        }
                        .padding(.top, 2)
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

    private func levelDescription(for level: LiquidGlassLevel) -> String {
        switch level {
        case .system:
            return "Automatically tunes opacity & blur to macOS system appearance, accent color, and accessibility transparency."
        case .low:
            return "Minimalist sheer glass with 18% opacity, 12pt blur, and delicate specular edge."
        case .medium:
            return "Balanced macOS frosted glass with 32% opacity, 22pt blur, and dual-tone specular highlight."
        case .high:
            return "Rich deep frosted glass with 52% opacity, 36pt blur, and luminous beveled rim."
        case .ultra:
            return "Hyper-stylized 72% liquid glass with 52pt caustic blur, chromatic edge refraction, and glowing rim."
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
