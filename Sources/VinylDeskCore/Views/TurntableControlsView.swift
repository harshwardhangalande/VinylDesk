import SwiftUI

@MainActor
public final class ControlsState: ObservableObject {
    @Published public var isCrackleActive: Bool = true
    @Published public var showThemePicker: Bool = false
    public init() {}
}

public struct TurntableControlsView: View {
    @ObservedObject var coordinator: MusicCoordinator
    @ObservedObject var themeManager: ThemeManager
    @StateObject private var state = ControlsState()

    public init(coordinator: MusicCoordinator, themeManager: ThemeManager) {
        self.coordinator = coordinator
        self.themeManager = themeManager
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Track Info Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(coordinator.currentTrack.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(coordinator.currentTrack.artist)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(1)

                        Text("•")
                            .foregroundColor(Color.white.opacity(0.4))

                        Text(coordinator.currentTrack.source.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(sourceColor.opacity(0.25))
                            .foregroundColor(sourceColor)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Time Display
                Text("\(coordinator.currentTrack.formattedPosition) / \(coordinator.currentTrack.formattedDuration)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Scrub Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(themeManager.currentTheme.accentGlow)
                        .frame(width: geo.size.width * coordinator.currentTrack.progress, height: 3)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = max(0, min(value.location.x / geo.size.width, 1.0))
                            coordinator.seek(to: fraction)
                        }
                )
            }
            .frame(height: 4)
            .padding(.horizontal, 14)

            // Bottom Physical Control Deck
            HStack(spacing: 16) {
                // Power LED & 33/45 RPM Selector
                HStack(spacing: 8) {
                    Circle()
                        .fill(coordinator.currentTrack.isPlaying ? Color.green : Color.red.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .shadow(color: coordinator.currentTrack.isPlaying ? Color.green : Color.clear, radius: 4)

                    Button(action: {
                        themeManager.rpmSpeed = (themeManager.rpmSpeed == 33) ? 45 : 33
                    }) {
                        Text("\(themeManager.rpmSpeed) RPM")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Playback Transport Buttons
                HStack(spacing: 14) {
                    Button(action: {
                        coordinator.previousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        SoundFXEngine.shared.playNeedleDrop()
                        coordinator.togglePlayPause()
                        if coordinator.currentTrack.isPlaying {
                            SoundFXEngine.shared.startCrackle()
                        } else {
                            SoundFXEngine.shared.stopCrackle()
                        }
                    }) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.35), Color(white: 0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: coordinator.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        coordinator.nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Vinyl Crackle Toggle & Theme Menu
                HStack(spacing: 10) {
                    Button(action: {
                        state.isCrackleActive.toggle()
                        SoundFXEngine.shared.isCrackleEnabled = state.isCrackleActive
                    }) {
                        Image(systemName: state.isCrackleActive ? "waveform.badge.magnifyingglass" : "waveform.slash")
                            .font(.system(size: 11))
                            .foregroundColor(state.isCrackleActive ? .orange : .white.opacity(0.4))
                            .help(state.isCrackleActive ? "Analog Vinyl Crackle: ON" : "Analog Vinyl Crackle: OFF")
                    }
                    .buttonStyle(.plain)

                    Menu {
                        ForEach(TurntableTheme.allCases) { theme in
                            Button(action: {
                                themeManager.selectTheme(theme)
                            }) {
                                HStack {
                                    Text(theme.rawValue)
                                    if theme.isPro && !themeManager.isProUnlocked {
                                        Text("(PRO)")
                                    }
                                    if themeManager.currentTheme == theme {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        Divider()

                        if !themeManager.isProUnlocked {
                            Button("Unlock Pro ($7.99)...") {
                                themeManager.showLicenseModal = true
                            }
                        } else {
                            Text("✓ VinylDesk Pro Active")
                        }
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
    }

    private var sourceColor: Color {
        switch coordinator.currentTrack.source {
        case .spotify, .spotifyWeb:
            return Color.green
        case .appleMusic, .appleMusicWeb:
            return Color.pink
        case .none:
            return Color.secondary
        }
    }
}
