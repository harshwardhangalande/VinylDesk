import SwiftUI

public struct VinylTypographyView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: VinylThemeConfig
    var isLightBackground: Bool = false

    @MainActor
    public init(
        coordinator: MusicCoordinator,
        theme: VinylThemeConfig,
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
                let duration = max(1.0, coordinator.currentTrack.duration)
                let progress = min(max(coordinator.playbackPosition / duration, 0.0), 1.0)
                let barColor = colorFor(theme.trackNameStyle).opacity(0.80)
                let trackBg = colorFor(theme.trackNameStyle).opacity(0.18)
                let timeColor = colorFor(theme.artistStyle).opacity(0.60)
                VStack(spacing: 3) {
                    GeometryReader { geo in
                        let barWidth = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(trackBg)
                                .frame(height: 3)

                            Capsule()
                                .fill(barColor)
                                .frame(width: max(0, min(barWidth * CGFloat(progress), barWidth)), height: 3)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let fraction = max(0, min(1, gesture.location.x / barWidth))
                                    coordinator.seek(to: Double(fraction) * duration)
                                }
                        )
                    }
                    .frame(height: 3)
                    .padding(.top, 4)

                    HStack {
                        Text(TrackInfo.formatTime(coordinator.playbackPosition))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(timeColor)
                        Spacer()
                        Text(coordinator.currentTrack.formattedDuration)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(timeColor)
                    }
                }
                .frame(width: max(120, theme.containerWidth * 0.9))
                .padding(.top, 2)
            }

            // Inline Controls
            if theme.showPlaybackControls && theme.controlsPlacement == .inlineWithText {
                VinylControlsView(coordinator: coordinator, theme: theme, isOverlay: false)
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
        return config.isWhiteText ? Color.white : Color(white: 0.15)
    }
}
