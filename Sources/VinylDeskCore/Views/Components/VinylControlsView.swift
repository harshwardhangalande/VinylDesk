import SwiftUI

public struct VinylControlsView: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: VinylThemeConfig
    var isOverlay: Bool = false
    @StateObject private var state = VinylControlsState()

    @MainActor
    public init(
        coordinator: MusicCoordinator,
        theme: VinylThemeConfig,
        isOverlay: Bool = false
    ) {
        self.coordinator = coordinator
        self.theme = theme
        self.isOverlay = isOverlay
    }

    public var body: some View {
        let iconSize = theme.controlsSize.iconSize
        let circleSize = iconSize * 1.9
        let playCircleSize = iconSize * 2.1
        let circleBg = isOverlay ? Color.white.opacity(0.24) : Color.primary.opacity(0.12)
        let fgColor = isOverlay ? Color.white : Color.primary

        HStack(spacing: theme.controlsSize.buttonPadding) {
            // Previous Button
            Button(action: {
                coordinator.previousTrack()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: iconSize * 0.9, weight: .semibold))
                    .foregroundColor(fgColor)
                    .frame(width: circleSize, height: circleSize)
                    .background(isOverlay ? Circle().fill(circleBg) : nil)
            }
            .buttonStyle(PlainButtonStyle())

            // Play/Pause Button
            Button(action: {
                coordinator.togglePlayPause()
            }) {
                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: iconSize * 1.15, weight: .bold))
                    .foregroundColor(fgColor)
                    .frame(width: playCircleSize, height: playCircleSize)
                    .background(Circle().fill(circleBg))
            }
            .buttonStyle(PlainButtonStyle())

            // Next Button
            Button(action: {
                coordinator.nextTrack()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: iconSize * 0.9, weight: .semibold))
                    .foregroundColor(fgColor)
                    .frame(width: circleSize, height: circleSize)
                    .background(isOverlay ? Circle().fill(circleBg) : nil)
            }
            .buttonStyle(PlainButtonStyle())
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
