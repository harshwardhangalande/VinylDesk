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

    private var isEdgeToEdge: Bool {
        theme.layout == .artworkPoster || theme.layout == .artworkCard
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
            case .timeDashboard:
                timeDashboardLayout
            case .artworkPoster:
                artworkPosterLayout
            case .compactSquare:
                compactSquareLayout
            case .splitBanner:
                splitBannerLayout
            case .artworkCard:
                artworkCardLayout
            }
        }
        .padding(isEdgeToEdge ? 0 : (theme.backdropMaterial == .clear ? 8 : (theme.layout == .compactSquare ? 12 : 14)))
        .background(isEdgeToEdge ? nil : backdropLayer)
        .overlay(
            WindowDragGripView()
                .padding(isEdgeToEdge ? 8 : 6),
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
        typographyView
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

    // MARK: - Screenshot New Layouts

    @ViewBuilder
    private var timeDashboardLayout: some View {
        VStack(spacing: 12) {
            // Three Time Metric Columns: Elapsed, Remaining, Duration
            HStack(alignment: .top) {
                // Elapsed
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(coordinator.playbackPosition))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    Text("ELAPSED TIME")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color.white.opacity(0.55))
                }

                Spacer()

                // Remaining (- time)
                let remaining = max(0, coordinator.currentTrack.duration - coordinator.playbackPosition)
                VStack(alignment: .center, spacing: 2) {
                    Text("-" + formatTime(remaining))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    Text("REMAINING TIME")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color.white.opacity(0.55))
                }

                Spacer()

                // Duration
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(coordinator.currentTrack.duration))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    Text("DURATION")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 4)

            // Bottom Track Bar Container
            HStack(spacing: 10) {
                // Poster thumbnail with equal left and top padding inside this card
                posterThumbnail(size: 42, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    let sub = (coordinator.currentTrack.artist + (coordinator.currentTrack.album.isEmpty ? "" : " — " + coordinator.currentTrack.album)).uppercased()
                    Text(sub)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer()

                // Compact playback controls
                HStack(spacing: 8) {
                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .frame(width: 320)
    }

    @ViewBuilder
    private var splitBannerLayout: some View {
        HStack(spacing: 14) {
            // Square poster thumbnail with strictly equal top and leading alignment (14pt from top and left)
            posterThumbnail(size: 100, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(coordinator.currentTrack.artist.isEmpty ? "Unknown Artist" : coordinator.currentTrack.artist)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)

                if !coordinator.currentTrack.album.isEmpty {
                    Text("— " + coordinator.currentTrack.album)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.60))
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                // Inline playback controls
                HStack(spacing: 8) {
                    Button(action: { coordinator.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 290, height: 100)
    }

    @ViewBuilder
    private var compactSquareLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Square poster thumbnail aligned symmetrically from top and leading (12pt from each edge)
            posterThumbnail(size: 44, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                let sub = coordinator.currentTrack.artist + (coordinator.currentTrack.album.isEmpty ? "" : " — " + coordinator.currentTrack.album)
                Text(sub)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.65))
                    .lineLimit(1)
            }

            // Micro controls row
            HStack(spacing: 12) {
                Button(action: { coordinator.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { coordinator.togglePlayPause() }) {
                    Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { coordinator.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 128)
    }

    @ViewBuilder
    private var artworkPosterLayout: some View {
        ZStack(alignment: .bottom) {
            // Full background poster image
            posterThumbnail(size: 300, cornerRadius: 24)

            // Gradient shadow on bottom half for high text readability
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Overlaid typography & floating controls
            VStack(spacing: 8) {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)

                let sub = coordinator.currentTrack.artist + (coordinator.currentTrack.album.isEmpty ? "" : " — " + coordinator.currentTrack.album)
                Text(sub)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 1)

                // Translucent floating controls
                HStack(spacing: 16) {
                    Button(action: { coordinator.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 300, height: 300)
    }

    @ViewBuilder
    private var artworkCardLayout: some View {
        ZStack {
            // Full background poster image
            posterThumbnail(size: 150, cornerRadius: 22)

            // Subtle dark overlay for contrast
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.3))

            // Overlaid centered info and controls
            VStack(spacing: 6) {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 1)

                Text(coordinator.currentTrack.artist.isEmpty ? "Unknown" : coordinator.currentTrack.artist)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 1)

                HStack(spacing: 12) {
                    Button(action: { coordinator.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .frame(width: 150, height: 150)
    }

    // MARK: - Poster Thumbnail Helper

    @ViewBuilder
    private func posterThumbnail(size: CGFloat, cornerRadius: CGFloat) -> some View {
        let artworkData = coordinator.currentTrack.artworkData
        let nsImage = ArtworkCache.shared.image(
            for: coordinator.currentTrack.id,
            data: artworkData,
            maxDimension: size * 2.0 // 2x Retina resolution
        )

        Group {
            if let image = nsImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.orange.opacity(0.85), Color.red.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.35, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
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
        case .glass, .liquidGlass:
            LiquidGlassBackdropView(
                theme: theme,
                coordinator: coordinator,
                isLightBackground: isLightBackground
            )
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
