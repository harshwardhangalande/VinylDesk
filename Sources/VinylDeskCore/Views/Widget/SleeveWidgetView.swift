import SwiftUI

public struct SleeveWidgetView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: SleeveThemeConfig
    var isLightBackground: Bool = false
    @StateObject private var hoverState = WidgetHoverState()
    @StateObject private var controlsState = SleeveControlsState()

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
                        .font(.system(size: 24, weight: .bold, design: theme.trackNameStyle.fontDesign.fontDesign))
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
                VStack(alignment: .center, spacing: 2) {
                    Text("-" + formatTime(remaining))
                        .font(.system(size: 24, weight: .bold, design: theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(theme.trackNameStyle))
                    Text("REMAINING TIME")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(colorFor(theme.trackNameStyle, opacity: 0.55))
                }

                Spacer()

                // Duration
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(coordinator.currentTrack.duration))
                        .font(.system(size: 24, weight: .bold, design: theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(theme.trackNameStyle))
                    Text("DURATION")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(colorFor(theme.trackNameStyle, opacity: 0.55))
                }
            }
            .padding(.horizontal, 4)

            // Bottom Track Bar Container
            HStack(spacing: 10) {
                if theme.flipHorizontal {
                    if theme.showPlaybackControls && (theme.controlsPlacement == .inlineWithText || hoverState.isHovered) {
                        timeDashboardControls
                    }
                    timeDashboardTextStack
                    Spacer()
                    posterThumbnail(size: 42, cornerRadius: 8)
                } else {
                    posterThumbnail(size: 42, cornerRadius: 8)
                    timeDashboardTextStack
                    Spacer()
                    if theme.showPlaybackControls && (theme.controlsPlacement == .inlineWithText || hoverState.isHovered) {
                        timeDashboardControls
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .frame(width: max(320, theme.containerWidth))
    }

    @ViewBuilder
    private var timeDashboardTextStack: some View {
        VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 2) {
            if theme.trackNameStyle.isVisible {
                Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                    .font(fontFor(theme.trackNameStyle, defaultSize: 13))
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

            let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
            let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
            if showArtist || showAlbum {
                HStack(spacing: 4) {
                    if showArtist {
                        Text(coordinator.currentTrack.artist.uppercased())
                            .font(fontFor(theme.artistStyle, defaultSize: 9))
                            .foregroundColor(colorFor(theme.artistStyle, opacity: 0.75))
                            .lineLimit(1)
                            .shadow(
                                color: Color.black.opacity(theme.artistStyle.shadow.opacity),
                                radius: theme.artistStyle.shadow.radius,
                                x: 0,
                                y: theme.artistStyle.shadow.yOffset
                            )
                    }
                    if showArtist && showAlbum {
                        Text("—")
                            .font(fontFor(theme.albumStyle, defaultSize: 9))
                            .foregroundColor(colorFor(theme.albumStyle, opacity: 0.45))
                    }
                    if showAlbum {
                        Text(coordinator.currentTrack.album.uppercased())
                            .font(fontFor(theme.albumStyle, defaultSize: 9))
                            .foregroundColor(colorFor(theme.albumStyle, opacity: 0.65))
                            .lineLimit(1)
                            .shadow(
                                color: Color.black.opacity(theme.albumStyle.shadow.opacity),
                                radius: theme.albumStyle.shadow.radius,
                                x: 0,
                                y: theme.albumStyle.shadow.yOffset
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timeDashboardControls: some View {
        HStack(spacing: theme.controlsSize.buttonPadding) {
            let iconSize = theme.controlsSize.iconSize * 0.85
            let btnSize = max(24, iconSize * 2.1)

            Button(action: { coordinator.togglePlayPause() }) {
                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundColor(buttonColor)
                    .frame(width: btnSize, height: btnSize)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.14)))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { coordinator.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundColor(buttonColor)
                    .frame(width: btnSize, height: btnSize)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.14)))
            }
            .buttonStyle(PlainButtonStyle())

            if theme.showLikeControl {
                Button(action: { controlsState.isLiked.toggle() }) {
                    Image(systemName: controlsState.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(controlsState.isLiked ? Color.red : buttonColor)
                        .frame(width: btnSize, height: btnSize)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.14)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .transition(.opacity)
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
                        SleeveControlsView(coordinator: coordinator, theme: theme, isOverlay: true)
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

                HStack(spacing: theme.controlsSize.buttonPadding) {
                    let iconSize = theme.controlsSize.iconSize * 0.85
                    let btnWidth = max(26, iconSize * 2.3)
                    let btnHeight = max(22, iconSize * 2.0)

                    Button(action: { coordinator.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(buttonColor)
                            .frame(width: btnWidth, height: btnHeight)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: iconSize * 1.1, weight: .bold))
                            .foregroundColor(buttonColor)
                            .frame(width: btnWidth, height: btnHeight)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { coordinator.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(buttonColor)
                            .frame(width: btnWidth, height: btnHeight)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    if theme.showLikeControl {
                        Button(action: { controlsState.isLiked.toggle() }) {
                            Image(systemName: controlsState.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: iconSize, weight: .medium))
                                .foregroundColor(controlsState.isLiked ? Color.red : buttonColor)
                                .frame(width: btnWidth, height: btnHeight)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignmentForTheme)
    }

    @ViewBuilder
    private var compactSquareLayout: some View {
        VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 8) {
            // Square poster thumbnail aligned symmetrically from top and leading (12pt from each edge)
            posterThumbnail(size: 44, cornerRadius: 8)

            VStack(alignment: theme.horizontalAlign.horizontalAlignment, spacing: 2) {
                if theme.trackNameStyle.isVisible {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(fontFor(theme.trackNameStyle, defaultSize: 12))
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

                let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
                let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
                if showArtist || showAlbum {
                    let sub = (showArtist ? coordinator.currentTrack.artist : "") + (showArtist && showAlbum ? " — " : "") + (showAlbum ? coordinator.currentTrack.album : "")
                    Text(sub)
                        .font(fontFor(theme.artistStyle, defaultSize: 10))
                        .foregroundColor(colorFor(theme.artistStyle, opacity: 0.65))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: Color.black.opacity(theme.artistStyle.shadow.opacity),
                            radius: theme.artistStyle.shadow.radius,
                            x: 0,
                            y: theme.artistStyle.shadow.yOffset
                        )
                }
            }

            // Controls
            if theme.showPlaybackControls {
                let isVisible = theme.controlsPlacement == .inlineWithText || hoverState.isHovered
                if isVisible {
                    let iconSize = theme.controlsSize.iconSize * 0.75
                    HStack(spacing: theme.controlsSize.buttonPadding) {
                        Button(action: { coordinator.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: iconSize))
                                .foregroundColor(buttonColor)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { coordinator.togglePlayPause() }) {
                            Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: iconSize * 1.15, weight: .bold))
                                .foregroundColor(buttonColor)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { coordinator.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: iconSize))
                                .foregroundColor(buttonColor)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if theme.showLikeControl {
                            Button(action: { controlsState.isLiked.toggle() }) {
                                Image(systemName: controlsState.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: iconSize))
                                    .foregroundColor(controlsState.isLiked ? Color.red : buttonColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(width: max(128, theme.containerWidth))
    }

    @ViewBuilder
    private var artworkPosterLayout: some View {
        let posterDim = max(240, theme.artworkSize > 0 ? theme.artworkSize : 300)
        ZStack(alignment: .bottom) {
            // Full background poster image
            posterThumbnail(size: posterDim, cornerRadius: theme.cornerRadius)

            // Gradient shadow on bottom half for high text readability
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))

            // Overlaid typography & floating controls
            VStack(spacing: 8) {
                if theme.trackNameStyle.isVisible {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(fontFor(theme.trackNameStyle, defaultSize: 18))
                        .foregroundColor(colorFor(theme.trackNameStyle))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(2)
                        .shadow(
                            color: Color.black.opacity(max(0.4, theme.trackNameStyle.shadow.opacity)),
                            radius: max(4, theme.trackNameStyle.shadow.radius),
                            x: 0,
                            y: max(2, theme.trackNameStyle.shadow.yOffset)
                        )
                }

                let showArtist = theme.artistStyle.isVisible && !coordinator.currentTrack.artist.isEmpty
                let showAlbum = theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty
                if showArtist || showAlbum {
                    let sub = (showArtist ? coordinator.currentTrack.artist : "") + (showArtist && showAlbum ? " — " : "") + (showAlbum ? coordinator.currentTrack.album : "")
                    Text(sub)
                        .font(fontFor(theme.artistStyle, defaultSize: 12))
                        .foregroundColor(colorFor(theme.artistStyle, opacity: 0.85))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: Color.black.opacity(max(0.3, theme.artistStyle.shadow.opacity)),
                            radius: max(3, theme.artistStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.artistStyle.shadow.yOffset)
                        )
                }

                // Translucent floating controls
                if theme.showPlaybackControls {
                    let isVisible = theme.controlsPlacement == .inlineWithText || hoverState.isHovered
                    if isVisible {
                        let iconSize = theme.controlsSize.iconSize
                        let circleSize = iconSize * 2.4
                        let playCircleSize = iconSize * 2.8

                        HStack(spacing: theme.controlsSize.buttonPadding * 1.5) {
                            Button(action: { coordinator.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: iconSize))
                                    .foregroundColor(.white)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(Color.black.opacity(0.35)))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.togglePlayPause() }) {
                                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: iconSize * 1.2, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: playCircleSize, height: playCircleSize)
                                    .background(Circle().fill(Color.black.opacity(0.45)))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: iconSize))
                                    .foregroundColor(.white)
                                    .frame(width: circleSize, height: circleSize)
                                    .background(Circle().fill(Color.black.opacity(0.35)))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if theme.showLikeControl {
                                Button(action: { controlsState.isLiked.toggle() }) {
                                    Image(systemName: controlsState.isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: iconSize, weight: .medium))
                                        .foregroundColor(controlsState.isLiked ? Color.red : .white)
                                        .frame(width: circleSize, height: circleSize)
                                        .background(Circle().fill(Color.black.opacity(0.35)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: posterDim, height: posterDim)
    }

    @ViewBuilder
    private var artworkCardLayout: some View {
        let cardDim = max(130, min(220, theme.artworkSize > 0 ? theme.artworkSize : 150))
        ZStack {
            // Full background poster image
            posterThumbnail(size: cardDim, cornerRadius: theme.cornerRadius)

            // Subtle dark overlay for contrast
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.35))

            // Overlaid centered info and controls
            VStack(spacing: 6) {
                if theme.trackNameStyle.isVisible {
                    Text(coordinator.currentTrack.title.isEmpty ? "No Track Playing" : coordinator.currentTrack.title)
                        .font(fontFor(theme.trackNameStyle, defaultSize: 14))
                        .foregroundColor(colorFor(theme.trackNameStyle))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: Color.black.opacity(max(0.4, theme.trackNameStyle.shadow.opacity)),
                            radius: max(4, theme.trackNameStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.trackNameStyle.shadow.yOffset)
                        )
                }

                if theme.artistStyle.isVisible {
                    Text(coordinator.currentTrack.artist.isEmpty ? "Unknown" : coordinator.currentTrack.artist)
                        .font(fontFor(theme.artistStyle, defaultSize: 11))
                        .foregroundColor(colorFor(theme.artistStyle, opacity: 0.85))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: Color.black.opacity(max(0.3, theme.artistStyle.shadow.opacity)),
                            radius: max(3, theme.artistStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.artistStyle.shadow.yOffset)
                        )
                }

                if theme.albumStyle.isVisible && !coordinator.currentTrack.album.isEmpty {
                    Text(coordinator.currentTrack.album)
                        .font(fontFor(theme.albumStyle, defaultSize: 10))
                        .foregroundColor(colorFor(theme.albumStyle, opacity: 0.70))
                        .multilineTextAlignment(theme.horizontalAlign.textAlignment)
                        .lineLimit(1)
                        .shadow(
                            color: Color.black.opacity(max(0.3, theme.albumStyle.shadow.opacity)),
                            radius: max(3, theme.albumStyle.shadow.radius),
                            x: 0,
                            y: max(1, theme.albumStyle.shadow.yOffset)
                        )
                }

                if theme.showPlaybackControls {
                    let isVisible = theme.controlsPlacement == .inlineWithText || hoverState.isHovered
                    if isVisible {
                        let iconSize = theme.controlsSize.iconSize * 0.8
                        HStack(spacing: theme.controlsSize.buttonPadding) {
                            Button(action: { coordinator.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: iconSize))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.togglePlayPause() }) {
                                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: iconSize * 1.15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { coordinator.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: iconSize))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if theme.showLikeControl {
                                Button(action: { controlsState.isLiked.toggle() }) {
                                    Image(systemName: controlsState.isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: iconSize, weight: .medium))
                                        .foregroundColor(controlsState.isLiked ? Color.red : .white)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                    }
                }
            }
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
