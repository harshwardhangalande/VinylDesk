import SwiftUI

public struct VinylWidgetView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: VinylThemeConfig
    var isLightBackground: Bool = false
    @StateObject private var hoverState = WidgetHoverState()
    @StateObject private var controlsState = VinylControlsState()

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

    private var isEdgeToEdge: Bool {
        theme.layout == .artworkPoster ||
        theme.layout == .artworkCard ||
        theme.layout == .compactSquare ||
        theme.layout == .splitCard ||
        theme.layout == .timeDashboard
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
            case .splitCard:
                splitCardLayout
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
        .padding(isEdgeToEdge ? 0 : (theme.backdropMaterial == .clear ? 8 : 14))
        .background(isEdgeToEdge ? AnyView(Color.clear) : AnyView(backdropLayer))
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
        let cardRadius: CGFloat = max(16, theme.cornerRadius)
        let cardWidth = max(330, theme.containerWidth)
        VStack(spacing: 0) {
            // Upper Section: Dark Time Dashboard
            HStack(alignment: .top) {
                // Elapsed
                VStack(alignment: .leading, spacing: 3) {
                    Text(formatTime(coordinator.playbackPosition))
                        .font(.system(size: 26, weight: .bold, design: theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(theme.trackNameStyle))
                    Text("ELAPSED TIME")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(colorFor(theme.trackNameStyle, opacity: 0.55))
                }

                Spacer()

                // Remaining (- time)
                let remaining = max(0, coordinator.currentTrack.duration - coordinator.playbackPosition)
                VStack(alignment: .center, spacing: 3) {
                    Text("-" + formatTime(remaining))
                        .font(.system(size: 26, weight: .bold, design: theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(theme.trackNameStyle))
                    Text("REMAINING TIME")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(colorFor(theme.trackNameStyle, opacity: 0.55))
                }

                Spacer()

                // Duration
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formatTime(coordinator.currentTrack.duration))
                        .font(.system(size: 26, weight: .bold, design: theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(theme.trackNameStyle))
                    Text("DURATION")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(colorFor(theme.trackNameStyle, opacity: 0.55))
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(isLightBackground ? Color(white: 0.88) : Color.black.opacity(0.85))

            // Lower Section: Frosted Track & Controls Bar
            HStack(spacing: 12) {
                if theme.flipHorizontal {
                    if theme.showPlaybackControls && (theme.controlsPlacement == .inlineWithText || hoverState.isHovered) {
                        timeDashboardControls
                    }
                    Spacer()
                    timeDashboardTextStack
                    posterThumbnail(size: 42, cornerRadius: max(6, min(12, theme.cornerRadius)))
                } else {
                    posterThumbnail(size: 42, cornerRadius: max(6, min(12, theme.cornerRadius)))
                    timeDashboardTextStack
                    Spacer()
                    if theme.showPlaybackControls && (theme.controlsPlacement == .inlineWithText || hoverState.isHovered) {
                        timeDashboardControls
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isLightBackground ? Color.black.opacity(0.08) : Color.white.opacity(0.18))
        }
        .frame(width: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
    }

    @ViewBuilder
    private var timeDashboardTextStack: some View {
        VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 2) {
            if theme.trackNameStyle.isVisible {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(fontFor(theme.trackNameStyle, defaultSize: 15))
                    .foregroundColor(colorFor(theme.trackNameStyle))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(1)
            }

            let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
            let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
            if showArtist || showAlbum {
                HStack(spacing: 4) {
                    if showArtist {
                        Text(coordinator.currentTrack.artist.uppercased())
                            .font(fontFor(theme.artistStyle, defaultSize: 10))
                            .foregroundColor(colorFor(theme.artistStyle, opacity: 0.70))
                            .lineLimit(1)
                    }
                    if showArtist && showAlbum {
                        Text("—")
                            .font(fontFor(theme.albumStyle, defaultSize: 10))
                            .foregroundColor(colorFor(theme.albumStyle, opacity: 0.45))
                    }
                    if showAlbum {
                        Text(coordinator.currentTrack.album.uppercased())
                            .font(fontFor(theme.albumStyle, defaultSize: 10))
                            .foregroundColor(colorFor(theme.albumStyle, opacity: 0.65))
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timeDashboardControls: some View {
        HStack(spacing: max(8, theme.controlsSize.buttonPadding)) {
            let iconSize = max(11, theme.controlsSize.iconSize * 0.85)
            let btnSize = max(28, iconSize * 2.2)
            let buttonBg = isLightBackground ? Color.black.opacity(0.12) : Color.white.opacity(0.24)
            let buttonFg = isLightBackground ? Color.primary : Color.white

            Button(action: { coordinator.togglePlayPause() }) {
                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: iconSize * 1.15, weight: .bold))
                    .foregroundColor(buttonFg)
                    .frame(width: btnSize, height: btnSize)
                    .background(Circle().fill(buttonBg))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { coordinator.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(buttonFg)
                    .frame(width: btnSize, height: btnSize)
                    .background(Circle().fill(buttonBg))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .transition(.opacity)
    }

    // MARK: - Split Card Layout (Screenshot 2 Bottom Widget)

    @ViewBuilder
    private var splitCardLayout: some View {
        let cardRadius: CGFloat = theme.cornerRadius
        let cardWidth = max(360, theme.containerWidth)
        let leftWidth = cardWidth * 0.4
        let rightWidth = cardWidth * 0.6
        let cardHeight: CGFloat = (theme.artworkSize > 0 && theme.artworkSize <= 220) ? theme.artworkSize : leftWidth

        HStack(spacing: 0) {
            if theme.flipHorizontal {
                splitCardDetails(width: rightWidth, height: cardHeight)
                splitCardArtwork(width: leftWidth, height: cardHeight)
            } else {
                splitCardArtwork(width: leftWidth, height: cardHeight)
                splitCardDetails(width: rightWidth, height: cardHeight)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.20),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.38), radius: 14, x: 0, y: 7)
    }

    private var splitCardBackground: some View {
        let artworkColor: Color? = {
            if let dominant = ArtworkCache.shared.dominantColor(for: coordinator.currentTrack.id, data: coordinator.currentTrack.artworkData) {
                return Color(dominant)
            }
            return nil
        }()

        return ZStack {
            if isLightBackground {
                Color(white: 0.94).opacity(0.95)
            } else {
                // Base dark slate blue/charcoal (#262B3B)
                Color(red: 0.15, green: 0.17, blue: 0.23)

                // Subtle tint from the album artwork dominant color
                if let artColor = artworkColor {
                    artColor.opacity(0.28)
                } else {
                    Color(red: 0.20, green: 0.24, blue: 0.35).opacity(0.32)
                }
            }
        }
    }

    @ViewBuilder
    private func splitCardArtwork(width: CGFloat, height: CGFloat) -> some View {
        let artworkData = coordinator.currentTrack.artworkData
        let maxDim = max(width, height)
        let nsImage = ArtworkCache.shared.image(
            for: coordinator.currentTrack.id,
            data: artworkData,
            maxDimension: maxDim * 2.0
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
                        .font(.system(size: min(width, height) * 0.35, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    @ViewBuilder
    private func splitCardDetails(width: CGFloat, height: CGFloat) -> some View {
        let circleSize: CGFloat = 36
        let iconSize: CGFloat = 13
        let playIconSize: CGFloat = 14
        let buttonBg = isLightBackground ? Color.black.opacity(0.09) : Color.white.opacity(0.18)
        let buttonFg = isLightBackground ? Color.primary : Color.white

        VStack(alignment: .leading, spacing: 5) {
            if theme.trackNameStyle.isVisible {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorFor(theme.trackNameStyle))
                    .lineLimit(1)
            }

            let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
            let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
            if showArtist || showAlbum {
                let sub = (showArtist ? coordinator.currentTrack.artist : "") + (showArtist && showAlbum ? " — " : "") + (showAlbum ? coordinator.currentTrack.album : "")
                Text(sub)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isLightBackground ? Color.black.opacity(0.65) : Color.white.opacity(0.72))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if theme.showPlaybackControls {
                HStack(spacing: 12) {
                    Button(action: { coordinator.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(buttonFg)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(buttonBg))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: playIconSize, weight: .bold))
                            .foregroundColor(buttonFg)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(buttonBg))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(buttonFg)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(buttonBg))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(width: width, height: height, alignment: .leading)
        .background(splitCardBackground)
    }

    @ViewBuilder
    private var splitBannerLayout: some View {
        let thumbDim: CGFloat = max(70, min(120, theme.artworkSize > 0 ? theme.artworkSize : 100))
        HStack(spacing: 14) {
            if theme.flipHorizontal {
                splitBannerTextAndControls
                splitBannerThumbnail(size: thumbDim)
            } else {
                splitBannerThumbnail(size: thumbDim)
                splitBannerTextAndControls
            }
        }
        .frame(width: max(290, theme.containerWidth), height: thumbDim)
    }

    @ViewBuilder
    private func splitBannerThumbnail(size: CGFloat) -> some View {
        ZStack {
            // Strictly equal margins from top and leading (or trailing when flipped)
            posterThumbnail(size: size, cornerRadius: theme.cornerRadius)

            if theme.showPlaybackControls && theme.controlsPlacement == .onHover && hoverState.isHovered {
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .frame(width: size, height: size)
                    .overlay(
                        VinylControlsView(coordinator: coordinator, theme: theme, isOverlay: true)
                    )
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var splitBannerTextAndControls: some View {
        VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 4) {
            if theme.trackNameStyle.isVisible {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(fontFor(theme.trackNameStyle, defaultSize: 15))
                    .foregroundColor(colorFor(theme.trackNameStyle))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(1)
                    .shadow(
                        color: Color.black.opacity(theme.trackNameStyle.shadow.opacity),
                        radius: theme.trackNameStyle.shadow.radius,
                        x: 0,
                        y: theme.trackNameStyle.shadow.yOffset
                    )
            }

            if theme.artistStyle.isVisible {
                Text(coordinator.currentTrack.artist.isEmpty ? "Unknown Artist" : coordinator.currentTrack.artist)
                    .font(fontFor(theme.artistStyle, defaultSize: 12))
                    .foregroundColor(colorFor(theme.artistStyle, opacity: 0.85))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(1)
                    .shadow(
                        color: Color.black.opacity(theme.artistStyle.shadow.opacity),
                        radius: theme.artistStyle.shadow.radius,
                        x: 0,
                        y: theme.artistStyle.shadow.yOffset
                    )
            }

            if theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty {
                Text("— " + coordinator.currentTrack.album)
                    .font(fontFor(theme.albumStyle, defaultSize: 11))
                    .foregroundColor(colorFor(theme.albumStyle, opacity: 0.60))
                    .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                    .lineLimit(1)
                    .shadow(
                        color: Color.black.opacity(theme.albumStyle.shadow.opacity),
                        radius: theme.albumStyle.shadow.radius,
                        x: 0,
                        y: theme.albumStyle.shadow.yOffset
                    )
            }

            if theme.showPlaybackControls && theme.controlsPlacement == .inlineWithText {
                Spacer(minLength: 4)

                HStack(spacing: theme.controlsSize.buttonPadding * 1.2) {
                    let iconSize = max(11, theme.controlsSize.iconSize * 0.85)
                    let circleSize = max(28, iconSize * 2.2)
                    let playCircleSize = max(32, iconSize * 2.5)
                    let buttonBg = isLightBackground ? Color.black.opacity(0.12) : Color.white.opacity(0.24)
                    let buttonFg = isLightBackground ? Color.primary : Color.white

                    Button(action: { coordinator.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(buttonFg)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(buttonBg))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: iconSize * 1.15, weight: .bold))
                            .foregroundColor(buttonFg)
                            .frame(width: playCircleSize, height: playCircleSize)
                            .background(Circle().fill(buttonBg))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(buttonFg)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(buttonBg))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignmentForTheme)
    }

    // MARK: - Adaptive Poster Scrim Helper
    @ViewBuilder
    private func adaptivePosterScrim(cornerRadius: CGFloat) -> some View {
        if isLightBackground {
            // White light shadow with blur for light mode
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.42), Color.white.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            // Existing rich dark shadow for dark mode
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.40), Color.black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    private var compactSquareLayout: some View {
        let squareDim = max(100, min(320, theme.artworkSize > 0 ? theme.artworkSize : 160))
        ZStack(alignment: .bottomLeading) {
            // Full background poster filling all available space - no margin or padding
            posterThumbnail(size: squareDim, cornerRadius: theme.cornerRadius)

            // Adaptive gradient overlay for text readability at bottom (white light shadow in light mode, dark in dark mode)
            adaptivePosterScrim(cornerRadius: theme.cornerRadius)

            // Overlaid track info & controls with alignment support
            VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 3) {
                if theme.trackNameStyle.isVisible {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(fontFor(theme.trackNameStyle, defaultSize: max(11, squareDim * 0.08)))
                        .foregroundColor(colorFor(theme.trackNameStyle))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.4, theme.trackNameStyle.shadow.opacity)),
                            radius: max(3, theme.trackNameStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.trackNameStyle.shadow.yOffset)
                        )
                }

                let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
                let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
                if showArtist || showAlbum {
                    let sub = (showArtist ? coordinator.currentTrack.artist : "") + (showArtist && showAlbum ? " — " : "") + (showAlbum ? coordinator.currentTrack.album : "")
                    Text(sub)
                        .font(fontFor(theme.artistStyle, defaultSize: max(9, squareDim * 0.06)))
                        .foregroundColor(colorFor(theme.artistStyle, opacity: 0.85))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.3, theme.artistStyle.shadow.opacity)),
                            radius: max(3, theme.artistStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.artistStyle.shadow.yOffset)
                        )
                }

                // Controls
                if theme.showPlaybackControls {
                    let isVisible = theme.controlsPlacement == .inlineWithText || hoverState.isHovered
                    if isVisible {
                        let iconSize = max(10, theme.controlsSize.iconSize * 0.75)
                        let circleSize = max(24, iconSize * 2.2)
                        let playCircleSize = max(28, iconSize * 2.5)
                        let buttonBg = isLightBackground ? Color.black.opacity(0.12) : Color.white.opacity(0.24)
                        let buttonFg = isLightBackground ? Color.primary : Color.white

                        HStack(spacing: theme.controlsSize.buttonPadding) {
                            Button(action: { coordinator.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: iconSize, weight: .semibold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.togglePlayPause() }) {
                                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: iconSize * 1.15, weight: .bold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: playCircleSize, height: playCircleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: iconSize, weight: .semibold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: alignmentForTheme)
            .padding(10)
        }
        .frame(width: squareDim, height: squareDim)
    }

    @ViewBuilder
    private var artworkPosterLayout: some View {
        let posterDim = max(80, theme.artworkSize > 0 ? theme.artworkSize : 240)
        ZStack(alignment: .bottom) {
            // Full background poster image
            posterThumbnail(size: posterDim, cornerRadius: theme.cornerRadius)

            // Adaptive gradient overlay for text readability at bottom
            adaptivePosterScrim(cornerRadius: theme.cornerRadius)

            // Overlaid typography & floating controls with alignment support
            VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: max(4, posterDim * 0.025)) {
                if theme.trackNameStyle.isVisible {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(fontFor(theme.trackNameStyle, defaultSize: max(13, posterDim * 0.075)))
                        .foregroundColor(colorFor(theme.trackNameStyle))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(2)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.4, theme.trackNameStyle.shadow.opacity)),
                            radius: max(3, theme.trackNameStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.trackNameStyle.shadow.yOffset)
                        )
                }

                let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
                let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
                if showArtist || showAlbum {
                    let sub = (showArtist ? coordinator.currentTrack.artist : "") + (showArtist && showAlbum ? " — " : "") + (showAlbum ? coordinator.currentTrack.album : "")
                    Text(sub)
                        .font(fontFor(theme.artistStyle, defaultSize: max(10, posterDim * 0.05)))
                        .foregroundColor(colorFor(theme.artistStyle, opacity: 0.85))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.3, theme.artistStyle.shadow.opacity)),
                            radius: max(2, theme.artistStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.artistStyle.shadow.yOffset)
                        )
                }

                // Floating controls
                if theme.showPlaybackControls {
                    let isVisible = theme.controlsPlacement == .inlineWithText || hoverState.isHovered
                    if isVisible {
                        let iconSize = max(11, theme.controlsSize.iconSize * (posterDim < 180 ? 0.75 : 1.0))
                        let circleSize = iconSize * 2.2
                        let playCircleSize = iconSize * 2.6
                        let buttonBg = isLightBackground ? Color.black.opacity(0.12) : Color.white.opacity(0.24)
                        let buttonFg = isLightBackground ? Color.primary : Color.white

                        HStack(spacing: theme.controlsSize.buttonPadding * 1.5) {
                            Button(action: { coordinator.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: iconSize, weight: .semibold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.togglePlayPause() }) {
                                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: iconSize * 1.2, weight: .bold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: playCircleSize, height: playCircleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: iconSize, weight: .semibold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: alignmentForTheme)
            .padding(.horizontal, max(10, posterDim * 0.06))
            .padding(.bottom, max(10, posterDim * 0.06))
        }
        .frame(width: posterDim, height: posterDim)
    }

    @ViewBuilder
    private var artworkCardLayout: some View {
        let cardDim = max(100, min(360, theme.artworkSize > 0 ? theme.artworkSize : 150))
        ZStack {
            // Full background poster image
            posterThumbnail(size: cardDim, cornerRadius: theme.cornerRadius)

            // Adaptive overlay for contrast
            adaptivePosterScrim(cornerRadius: theme.cornerRadius)

            // Overlaid centered or aligned info and controls
            VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 6) {
                if theme.trackNameStyle.isVisible {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(fontFor(theme.trackNameStyle, defaultSize: max(12, cardDim * 0.08)))
                        .foregroundColor(colorFor(theme.trackNameStyle))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.4, theme.trackNameStyle.shadow.opacity)),
                            radius: max(4, theme.trackNameStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.trackNameStyle.shadow.yOffset)
                        )
                }

                if theme.artistStyle.isVisible {
                    Text(coordinator.currentTrack.artist.isEmpty ? "Unknown" : coordinator.currentTrack.artist)
                        .font(fontFor(theme.artistStyle, defaultSize: max(10, cardDim * 0.065)))
                        .foregroundColor(colorFor(theme.artistStyle, opacity: 0.85))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.3, theme.artistStyle.shadow.opacity)),
                            radius: max(3, theme.artistStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.artistStyle.shadow.yOffset)
                        )
                }

                if theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty {
                    Text(coordinator.currentTrack.album)
                        .font(fontFor(theme.albumStyle, defaultSize: max(9, cardDim * 0.055)))
                        .foregroundColor(colorFor(theme.albumStyle, opacity: 0.70))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: isLightBackground ? Color.white.opacity(0.9) : Color.black.opacity(max(0.3, theme.albumStyle.shadow.opacity)),
                            radius: max(3, theme.albumStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.albumStyle.shadow.yOffset)
                        )
                }

                if theme.showPlaybackControls {
                    let isVisible = theme.controlsPlacement == .inlineWithText || hoverState.isHovered
                    if isVisible {
                        let iconSize = max(10, theme.controlsSize.iconSize * 0.8)
                        let circleSize = max(24, iconSize * 2.2)
                        let playCircleSize = max(28, iconSize * 2.5)
                        let buttonBg = isLightBackground ? Color.black.opacity(0.12) : Color.white.opacity(0.24)
                        let buttonFg = isLightBackground ? Color.primary : Color.white

                        HStack(spacing: theme.controlsSize.buttonPadding) {
                            Button(action: { coordinator.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: iconSize, weight: .semibold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.togglePlayPause() }) {
                                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: iconSize * 1.15, weight: .bold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: playCircleSize, height: playCircleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: iconSize, weight: .semibold))
                                    .foregroundColor(buttonFg)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(buttonBg))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: alignmentForTheme)
            .padding(12)
        }
        .frame(width: cardDim, height: cardDim)
    }

    // MARK: - Typography & Color Helpers

    private func fontFor(_ config: TypographyLineConfig, defaultSize: CGFloat? = nil) -> Font {
        let size = config.fontSize > 0 ? config.fontSize : (defaultSize ?? 13)
        return Font.system(
            size: size,
            weight: config.fontWeight.fontWeight,
            design: config.fontDesign.fontDesign
        )
    }

    private func colorFor(_ config: TypographyLineConfig, opacity: Double = 1.0) -> Color {
        let baseColor: Color
        if isLightBackground {
            baseColor = config.isWhiteText ? Color.black : Color(white: 0.2)
        } else {
            baseColor = config.isWhiteText ? Color.white : Color(white: 0.9)
        }
        return baseColor.opacity(opacity)
    }

    private var buttonColor: Color {
        if isLightBackground {
            return Color.black
        }
        return Color.white
    }

    // MARK: - Lighting & Poster Thumbnail Helpers

    @ViewBuilder
    private func lightingOverlay(size: CGFloat, cornerRadius: CGFloat) -> some View {
        switch theme.lightingEffect {
        case .none:
            EmptyView()
        case .spotlight:
            RadialGradient(
                colors: [Color.white.opacity(0.35), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: size * 1.15
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .glare:
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.28), location: 0.0),
                    .init(color: Color.white.opacity(0.10), location: 0.42),
                    .init(color: Color.clear, location: 0.44),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

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
        .overlay(lightingOverlay(size: size, cornerRadius: cornerRadius))
        .shadow(
            color: isEdgeToEdge ? Color.clear : Color.black.opacity(theme.artworkShadow.opacity),
            radius: isEdgeToEdge ? 0 : theme.artworkShadow.radius,
            x: 0,
            y: isEdgeToEdge ? 0 : theme.artworkShadow.yOffset
        )
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Subviews

    private var artworkView: some View {
        VinylArtworkView(
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
        VinylTypographyView(
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
