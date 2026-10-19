import SwiftUI

@MainActor
public final class VUMeterState: ObservableObject {
    @Published public var needlePosition: Double = 0.05 // 0.0 (-20dB) to 1.0 (+3dB)
    public init() {}
}

public struct VUMeterView: View {
    @ObservedObject var coordinator: MusicCoordinator
    @ObservedObject var themeManager: ThemeManager
    @StateObject private var state = VUMeterState()

    let channelName: String

    public init(coordinator: MusicCoordinator, themeManager: ThemeManager, channelName: String = "L") {
        self.coordinator = coordinator
        self.themeManager = themeManager
        self.channelName = channelName
    }

    // Needle deflection angle: from -38 degrees (-20dB) to +38 degrees (+3dB)
    private var needleAngle: Double {
        let minAngle = -38.0
        let maxAngle = 38.0
        return minAngle + (state.needlePosition * (maxAngle - minAngle))
    }

    public var body: some View {
        ZStack {
            // Dial Faceplate Background
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.96, green: 0.93, blue: 0.82), Color(red: 0.88, green: 0.82, blue: 0.68)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Vintage Backlit Glow
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(themeManager.currentTheme.accentGlow, lineWidth: 1.5)
                        .blur(radius: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1.5)

            // Scale Markings & Text
            VStack {
                HStack {
                    Text(channelName)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.black.opacity(0.6))
                    Spacer()
                    Text("VU")
                        .font(.system(size: 9, weight: .black, design: .serif))
                        .foregroundColor(Color.black.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                Spacer()

                // dB scale arc representation
                HStack(spacing: 6) {
                    Text("-20")
                    Text("-10")
                    Text("-5")
                    Text("0")
                        .foregroundColor(.red)
                    Text("+3")
                        .foregroundColor(.red)
                }
                .font(.system(size: 6, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.black.opacity(0.75))
                .padding(.bottom, 6)
            }

            // Moving Needle
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color(white: 0.15))
                    .frame(width: 1.2, height: 26)
                    .rotationEffect(.degrees(needleAngle), anchor: .bottom)
                    .animation(.interpolatingSpring(stiffness: 180, damping: 14), value: needleAngle)

                // Pivot Cap
                Circle()
                    .fill(Color(white: 0.2))
                    .frame(width: 8, height: 8)
                    .offset(y: 2)
            }
        }
        .frame(width: 85, height: 42)
        .onReceive(Timer.publish(every: 1.0 / 24.0, on: .main, in: .common).autoconnect()) { _ in
            if coordinator.currentTrack.isPlaying {
                // Simulate rhythmic audio level bounce
                let base = 0.45
                let bounce = Double.random(in: -0.25...0.35)
                state.needlePosition = max(0.05, min(0.95, base + bounce))
            } else {
                state.needlePosition = 0.05
            }
        }
    }
}
