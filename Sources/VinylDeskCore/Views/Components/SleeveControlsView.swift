import SwiftUI

public struct SleeveControlsView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: SleeveThemeConfig
    var isOverlay: Bool = false
    @StateObject private var state = SleeveControlsState()

    @MainActor
    public init(
        coordinator: MusicCoordinator,
        theme: SleeveThemeConfig,
        isOverlay: Bool = false
    ) {
        self.coordinator = coordinator
        self.theme = theme
        self.isOverlay = isOverlay
    }

    public var body: some View {
        HStack(spacing: theme.controlsSize.buttonPadding) {
            // Previous Button
            Button(action: {
                coordinator.previousTrack()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: theme.controlsSize.iconSize, weight: .semibold))
                    .foregroundColor(buttonColor)
            }
            .buttonStyle(PlainButtonStyle())

            // Play/Pause Button
            Button(action: {
                coordinator.togglePlayPause()
            }) {
                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: theme.controlsSize.iconSize * 1.25, weight: .bold))
                    .foregroundColor(buttonColor)
                    .frame(width: theme.controlsSize.iconSize * 1.8, height: theme.controlsSize.iconSize * 1.8)
                    .background(
                        isOverlay ? Color.white.opacity(0.18) : Color.primary.opacity(0.10)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())

            // Next Button
            Button(action: {
                coordinator.nextTrack()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: theme.controlsSize.iconSize, weight: .semibold))
                    .foregroundColor(buttonColor)
            }
            .buttonStyle(PlainButtonStyle())

            // Like / Favorite Button
            if theme.showLikeControl {
                Button(action: {
                    state.isLiked.toggle()
                }) {
                    Image(systemName: state.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: theme.controlsSize.iconSize, weight: .medium))
                        .foregroundColor(state.isLiked ? Color.red : buttonColor.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Group {
                if !isOverlay && theme.backdropMaterial == .clear {
                    Capsule()
                        .fill(Color.black.opacity(0.20))
                }
            }
        )
    }

    private var buttonColor: Color {
        if isOverlay {
            return .white
        }
        return .primary
    }
}
