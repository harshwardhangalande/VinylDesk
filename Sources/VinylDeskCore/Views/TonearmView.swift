import SwiftUI

public struct TonearmView: View {
    @ObservedObject var coordinator: MusicCoordinator
    @ObservedObject var themeManager: ThemeManager

    let height: CGFloat

    public init(coordinator: MusicCoordinator, themeManager: ThemeManager, height: CGFloat = 240) {
        self.coordinator = coordinator
        self.themeManager = themeManager
        self.height = height
    }

    // Calculated tonearm rotation angle based on playback state and track progress
    private var targetAngle: Double {
        if !coordinator.currentTrack.isPlaying {
            return -6.0 // Rest cradle position
        } else {
            let leadIn = 17.0
            let runOut = 37.0
            let progress = coordinator.currentTrack.progress
            return leadIn + (progress * (runOut - leadIn))
        }
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Cradle rest post (stationary)
            VStack(spacing: 0) {
                Spacer().frame(height: 70)
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.25))
                        .frame(width: 8, height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(Color(white: 0.4), lineWidth: 1)
                        )
                    Spacer()
                }
                .frame(width: 60)
            }

            // Pivot Gimbal Base (Stationary)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.35), Color(white: 0.15)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)

                Circle()
                    .stroke(themeManager.currentTheme.tonearmMetalColor, lineWidth: 2)
                    .frame(width: 44, height: 44)

                // Anti-skate dial knob
                Circle()
                    .fill(Color(white: 0.45))
                    .frame(width: 14, height: 14)
            }

            // The Rotating Arm Assembly
            ZStack(alignment: .top) {
                // Top Counterweight (extending backward from pivot)
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.2), Color(white: 0.1), Color(white: 0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 22, height: 28)
                    .offset(y: -22)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)

                // Arm Tube (Curved / Angled metallic tube)
                VStack(spacing: 0) {
                    // Pivot collar
                    Circle()
                        .fill(themeManager.currentTheme.tonearmMetalColor)
                        .frame(width: 16, height: 16)

                    // Straight / S-curve arm rod
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.tonearmMetalColor.opacity(0.8),
                                    themeManager.currentTheme.tonearmMetalColor,
                                    themeManager.currentTheme.tonearmMetalColor.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 4.5, height: height * 0.70)

                    // Cartridge & Headshell (Angled stylus cartridge)
                    ZStack(alignment: .topLeading) {
                        // Headshell
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.22), Color(white: 0.12)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 14, height: 26)
                            .rotationEffect(.degrees(18))

                        // Stylus needle tip
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 3.5, height: 3.5)
                            .offset(x: -3, y: 24)
                    }
                    .shadow(color: .black.opacity(0.4), radius: 4, x: -2, y: 2)
                }
            }
            .rotationEffect(.degrees(targetAngle), anchor: .top)
            .animation(.spring(response: 0.75, dampingFraction: 0.78), value: targetAngle)
            .onTapGesture {
                SoundFXEngine.shared.playNeedleDrop()
                coordinator.togglePlayPause()
            }
        }
        .frame(width: 70, height: height)
    }
}
