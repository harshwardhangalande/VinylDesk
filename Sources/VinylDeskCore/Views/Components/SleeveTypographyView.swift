import SwiftUI

public struct SleeveTypographyView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: SleeveThemeConfig
    var isLightBackground: Bool = false

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
        VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 3) {
            // Track Name
            if theme.trackNameStyle.isVisible {
                Text(coordinator.currentTrack.title)
                    .font(fontFor(theme.trackNameStyle))
                    .foregroundColor(colorFor(theme.trackNameStyle))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(2)
                    .shadow(
                        color: Color.black.opacity(theme.trackNameStyle.shadow.opacity),
                        radius: theme.trackNameStyle.shadow.radius,
                        x: 0,
                        y: theme.trackNameStyle.shadow.yOffset
                    )
            }

            // Artist Name
            if theme.artistStyle.isVisible {
                Text(coordinator.currentTrack.artist)
                    .font(fontFor(theme.artistStyle))
                    .foregroundColor(colorFor(theme.artistStyle).opacity(0.85))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(1)
                    .shadow(
                        color: Color.black.opacity(theme.artistStyle.shadow.opacity),
                        radius: theme.artistStyle.shadow.radius,
                        x: 0,
                        y: theme.artistStyle.shadow.yOffset
                    )
            }

            // Album Name
            if theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty {
                Text(coordinator.currentTrack.album)
                    .font(fontFor(theme.albumStyle))
                    .foregroundColor(colorFor(theme.albumStyle).opacity(0.65))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(1)
                    .shadow(
                        color: Color.black.opacity(theme.albumStyle.shadow.opacity),
                        radius: theme.albumStyle.shadow.radius,
                        x: 0,
                        y: theme.albumStyle.shadow.yOffset
                    )
            }

            // Optional Progress Bar
            if theme.showProgressBar {
                VStack(spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.12))
                                .frame(height: 3)

                            Capsule()
                                .fill(Color.primary.opacity(0.75))
                                .frame(width: max(0, min(geo.size.width * CGFloat(coordinator.currentTrack.progress), geo.size.width)), height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 4)

                    HStack {
                        Text(coordinator.currentTrack.formattedPosition)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color.primary.opacity(0.5))
                        Spacer()
                        Text(coordinator.currentTrack.formattedDuration)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color.primary.opacity(0.5))
                    }
                }
                .frame(width: max(120, theme.containerWidth * 0.9))
                .padding(.top, 2)
            }

            // Inline Controls
            if theme.showPlaybackControls && theme.controlsPlacement == .inlineWithText {
                SleeveControlsView(coordinator: coordinator, theme: theme, isOverlay: false)
                    .padding(.top, 4)
            }
        }
    }

    private func fontFor(_ config: TypographyLineConfig) -> Font {
        return Font.system(
            size: config.fontSize,
            weight: config.fontWeight.fontWeight,
            design: config.fontDesign.fontDesign
        )
    }

    private func colorFor(_ config: TypographyLineConfig) -> Color {
        if isLightBackground {
            return config.isWhiteText ? Color.black : Color(white: 0.2)
        } else {
            return config.isWhiteText ? Color.white : Color(white: 0.9)
        }
    }
}
