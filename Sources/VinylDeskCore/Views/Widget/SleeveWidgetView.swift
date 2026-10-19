import SwiftUI

public struct SleeveWidgetView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: SleeveThemeConfig
    var isLightBackground: Bool = false
    @StateObject private var hoverState = WidgetHoverState()

    @MainActor
    public init(
        coordinator: MusicCoordinator,
        theme: SleeveThemeConfig,
        isLightBackground: Bool = false
    ) {
        self.coordinator = coordinator
        self.theme = theme
        self.isLightBackground = isLightBackground
    }

    public var body: some View {
        Group {
            switch theme.layout {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            case .stacked:
                stackedLayout
            case .textOnly:
                textOnlyLayout
            case .vintageVinyl:
                vintageVinylLayout
            case .woodenShelf:
                woodenShelfLayout
            }
        }
        .padding(theme.backdropMaterial == .clear ? 8 : 16)
        .background(backdropLayer)
        .overlay(
            WindowDragGripView()
                .padding(theme.backdropMaterial == .clear ? 2 : 6),
            alignment: .topTrailing
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoverState.isHovered = hovering
            }
        }
    }

    // MARK: - Layout Configurations

    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(alignment: verticalAlignmentForTheme, spacing: 14) {
            if theme.flipHorizontal {
                typographyView
                artworkView
            } else {
                artworkView
                typographyView
            }
        }
    }

    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 12) {
            artworkView
            typographyView
        }
    }

    @ViewBuilder
    private var stackedLayout: some View {
        VStack(spacing: 10) {
            artworkView
            typographyView
        }
        .frame(width: max(theme.artworkSize + 28, theme.containerWidth))
    }

    @ViewBuilder
    private var textOnlyLayout: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.accentColor)

            typographyView
        }
    }

    @ViewBuilder
    private var vintageVinylLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            artworkView
            typographyView
        }
    }

    @ViewBuilder
    private var woodenShelfLayout: some View {
        HStack(alignment: .center, spacing: 18) {
            artworkView
            typographyView
        }
    }

    // MARK: - Subviews

    private var artworkView: some View {
        SleeveArtworkView(
            coordinator: coordinator,
            theme: theme,
            isHovered: hoverState.isHovered,
            onHoverChanged: { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoverState.isHovered = hovering
                }
            }
        )
    }

    private var typographyView: some View {
        SleeveTypographyView(
            coordinator: coordinator,
            theme: theme,
            isLightBackground: isLightBackground
        )
        .frame(minWidth: theme.containerWidth, alignment: alignmentForTheme)
    }

    // MARK: - Backdrop Layer

    @ViewBuilder
    private var backdropLayer: some View {
        switch theme.backdropMaterial {
        case .glass:
            RoundedRectangle(cornerRadius: theme.backdropCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.backdropCornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
        case .blur:
            RoundedRectangle(cornerRadius: theme.backdropCornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
        case .solid:
            RoundedRectangle(cornerRadius: theme.backdropCornerRadius, style: .continuous)
                .fill(isLightBackground ? Color.white : Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.backdropCornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        case .clear:
            Color.clear
        }
    }

    // MARK: - Alignment Helpers

    private var alignmentForTheme: Alignment {
        switch theme.horizontalAlign {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private var verticalAlignmentForTheme: VerticalAlignment {
        switch theme.verticalAlign {
        case .top: return .top
        case .middle: return .center
        case .bottom: return .bottom
        }
    }
}
