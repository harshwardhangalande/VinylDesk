import SwiftUI
import AppKit

// MARK: - AppKit Visual Effect Representable

public struct VisualEffectViewRepresentable: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    public init(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Artwork Dominant Color Extractor

public enum ArtworkColorExtractor {
    public static func dominantColor(from data: Data?) -> Color? {
        guard let data = data, let image = NSImage(data: data) else { return nil }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let ctx = context else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let pixelBuffer = ctx.data else { return nil }
        let pixel = pixelBuffer.bindMemory(to: UInt8.self, capacity: 4)
        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Liquid Glass Backdrop View

public struct LiquidGlassBackdropView: View {
    let theme: SleeveThemeConfig
    @ObservedObject var coordinator: MusicCoordinator
    var isLightBackground: Bool
    @StateObject private var shimmerState = LiquidShimmerState()

    @MainActor
    public init(
        theme: SleeveThemeConfig,
        coordinator: MusicCoordinator,
        isLightBackground: Bool = false
    ) {
        self.theme = theme
        self.coordinator = coordinator
        self.isLightBackground = isLightBackground
    }

    public var body: some View {
        let cornerRadius = theme.backdropCornerRadius
        let clipShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            // 1. Native macOS Behind-Window Hardware Visual Effect
            VisualEffectViewRepresentable(
                material: theme.liquidGlassLevel.visualEffectMaterial,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(clipShape)

            // 2. Translucent Base Glass Tint
            clipShape
                .fill(baseTintFill)

            // 3. Dynamic Fluid / Chromatic Tint Layer
            dynamicTintLayer
                .clipShape(clipShape)

            // 4. Liquid Caustic Refraction Glow (Top-Left Specular Surface)
            LinearGradient(
                colors: [
                    Color.white.opacity(effectiveRimShine * 0.45),
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
            .clipShape(clipShape)

            // 5. Breathing Living Shimmer (When Playing & Enabled)
            if theme.liquidGlassFluidPulse && coordinator.currentTrack.isPlaying {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.12 + shimmerState.shimmerPhase * 0.12),
                        Color.clear
                    ],
                    startPoint: UnitPoint(x: -0.2 + shimmerState.shimmerPhase * 1.4, y: 0),
                    endPoint: UnitPoint(x: 0.2 + shimmerState.shimmerPhase * 1.4, y: 1)
                )
                .clipShape(clipShape)
            }

            // 6. Dual-Tone Polished Specular Rim & Beveled Stroke
            clipShape
                .stroke(specularBorderGradient, lineWidth: strokeWidth)

            // 7. Prismatic Edge Accent (If Prismatic mode active)
            if theme.liquidGlassTint == .prismatic {
                clipShape
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.cyan.opacity(0.5),
                                Color.purple.opacity(0.5),
                                Color.pink.opacity(0.5),
                                Color.orange.opacity(0.4),
                                Color.cyan.opacity(0.5)
                            ],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 1)
            }
        }
        .shadow(
            color: Color.black.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 0,
            y: shadowYOffset
        )
        .onAppear {
            if theme.liquidGlassFluidPulse {
                withAnimation(
                    .easeInOut(duration: 4.5)
                    .repeatForever(autoreverses: true)
                ) {
                    shimmerState.shimmerPhase = 1.0
                }
            }
        }
    }

    // MARK: - Effective Values

    private var effectiveOpacity: CGFloat {
        if theme.liquidGlassCustomOpacity > 0.01 {
            return theme.liquidGlassCustomOpacity
        }
        return theme.liquidGlassLevel.baseOpacity
    }

    private var effectiveRimShine: CGFloat {
        if theme.liquidGlassRimShine > 0.01 {
            return theme.liquidGlassRimShine
        }
        return theme.liquidGlassLevel.rimShine
    }

    private var strokeWidth: CGFloat {
        switch theme.liquidGlassLevel {
        case .ultra: return 1.5
        case .high: return 1.2
        default: return 1.0
        }
    }

    private var shadowOpacity: Double {
        switch theme.liquidGlassLevel {
        case .low: return 0.15
        case .medium: return 0.25
        case .high: return 0.35
        case .ultra: return 0.45
        case .system:
            return isLightBackground ? 0.18 : 0.30
        }
    }

    private var shadowRadius: CGFloat {
        switch theme.liquidGlassLevel {
        case .low: return 8
        case .medium: return 14
        case .high: return 22
        case .ultra: return 32
        case .system: return 16
        }
    }

    private var shadowYOffset: CGFloat {
        switch theme.liquidGlassLevel {
        case .low: return 4
        case .medium: return 8
        case .high: return 12
        case .ultra: return 16
        case .system: return 8
        }
    }

    // MARK: - Tint & Color Calculations

    private var baseTintFill: Color {
        if isLightBackground {
            return Color.white.opacity(effectiveOpacity * 0.85)
        } else {
            return Color(white: 0.08).opacity(effectiveOpacity)
        }
    }

    @ViewBuilder
    private var dynamicTintLayer: some View {
        switch theme.liquidGlassTint {
        case .neutral:
            EmptyView()

        case .albumArt:
            if let artworkColor = ArtworkColorExtractor.dominantColor(from: coordinator.currentTrack.artworkData) {
                LinearGradient(
                    colors: [
                        artworkColor.opacity(0.30),
                        artworkColor.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.18),
                        Color.purple.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

        case .systemAccent:
            Color(nsColor: .controlAccentColor)
                .opacity(0.18)

        case .prismatic:
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.18),
                    Color.purple.opacity(0.14),
                    Color.pink.opacity(0.12),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var specularBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(effectiveRimShine),
                Color.white.opacity(effectiveRimShine * 0.20),
                Color.white.opacity(effectiveRimShine * 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
