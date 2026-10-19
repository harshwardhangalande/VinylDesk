import SwiftUI

@MainActor
public final class PlatterState: ObservableObject {
    @Published public var continuousRotation: Double = 0
    @Published public var dragStartRotation: Double = 0
    @Published public var currentDragOffset: Double = 0
    @Published public var lastDragLocation: CGPoint = .zero

    public init() {}
}

public struct VinylPlatterView: View {
    @ObservedObject var coordinator: MusicCoordinator
    @ObservedObject var themeManager: ThemeManager
    @StateObject private var state = PlatterState()

    let size: CGFloat

    public init(coordinator: MusicCoordinator, themeManager: ThemeManager, size: CGFloat = 260) {
        self.coordinator = coordinator
        self.themeManager = themeManager
        self.size = size
    }

    private var isSpinning: Bool {
        coordinator.currentTrack.isPlaying && !coordinator.isScratching
    }

    public var body: some View {
        ZStack {
            // 1. Aluminum Platter Base with Strobe Dots
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.35), Color(white: 0.20), Color(white: 0.12)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)

            // Platter rim strobe pattern
            Circle()
                .stroke(
                    style: StrokeStyle(lineWidth: 4, dash: [2, 4])
                )
                .foregroundColor(Color(white: 0.65).opacity(0.4))
                .frame(width: size - 6, height: size - 6)

            // 2. Vinyl Record Disc (Rotates)
            ZStack {
                // Vinyl body
                Circle()
                    .fill(themeManager.currentTheme.vinylColor)
                    .frame(width: size - 16, height: size - 16)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)

                // Concentric micro-grooves
                ForEach(0..<14) { index in
                    let radiusFraction = 0.40 + (Double(index) * 0.04)
                    Circle()
                        .stroke(
                            Color.white.opacity(0.04 + (Double(index % 3) * 0.02)),
                            lineWidth: 0.8
                        )
                        .frame(width: (size - 16) * radiusFraction, height: (size - 16) * radiusFraction)
                }

                // Lead-in and run-out deadwax rings
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: (size - 16) * 0.94, height: (size - 16) * 0.94)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: (size - 16) * 0.38, height: (size - 16) * 0.38)

                // Specular Light Sheen (Anisotropic reflection of light across grooves)
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.18),
                        Color.clear,
                        Color.white.opacity(0.18),
                        Color.clear,
                        Color.white.opacity(0.18),
                        Color.clear,
                        Color.white.opacity(0.18),
                        Color.clear
                    ]),
                    center: .center
                )
                .mask(
                    Circle().frame(width: size - 20, height: size - 20)
                )
                .blendMode(.screen)

                // Center Circular Album Artwork Label
                centerAlbumLabel
                    .frame(width: (size - 16) * 0.36, height: (size - 16) * 0.36)

                // Center Spindle Hole
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.8), Color(white: 0.4), Color.black],
                            center: .center,
                            startRadius: 0,
                            endRadius: 7
                        )
                    )
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color(white: 0.9), lineWidth: 1.5)
                    )
            }
            .rotationEffect(.degrees(state.continuousRotation + state.currentDragOffset))
            // Scratch / Scrub Gesture
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(value)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
        }
        .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
            if isSpinning {
                let degreesPerFrame = (360.0 / themeManager.rotationDuration) / 60.0
                state.continuousRotation = (state.continuousRotation + degreesPerFrame).truncatingRemainder(dividingBy: 360.0)
            }
        }
    }

    // MARK: - Center Album Label

    private var centerAlbumLabel: some View {
        ZStack {
            // Label background base
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.25, blue: 0.20), Color(red: 0.55, green: 0.15, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let data = coordinator.currentTrack.artworkData,
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
            } else {
                // Retro vinyl typography label
                VStack(spacing: 2) {
                    Text("VINYLDESK")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                    Text(coordinator.currentTrack.source.rawValue.uppercased())
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.yellow.opacity(0.8))
                    Text("33 ⅓ RPM")
                        .font(.system(size: 5, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Label border ring
            Circle()
                .stroke(Color.black.opacity(0.4), lineWidth: 2)
        }
    }

    // MARK: - Scratch Gesture Handling

    private func handleDrag(_ value: DragGesture.Value) {
        if !coordinator.isScratching {
            coordinator.isScratching = true
            state.dragStartRotation = state.currentDragOffset
            state.lastDragLocation = value.location
        }

        let center = CGPoint(x: size / 2, y: size / 2)
        let currentVector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
        let prevVector = CGVector(dx: state.lastDragLocation.x - center.x, dy: state.lastDragLocation.y - center.y)

        let currentAngle = atan2(currentVector.dy, currentVector.dx)
        let prevAngle = atan2(prevVector.dy, prevVector.dx)
        var angleDelta = (currentAngle - prevAngle) * 180.0 / .pi

        if angleDelta > 180 { angleDelta -= 360 }
        if angleDelta < -180 { angleDelta += 360 }

        state.currentDragOffset += angleDelta
        state.lastDragLocation = value.location

        // Play scratch sound proportional to velocity
        SoundFXEngine.shared.playScratchSound(velocity: angleDelta)

        // Scrub position slightly (1 full rotation = 1.8 seconds)
        let scrubDeltaSeconds = (angleDelta / 360.0) * themeManager.rotationDuration
        let newPos = max(0, min(coordinator.currentTrack.position + scrubDeltaSeconds, coordinator.currentTrack.duration))
        coordinator.currentTrack.position = newPos
    }

    private func handleDragEnd() {
        coordinator.isScratching = false
        // Smoothly settle drag offset into continuous rotation
        state.continuousRotation = (state.continuousRotation + state.currentDragOffset).truncatingRemainder(dividingBy: 360.0)
        state.currentDragOffset = 0
    }
}
