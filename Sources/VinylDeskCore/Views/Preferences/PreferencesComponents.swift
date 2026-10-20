import SwiftUI

// MARK: - Selectable Card Option

public struct VinylOptionCard<Content: View>: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let content: () -> Content

    public init(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
        self.content = content
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(white: 0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected ? Color.blue : Color.white.opacity(0.12),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    content()
                        .padding(8)
                }
                .frame(height: 72)

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.blue : Color.primary.opacity(0.85))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Segmented Size Selector Button

public struct VinylSegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .white : .primary.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color(red: 0.15, green: 0.45, blue: 0.70) : Color(white: 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Card Container

public struct VinylSectionCard<Content: View>: View {
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.14).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Alignment & Orientation Card

public struct VinylAlignmentCard: View {
    @ObservedObject var themeManager: VinylThemeManager

    public init(themeManager: VinylThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        VinylSectionCard {
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

            Divider().background(Color.white.opacity(0.1)).padding(.vertical, 2)

            Toggle("Flip horizontally", isOn: Binding(
                get: { themeManager.currentTheme.flipHorizontal },
                set: { themeManager.currentTheme.flipHorizontal = $0; themeManager.saveCurrentTheme() }
            ))
            .toggleStyle(SwitchToggleStyle())
        }
    }
}
