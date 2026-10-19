import SwiftUI

public enum TypographyTarget: String, CaseIterable, Identifiable {
    case trackName = "Name"
    case artist = "Artist"
    case album = "Album"

    public var id: String { rawValue }
}

public struct TypographyInspectorView: View {
    @ObservedObject var themeManager: VinylThemeManager
    @StateObject private var state = TypographyInspectorState()

    @MainActor
    public init(themeManager: VinylThemeManager) {
        self.themeManager = themeManager
    }

    private var activeConfig: Binding<TypographyLineConfig> {
        switch state.selectedTarget {
        case .trackName:
            return Binding(
                get: { themeManager.currentTheme.trackNameStyle },
                set: { themeManager.currentTheme.trackNameStyle = $0; themeManager.saveCurrentTheme() }
            )
        case .artist:
            return Binding(
                get: { themeManager.currentTheme.artistStyle },
                set: { themeManager.currentTheme.artistStyle = $0; themeManager.saveCurrentTheme() }
            )
        case .album:
            return Binding(
                get: { themeManager.currentTheme.albumStyle },
                set: { themeManager.currentTheme.albumStyle = $0; themeManager.saveCurrentTheme() }
            )
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Target Tab Selector (Name | Artist | Album)
                HStack(spacing: 0) {
                    ForEach(TypographyTarget.allCases) { target in
                        Button(action: { state.selectedTarget = target }) {
                            Text(target.rawValue)
                                .font(.system(size: 13, weight: state.selectedTarget == target ? .semibold : .regular))
                                .foregroundColor(state.selectedTarget == target ? .white : .primary.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(state.selectedTarget == target ? Color.blue : Color(white: 0.18))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))

                // Line Display Toggle
                VinylSectionCard {
                    Toggle("Display \(state.selectedTarget.rawValue.lowercased())", isOn: activeConfig.isVisible)
                        .toggleStyle(SwitchToggleStyle())

                    // Live Typography Preview Pill
                    if activeConfig.wrappedValue.isVisible {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 54)

                            Text(previewSampleText)
                                .font(.system(
                                    size: activeConfig.wrappedValue.fontSize,
                                    weight: activeConfig.wrappedValue.fontWeight.fontWeight,
                                    design: activeConfig.wrappedValue.fontDesign.fontDesign
                                ))
                                .foregroundColor(activeConfig.wrappedValue.isWhiteText ? .white : .black)
                                .shadow(
                                    color: Color.black.opacity(activeConfig.wrappedValue.shadow.opacity),
                                    radius: activeConfig.wrappedValue.shadow.radius * 0.5,
                                    x: 0,
                                    y: activeConfig.wrappedValue.shadow.yOffset * 0.5
                                )
                                .lineLimit(1)
                                .padding(.horizontal, 16)
                        }
                    }
                }

                if activeConfig.wrappedValue.isVisible {
                    // Font Family / Design
                    VinylSectionCard {
                        Text("Typography Style")
                            .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 8) {
                            ForEach(FontFamilyDesign.allCases, id: \.self) { design in
                                Button(action: {
                                    activeConfig.wrappedValue.fontDesign = design
                                    themeManager.saveCurrentTheme()
                                }) {
                                    VStack(spacing: 4) {
                                        Text("Abc")
                                            .font(.system(size: 15, weight: .semibold, design: design.fontDesign))
                                        Text(design.rawValue)
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(activeConfig.wrappedValue.fontDesign == design ? .white : .primary.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(activeConfig.wrappedValue.fontDesign == design ? Color.blue : Color(white: 0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(activeConfig.wrappedValue.fontDesign == design ? Color.cyan : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Font Weight Selector
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Font Weight")
                                .font(.system(size: 12))

                            HStack(spacing: 6) {
                                ForEach(FontWeightPreset.allCases, id: \.self) { weight in
                                    Button(action: {
                                        activeConfig.wrappedValue.fontWeight = weight
                                        themeManager.saveCurrentTheme()
                                    }) {
                                        Text(weight.rawValue)
                                            .font(.system(size: 11, weight: weight.fontWeight))
                                            .foregroundColor(activeConfig.wrappedValue.fontWeight == weight ? .white : .primary.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(activeConfig.wrappedValue.fontWeight == weight ? Color.blue : Color(white: 0.20))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        // Font Size Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Text Size")
                                    .font(.system(size: 12))
                                Spacer()
                                Text("\(Int(activeConfig.wrappedValue.fontSize)) pt")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: activeConfig.fontSize,
                                in: 10...26,
                                step: 1
                            )
                        }
                    }

                    // Text Shadow & Color
                    VinylSectionCard {
                        Text("Text Appearance")
                            .font(.system(size: 13, weight: .semibold))

                        // Color mode
                        HStack(spacing: 12) {
                            Button(action: {
                                activeConfig.wrappedValue.isWhiteText = true
                                themeManager.saveCurrentTheme()
                            }) {
                                HStack {
                                    Circle().fill(Color.white).frame(width: 14, height: 14)
                                    Text("White")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(activeConfig.wrappedValue.isWhiteText ? Color.blue : Color(white: 0.20)))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                activeConfig.wrappedValue.isWhiteText = false
                                themeManager.saveCurrentTheme()
                            }) {
                                HStack {
                                    Circle().fill(Color.black).frame(width: 14, height: 14)
                                    Text("Black")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(!activeConfig.wrappedValue.isWhiteText ? Color.blue : Color(white: 0.20)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Shadow Depth
                        Text("Text Shadow")
                            .font(.system(size: 12))
                            .padding(.top, 4)

                        HStack(spacing: 8) {
                            ForEach([ShadowStyle.none, ShadowStyle.subtle, ShadowStyle.regular], id: \.self) { shadow in
                                Button(action: {
                                    activeConfig.wrappedValue.shadow = shadow
                                    themeManager.saveCurrentTheme()
                                }) {
                                    Text(shadow.rawValue)
                                        .font(.system(size: 12))
                                        .foregroundColor(activeConfig.wrappedValue.shadow == shadow ? .white : .primary.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(activeConfig.wrappedValue.shadow == shadow ? Color.blue : Color(white: 0.20))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var previewSampleText: String {
        switch state.selectedTarget {
        case .trackName: return "To Feel Again / Trois"
        case .artist: return "Jon Hopkins"
        case .album: return "Music for Psychedelic Therapy"
        }
    }
}
