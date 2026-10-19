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
