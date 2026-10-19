import SwiftUI

public struct ArtworkInspectorView: View {
    @ObservedObject var themeManager: SleeveThemeManager

    @MainActor
    public init(themeManager: SleeveThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Size Presets & Slider
                SleeveSectionCard {
                    Text("Artwork Size")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 8) {
                        SleeveSegmentButton(title: "S", isSelected: isApprox(themeManager.currentTheme.artworkSize, 100)) {
                            themeManager.currentTheme.artworkSize = 100
                            themeManager.saveCurrentTheme()
                        }
                        SleeveSegmentButton(title: "M", isSelected: isApprox(themeManager.currentTheme.artworkSize, 140)) {
                            themeManager.currentTheme.artworkSize = 140
                            themeManager.saveCurrentTheme()
                        }
                        SleeveSegmentButton(title: "L", isSelected: isApprox(themeManager.currentTheme.artworkSize, 180)) {
                            themeManager.currentTheme.artworkSize = 180
                            themeManager.saveCurrentTheme()
                        }
                        SleeveSegmentButton(title: "XL", isSelected: isApprox(themeManager.currentTheme.artworkSize, 220)) {
                            themeManager.currentTheme.artworkSize = 220
                            themeManager.saveCurrentTheme()
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Custom Size")
                                .font(.system(size: 12))
                            Spacer()
                            Text("\(Int(themeManager.currentTheme.artworkSize)) pt")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { themeManager.currentTheme.artworkSize },
                                set: { themeManager.currentTheme.artworkSize = $0; themeManager.saveCurrentTheme() }
                            ),
                            in: 80...260,
                            step: 4
                        )
                    }

                    // Corner Radius Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Corner Radius")
                                .font(.system(size: 12))
                            Spacer()
                            Text("\(Int(themeManager.currentTheme.cornerRadius))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { themeManager.currentTheme.cornerRadius },
                                set: { themeManager.currentTheme.cornerRadius = $0; themeManager.saveCurrentTheme() }
                            ),
                            in: 0...32,
                            step: 1
                        )
                    }
                }

                // Shadow Style Cards
                SleeveSectionCard {
                    Text("Shadow Depth")
                        .font(.system(size: 13, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ShadowStyle.allCases, id: \.self) { shadow in
                            SleeveOptionCard(
                                title: shadow.rawValue,
                                isSelected: themeManager.currentTheme.artworkShadow == shadow,
                                action: {
                                    themeManager.currentTheme.artworkShadow = shadow
                                    themeManager.saveCurrentTheme()
                                }
                            ) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                                    .frame(width: 28, height: 28)
                                    .shadow(
                                        color: Color.black.opacity(shadow.opacity),
                                        radius: shadow.radius * 0.4,
                                        x: 0,
                                        y: shadow.yOffset * 0.4
                                    )
                            }
                        }
                    }
                }

                // Lighting Effect Cards
                SleeveSectionCard {
                    Text("Lighting Effect")
                        .font(.system(size: 13, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        SleeveOptionCard(
                            title: "None",
                            isSelected: themeManager.currentTheme.lightingEffect == .none,
                            action: {
                                themeManager.currentTheme.lightingEffect = .none
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .frame(width: 28, height: 28)
                        }

                        SleeveOptionCard(
                            title: "Spotlight",
                            isSelected: themeManager.currentTheme.lightingEffect == .spotlight,
                            action: {
                                themeManager.currentTheme.lightingEffect = .spotlight
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                                    .frame(width: 28, height: 28)
                                RadialGradient(
                                    colors: [Color.white.opacity(0.8), Color.clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 24
                                )
                                .frame(width: 28, height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }

                        SleeveOptionCard(
                            title: "Glare",
                            isSelected: themeManager.currentTheme.lightingEffect == .glare,
                            action: {
                                themeManager.currentTheme.lightingEffect = .glare
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                                    .frame(width: 28, height: 28)
                                LinearGradient(
                                    colors: [Color.white.opacity(0.7), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(width: 28, height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }

                // Sleeve 3.3 Vintage Enhancements
                SleeveSectionCard {
                    Text("Vintage Additions (Sleeve 3.3)")
                        .font(.system(size: 13, weight: .semibold))

                    Toggle("Show Spinning Vinyl Record", isOn: Binding(
                        get: { themeManager.currentTheme.showSpinningRecord },
                        set: { themeManager.currentTheme.showSpinningRecord = $0; themeManager.saveCurrentTheme() }
                    ))
                    .toggleStyle(SwitchToggleStyle())

                    if themeManager.currentTheme.layout == .woodenShelf {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Desk Shelf Finish")
                                .font(.system(size: 12))

                            Picker("Shelf Finish", selection: Binding(
                                get: { themeManager.currentTheme.shelfFinish },
                                set: { themeManager.currentTheme.shelfFinish = $0; themeManager.saveCurrentTheme() }
                            )) {
                                ForEach(ShelfFinish.allCases, id: \.self) { finish in
                                    Text(finish.rawValue).tag(finish)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func isApprox(_ a: CGFloat, _ b: CGFloat) -> Bool {
        return abs(a - b) < 6
    }
}
