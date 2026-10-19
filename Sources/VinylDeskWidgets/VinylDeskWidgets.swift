import WidgetKit
import SwiftUI
import AppIntents
import VinylDeskCore

// MARK: - App Intents for Playback Control

public struct TogglePlayIntent: AppIntent {
    public static var title: LocalizedStringResource = "Play/Pause"
    public static var description = IntentDescription("Toggles music playback in Spotify or Apple Music.")

    public init() {}

    public func perform() async throws -> some IntentResult {
        // Direct script execution for immediate response
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to playpause
        else if application "Music" is running then
            tell application "Music" to playpause
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
        return .result()
    }
}

public struct NextTrackIntent: AppIntent {
    public static var title: LocalizedStringResource = "Next Track"
    public static var description = IntentDescription("Skips to the next track in Spotify or Apple Music.")

    public init() {}

    public func perform() async throws -> some IntentResult {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to next track
        else if application "Music" is running then
            tell application "Music" to next track
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
        return .result()
    }
}

public struct PreviousTrackIntent: AppIntent {
    public static var title: LocalizedStringResource = "Previous Track"
    public static var description = IntentDescription("Skips to previous track in Spotify or Apple Music.")

    public init() {}

    public func perform() async throws -> some IntentResult {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to previous track
        else if application "Music" is running then
            tell application "Music" to previous track
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
        return .result()
    }
}

// MARK: - Timeline Provider

struct VinylDeskTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrackEntry {
        TrackEntry(date: Date(), track: .fallback, artwork: nil, theme: .presetTimeDashboard)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrackEntry) -> Void) {
        let track = SharedWidgetStorage.shared.loadTrack()
        let artwork = SharedWidgetStorage.shared.loadArtwork()
        let theme = SharedWidgetStorage.shared.loadTheme()
        completion(TrackEntry(date: Date(), track: track, artwork: artwork, theme: theme))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrackEntry>) -> Void) {
        let track = SharedWidgetStorage.shared.loadTrack()
        let artwork = SharedWidgetStorage.shared.loadArtwork()
        let theme = SharedWidgetStorage.shared.loadTheme()
        let entry = TrackEntry(date: Date(), track: track, artwork: artwork, theme: theme)
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TrackEntry: TimelineEntry {
    let date: Date
    let track: SharedWidgetTrack
    let artwork: NSImage?
    let theme: VinylThemeConfig
}

// MARK: - Widget Views

struct VinylDeskWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: VinylDeskTimelineProvider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemLarge:
                largeWidgetView
            default:
                mediumWidgetView
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }

    // MARK: - Dynamic Widget Backdrop
    @ViewBuilder
    private var widgetBackground: some View {
        switch entry.theme.backdropMaterial {
        case .liquidGlass, .glass:
            ZStack {
                Color(red: 0.08, green: 0.10, blue: 0.16)
                LinearGradient(
                    colors: [Color.cyan.opacity(0.18), Color.purple.opacity(0.12), Color.black.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .blur:
            Color(white: 0.15)
        case .solid:
            Color(white: 0.10)
        case .clear:
            Color(white: 0.08)
        }
    }

    // MARK: - Typography Helpers
    private func fontFor(_ config: TypographyLineConfig, defaultSize: CGFloat) -> Font {
        let size = config.fontSize > 0 ? config.fontSize : defaultSize
        return Font.system(
            size: size,
            weight: config.fontWeight.fontWeight,
            design: config.fontDesign.fontDesign
        )
    }

    private func colorFor(_ config: TypographyLineConfig, opacity: Double = 1.0) -> Color {
        (config.isWhiteText ? Color.white : Color(white: 0.9)).opacity(opacity)
    }

    // MARK: - Lighting Effect Helper
    @ViewBuilder
    private func lightingOverlay(size: CGFloat, cornerRadius: CGFloat) -> some View {
        switch entry.theme.lightingEffect {
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

    // MARK: - Artwork View with Shadow Depth & Lighting Effects
    @ViewBuilder
    private func widgetArtwork(size: CGFloat, cornerRadius: CGFloat) -> some View {
        Group {
            if let artwork = entry.artwork {
                Image(nsImage: artwork)
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
                        .font(.system(size: size * 0.35))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(lightingOverlay(size: size, cornerRadius: cornerRadius))
        .shadow(
            color: Color.black.opacity(entry.theme.artworkShadow.opacity),
            radius: entry.theme.artworkShadow.radius,
            x: 0,
            y: entry.theme.artworkShadow.yOffset
        )
    }

    // MARK: - System Small (Compact Square)
    private var smallWidgetView: some View {
        ZStack(alignment: .bottomLeading) {
            // Full background poster filling all available space - no margin or padding
            GeometryReader { geo in
                Group {
                    if let artwork = entry.artwork {
                        Image(nsImage: artwork)
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
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(lightingOverlay(size: max(geo.size.width, geo.size.height), cornerRadius: 0))
            }

            // Dark gradient overlay for text readability at bottom
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Overlaid track info & controls
            VStack(alignment: .leading, spacing: 3) {
                if entry.theme.trackNameStyle.isVisible {
                    Text(entry.track.title.isEmpty ? "No Track Playing" : entry.track.title)
                        .font(fontFor(entry.theme.trackNameStyle, defaultSize: 13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: Color.black.opacity(0.8), radius: 3, x: 0, y: 1)
                }

                let showArtist = entry.theme.artistStyle.isVisible && !entry.track.artist.isEmpty
                let showAlbum = entry.theme.albumStyle.isVisible && !entry.track.album.isEmpty
                if showArtist || showAlbum {
                    let sub = (showArtist ? entry.track.artist : "") + (showArtist && showAlbum ? " — " : "") + (showAlbum ? entry.track.album : "")
                    Text(sub)
                        .font(fontFor(entry.theme.artistStyle, defaultSize: 10))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
                }

                if entry.theme.showPlaybackControls {
                    let iconSize = entry.theme.controlsSize.iconSize * 0.75
                    HStack {
                        Button(intent: PreviousTrackIntent()) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.white.opacity(0.24)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(intent: TogglePlayIntent()) {
                            Image(systemName: entry.track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: iconSize * 1.15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.white.opacity(0.24)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(intent: NextTrackIntent()) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.white.opacity(0.24)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(10)
        }
    }

    // MARK: - System Medium (Split Banner or Time Dashboard)
    private var mediumWidgetView: some View {
        Group {
            if entry.theme.layout == .timeDashboard {
                mediumTimeDashboardView
            } else {
                mediumSplitBannerView
            }
        }
    }

    private var mediumSplitBannerView: some View {
        let cornerR = max(6, min(18, entry.theme.cornerRadius))
        return HStack(spacing: 14) {
            if entry.theme.flipHorizontal {
                mediumTextAndControls
                widgetArtwork(size: 100, cornerRadius: cornerR)
            } else {
                widgetArtwork(size: 100, cornerRadius: cornerR)
                mediumTextAndControls
            }
        }
        .padding(14)
    }

    private var mediumTextAndControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.theme.trackNameStyle.isVisible {
                Text(entry.track.title)
                    .font(fontFor(entry.theme.trackNameStyle, defaultSize: 15))
                    .foregroundColor(colorFor(entry.theme.trackNameStyle))
                    .lineLimit(1)
                    .shadow(
                        color: Color.black.opacity(entry.theme.trackNameStyle.shadow.opacity),
                        radius: entry.theme.trackNameStyle.shadow.radius * 0.5,
                        x: 0,
                        y: entry.theme.trackNameStyle.shadow.yOffset * 0.5
                    )
            }

            if entry.theme.artistStyle.isVisible {
                Text(entry.track.artist)
                    .font(fontFor(entry.theme.artistStyle, defaultSize: 12))
                    .foregroundColor(colorFor(entry.theme.artistStyle, opacity: 0.85))
                    .lineLimit(1)
            }

            if entry.theme.albumStyle.isVisible && !entry.track.album.isEmpty {
                Text("— " + entry.track.album)
                    .font(fontFor(entry.theme.albumStyle, defaultSize: 11))
                    .foregroundColor(colorFor(entry.theme.albumStyle, opacity: 0.60))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if entry.theme.showPlaybackControls {
                let iconSize = entry.theme.controlsSize.iconSize * 0.85
                HStack(spacing: entry.theme.controlsSize.buttonPadding * 1.2) {
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.24)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: TogglePlayIntent()) {
                        Image(systemName: entry.track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: iconSize * 1.15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.24)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.24)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumTimeDashboardView: some View {
        VStack(spacing: 10) {
            // Three Time Metric Columns
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(entry.track.position))
                        .font(.system(size: 20, weight: .bold, design: entry.theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(entry.theme.trackNameStyle))
                    Text("ELAPSED")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(colorFor(entry.theme.trackNameStyle, opacity: 0.55))
                }

                Spacer()

                let remaining = max(0, entry.track.duration - entry.track.position)
                VStack(alignment: .center, spacing: 2) {
                    Text("-" + formatTime(remaining))
                        .font(.system(size: 20, weight: .bold, design: entry.theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(entry.theme.trackNameStyle))
                    Text("REMAINING")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(colorFor(entry.theme.trackNameStyle, opacity: 0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(entry.track.duration))
                        .font(.system(size: 20, weight: .bold, design: entry.theme.trackNameStyle.fontDesign.fontDesign))
                        .monospacedDigit()
                        .foregroundColor(colorFor(entry.theme.trackNameStyle))
                    Text("DURATION")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(colorFor(entry.theme.trackNameStyle, opacity: 0.55))
                }
            }

            // Bottom Track Bar Container
            HStack(spacing: 8) {
                let cornerR = max(4, min(10, entry.theme.cornerRadius))
                widgetArtwork(size: 38, cornerRadius: cornerR)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.track.title)
                        .font(fontFor(entry.theme.trackNameStyle, defaultSize: 12))
                        .foregroundColor(colorFor(entry.theme.trackNameStyle))
                        .lineLimit(1)

                    Text(entry.track.artist)
                        .font(fontFor(entry.theme.artistStyle, defaultSize: 9))
                        .foregroundColor(colorFor(entry.theme.artistStyle, opacity: 0.65))
                        .lineLimit(1)
                }

                Spacer()

                if entry.theme.showPlaybackControls {
                    Button(intent: TogglePlayIntent()) {
                        Image(systemName: entry.track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        }
        .padding(12)
    }

    // MARK: - System Large (Poster / Deep View)
    private var largeWidgetView: some View {
        VStack(spacing: 12) {
            let posterSize: CGFloat = 160
            let cornerR = max(8, min(24, entry.theme.cornerRadius))
            widgetArtwork(size: posterSize, cornerRadius: cornerR)

            VStack(spacing: 4) {
                if entry.theme.trackNameStyle.isVisible {
                    Text(entry.track.title)
                        .font(fontFor(entry.theme.trackNameStyle, defaultSize: 17))
                        .foregroundColor(colorFor(entry.theme.trackNameStyle))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .shadow(
                            color: Color.black.opacity(entry.theme.trackNameStyle.shadow.opacity),
                            radius: entry.theme.trackNameStyle.shadow.radius * 0.5,
                            x: 0,
                            y: entry.theme.trackNameStyle.shadow.yOffset * 0.5
                        )
                }

                if entry.theme.artistStyle.isVisible {
                    Text(entry.track.artist)
                        .font(fontFor(entry.theme.artistStyle, defaultSize: 13))
                        .foregroundColor(colorFor(entry.theme.artistStyle, opacity: 0.85))
                        .lineLimit(1)
                }

                if entry.theme.albumStyle.isVisible && !entry.track.album.isEmpty {
                    Text(entry.track.album)
                        .font(fontFor(entry.theme.albumStyle, defaultSize: 11))
                        .foregroundColor(colorFor(entry.theme.albumStyle, opacity: 0.60))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if entry.theme.showPlaybackControls {
                HStack(spacing: 16) {
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: TogglePlayIntent()) {
                        Image(systemName: entry.track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.20)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }

    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Widget Configuration

public struct VinylDeskWidget: Widget {
    public let kind: String = "VinylDeskWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VinylDeskTimelineProvider()) { entry in
            VinylDeskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VinylDesk Music")
        .description("Track metadata, cover art, and interactive playback controls right on your desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct VinylDeskWidgetBundle: WidgetBundle {
    var body: some Widget {
        VinylDeskWidget()
    }
}
