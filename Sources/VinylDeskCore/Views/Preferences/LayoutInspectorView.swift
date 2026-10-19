import SwiftUI

public struct LayoutInspectorView: View {
    @ObservedObject var themeManager: SleeveThemeManager

    @MainActor
    public init(themeManager: SleeveThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Layout Selector Grid
                SleeveSectionCard {
                    Text("Layout Style")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        SleeveOptionCard(
                            title: "Horizontal",
                            isSelected: themeManager.currentTheme.layout == .horizontal,
                            action: { themeManager.currentTheme.layout = .horizontal; themeManager.saveCurrentTheme() }
                        ) {
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: 22, height: 22)
                                VStack(alignment: .leading, spacing: 3) {
                                    Rectangle().fill(Color.white.opacity(0.8)).frame(width: 28, height: 3)
                                    Rectangle().fill(Color.white.opacity(0.4)).frame(width: 18, height: 3)
                                }
                            }
                        }

                        SleeveOptionCard(
                            title: "Vertical",
                            isSelected: themeManager.currentTheme.layout == .vertical,
                            action: { themeManager.currentTheme.layout = .vertical; themeManager.saveCurrentTheme() }
                        ) {
                            VStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: 22, height: 22)
                                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 24, height: 3)
                            }
                        }

                        SleeveOptionCard(
                            title: "Stacked",
                            isSelected: themeManager.currentTheme.layout == .stacked,
                            action: { themeManager.currentTheme.layout = .stacked; themeManager.saveCurrentTheme() }
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.35)).frame(width: 36, height: 36)
                                RoundedRectangle(cornerRadius: 4).fill(Color.blue).frame(width: 26, height: 26)
                            }
                        }

                        SleeveOptionCard(
                            title: "Text only",
                            isSelected: themeManager.currentTheme.layout == .textOnly,
                            action: { themeManager.currentTheme.layout = .textOnly; themeManager.saveCurrentTheme() }
                        ) {
                            VStack(spacing: 4) {
                                Rectangle().fill(Color.white.opacity(0.9)).frame(width: 32, height: 3)
                                Rectangle().fill(Color.white.opacity(0.5)).frame(width: 20, height: 3)
                            }
                        }

                        SleeveOptionCard(
                            title: "Retro Vinyl",
                            isSelected: themeManager.currentTheme.layout == .vintageVinyl,
                            action: {
                                themeManager.currentTheme.layout = .vintageVinyl
                                themeManager.currentTheme.showSpinningRecord = true
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            HStack(spacing: -6) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.orange).frame(width: 22, height: 22)
                                Circle().fill(Color.black).frame(width: 20, height: 20)
                            }
                        }

                        SleeveOptionCard(
                            title: "Wooden Shelf",
                            isSelected: themeManager.currentTheme.layout == .woodenShelf,
                            action: {
                                themeManager.currentTheme.layout = .woodenShelf
                                themeManager.saveCurrentTheme()
                            }
                        ) {
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.purple).frame(width: 22, height: 22)
                                RoundedRectangle(cornerRadius: 1).fill(Color.brown).frame(width: 30, height: 4)
                            }
                        }
                    }

                    Toggle("Flip horizontally", isOn: Binding(
                        get: { themeManager.currentTheme.flipHorizontal },
                        set: { themeManager.currentTheme.flipHorizontal = $0; themeManager.saveCurrentTheme() }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                    .padding(.top, 4)
                }

                // Alignment Controls
                SleeveSectionCard {
                    Text("Alignment")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    // Horizontal Alignment
                    HStack(spacing: 8) {
                        ForEach(HorizontalAlign.allCases, id: \.self) { align in
                            Button(action: {
                                themeManager.currentTheme.horizontalAlign = align
                                themeManager.saveCurrentTheme()
                            }) {
                                Text(align.rawValue)
                                    .font(.system(size: 12, weight: themeManager.currentTheme.horizontalAlign == align ? .bold : .regular))
                                    .foregroundColor(themeManager.currentTheme.horizontalAlign == align ? .white : .primary.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(themeManager.currentTheme.horizontalAlign == align ? Color.blue : Color(white: 0.20))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Vertical Alignment
                    HStack(spacing: 8) {
                        ForEach(VerticalAlign.allCases, id: \.self) { vAlign in
                            Button(action: {
                                themeManager.currentTheme.verticalAlign = vAlign
                                themeManager.saveCurrentTheme()
                            }) {
                                Text(vAlign.rawValue)
                                    .font(.system(size: 12, weight: themeManager.currentTheme.verticalAlign == vAlign ? .bold : .regular))
                                    .foregroundColor(themeManager.currentTheme.verticalAlign == vAlign ? .white : .primary.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(themeManager.currentTheme.verticalAlign == vAlign ? Color.blue : Color(white: 0.20))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Width Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Width")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(themeManager.currentTheme.containerWidth)) pt")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { themeManager.currentTheme.containerWidth },
                                set: { themeManager.currentTheme.containerWidth = $0; themeManager.saveCurrentTheme() }
                            ),
                            in: 140...380,
                            step: 5
                        )
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
    }
}
