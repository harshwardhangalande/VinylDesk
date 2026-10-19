import SwiftUI
import AppKit

public struct VinylArtworkView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: VinylThemeConfig
    var isHovered: Bool = false
    var onHoverChanged: ((Bool) -> Void)? = nil

    @StateObject private var state = ArtworkState()

    @MainActor
    public init(
        coordinator: MusicCoordinator,
        theme: VinylThemeConfig,
        isHovered: Bool = false,
        onHoverChanged: ((Bool) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.theme = theme
        self.isHovered = isHovered
        self.onHoverChanged = onHoverChanged
    }

    public var body: some View {
        if theme.layout == .woodenShelf {
            shelfArtworkPresentation
        } else if theme.layout == .vintageVinyl || theme.showSpinningRecord {
            vinylArtworkPresentation
        } else {
            standardArtworkPresentation
        }
    }

    // MARK: - Standard Artwork

    @ViewBuilder
    private var standardArtworkPresentation: some View {
        ZStack {
            albumCoverImage
                .frame(width: theme.artworkSize, height: theme.artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
                .overlay(lightingOverlay)
                .shadow(
                    color: Color.black.opacity(theme.artworkShadow.opacity),
                    radius: theme.artworkShadow.radius,
                    x: 0,
                    y: theme.artworkShadow.yOffset
                )

            // On-hover controls overlay
            if theme.showPlaybackControls && theme.controlsPlacement == .onHover && isHovered {
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .frame(width: theme.artworkSize, height: theme.artworkSize)
                    .overlay(
                        VinylControlsView(coordinator: coordinator, theme: theme, isOverlay: true)
                    )
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            onHoverChanged?(hovering)
        }
    }

    // MARK: - Retro Vinyl Presentation

    @ViewBuilder
    private var vinylArtworkPresentation: some View {
        HStack(spacing: -theme.artworkSize * 0.42) {
            // Album Vinyl Jacket
            ZStack {
                albumCoverImage
                    .frame(width: theme.artworkSize, height: theme.artworkSize)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
                    .overlay(lightingOverlay)
                    .overlay(
                        // Vinyl spine & worn edge effect
                        RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(theme.artworkShadow.opacity),
                        radius: theme.artworkShadow.radius,
                        x: 0,
                        y: theme.artworkShadow.yOffset
                    )

                if theme.showPlaybackControls && theme.controlsPlacement == .onHover && isHovered {
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: theme.artworkSize, height: theme.artworkSize)
                        .overlay(
                            VinylControlsView(coordinator: coordinator, theme: theme, isOverlay: true)
                        )
                        .transition(.opacity)
                }
            }
            .zIndex(2)

            // Spinning Vinyl Disc Extruding from Vinyl
            ZStack {
                // Vinyl outer body
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.14),
                                Color(white: 0.08),
                                Color(white: 0.03)
                            ]),
                            center: .center,
                            startRadius: theme.artworkSize * 0.1,
                            endRadius: theme.artworkSize * 0.48
                        )
                    )
                    .frame(width: theme.artworkSize * 0.94, height: theme.artworkSize * 0.94)

                // Vinyl sound grooves
                ForEach(1...4, id: \.self) { ring in
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(
                            width: theme.artworkSize * (0.35 + CGFloat(ring) * 0.12),
                            height: theme.artworkSize * (0.35 + CGFloat(ring) * 0.12)
                        )
                }

                // Vinyl light specular reflection
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.12),
                        Color.clear,
                        Color.white.opacity(0.08),
                        Color.clear,
                        Color.white.opacity(0.12)
                    ]),
                    center: .center
                )
                .mask(Circle())
                .frame(width: theme.artworkSize * 0.94, height: theme.artworkSize * 0.94)

                // Center Label
                ZStack {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.35, blue: 0.25))
                        .frame(width: theme.artworkSize * 0.34, height: theme.artworkSize * 0.34)

                    albumCoverImage
                        .frame(width: theme.artworkSize * 0.24, height: theme.artworkSize * 0.24)
                        .clipShape(Circle())

                    // Spindle hole
                    Circle()
                        .fill(Color.black)
                        .frame(width: theme.artworkSize * 0.07, height: theme.artworkSize * 0.07)
                }
            }
            .rotationEffect(.degrees(state.rotationAngle))
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 6, y: 4)
            .zIndex(1)
        }
        .onHover { hovering in
            onHoverChanged?(hovering)
        }
        .onAppear {
            startRotationAnimation()
        }
        .onChange(of: coordinator.currentTrack.isPlaying) { _, isPlaying in
            if isPlaying {
                startRotationAnimation()
            }
        }
    }

    // MARK: - Wooden Shelf Presentation

    @ViewBuilder
    private var shelfArtworkPresentation: some View {
        VStack(spacing: -6) {
            ZStack {
                albumCoverImage
                    .frame(width: theme.artworkSize, height: theme.artworkSize)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
                    .overlay(lightingOverlay)
                    .shadow(
                        color: Color.black.opacity(theme.artworkShadow.opacity),
                        radius: theme.artworkShadow.radius,
                        x: 0,
                        y: theme.artworkShadow.yOffset
                    )

                if theme.showPlaybackControls && theme.controlsPlacement == .onHover && isHovered {
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: theme.artworkSize, height: theme.artworkSize)
                        .overlay(
                            VinylControlsView(coordinator: coordinator, theme: theme, isOverlay: true)
                        )
                        .transition(.opacity)
                }
            }
            .zIndex(2)

            // Wooden Shelf / Stand Plinth
            ZStack(alignment: .top) {
                // Shelf Base
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(shelfFill)
                    .frame(width: theme.artworkSize + 36, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 6)

                // Shelf groove indentation
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.45))
                    .frame(width: theme.artworkSize + 14, height: 3)
                    .padding(.top, 2)
            }
            .zIndex(1)
        }
        .onHover { hovering in
            onHoverChanged?(hovering)
        }
    }

    private var shelfFill: LinearGradient {
        switch theme.shelfFinish {
        case .lightOak:
            return LinearGradient(
                colors: [Color(red: 0.82, green: 0.68, blue: 0.50), Color(red: 0.65, green: 0.50, blue: 0.34)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .darkWalnut:
            return LinearGradient(
                colors: [Color(red: 0.38, green: 0.22, blue: 0.14), Color(red: 0.24, green: 0.13, blue: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .matteBlack:
            return LinearGradient(
                colors: [Color(white: 0.22), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .neonAcrylic:
            return LinearGradient(
                colors: [Color.cyan.opacity(0.85), Color.blue.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Album Image & Lighting

    @ViewBuilder
    private var albumCoverImage: some View {
        if let nsImage = ArtworkCache.shared.image(
            for: coordinator.currentTrack.id,
            data: coordinator.currentTrack.artworkData,
            maxDimension: max(160, theme.artworkSize * 2)
        ) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.25, blue: 0.45),
                        Color(red: 0.08, green: 0.10, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: theme.artworkSize * 0.26))
                        .foregroundColor(.white.opacity(0.75))

                    Text(coordinator.currentTrack.artist)
                        .font(.system(size: max(9, theme.artworkSize * 0.08), weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                }
            }
        }
    }

    @ViewBuilder
    private var lightingOverlay: some View {
        switch theme.lightingEffect {
        case .none:
            EmptyView()
        case .spotlight:
            RadialGradient(
                colors: [Color.white.opacity(0.32), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: theme.artworkSize * 1.1
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        case .glare:
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.24), location: 0.0),
                    .init(color: Color.white.opacity(0.08), location: 0.42),
                    .init(color: Color.clear, location: 0.44),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        }
    }

    private func startRotationAnimation() {
        guard coordinator.currentTrack.isPlaying else { return }
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            state.rotationAngle += 360
        }
    }
}
