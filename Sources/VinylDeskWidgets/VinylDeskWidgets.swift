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
        TrackEntry(date: Date(), track: .fallback, artwork: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrackEntry) -> Void) {
        let track = SharedWidgetStorage.shared.loadTrack()
        let artwork = SharedWidgetStorage.shared.loadArtwork()
        completion(TrackEntry(date: Date(), track: track, artwork: artwork))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrackEntry>) -> Void) {
        let track = SharedWidgetStorage.shared.loadTrack()
        let artwork = SharedWidgetStorage.shared.loadArtwork()
        let entry = TrackEntry(date: Date(), track: track, artwork: artwork)
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TrackEntry: TimelineEntry {
    let date: Date
    let track: SharedWidgetTrack
    let artwork: NSImage?
}

// MARK: - Widget Views

struct VinylDeskWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: VinylDeskTimelineProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        default:
            mediumWidgetView
        }
    }

    // MARK: - System Small (Compact Square / Squircle)
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Square poster thumbnail aligned equally from top and leading (10pt each)
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
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.track.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                let sub = entry.track.artist + (entry.track.album.isEmpty ? "" : " — " + entry.track.album)
                Text(sub)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Interactive Play/Pause button via AppIntent
            HStack {
                Button(intent: PreviousTrackIntent()) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(intent: TogglePlayIntent()) {
                    Image(systemName: entry.track.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(intent: NextTrackIntent()) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .containerBackground(Color(white: 0.12), for: .widget)
    }

    // MARK: - System Medium (Split Banner)
    private var mediumWidgetView: some View {
        HStack(spacing: 14) {
            // Square poster thumbnail with strictly equal top and leading margins
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
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.track.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(entry.track.artist)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)

                if !entry.track.album.isEmpty {
                    Text("— " + entry.track.album)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.60))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Interactive AppIntent Controls
                HStack(spacing: 12) {
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: TogglePlayIntent()) {
                        Image(systemName: entry.track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)))
                    }
                    .buttonStyle(.plain)

                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(Color(white: 0.12), for: .widget)
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct VinylDeskWidgetBundle: WidgetBundle {
    var body: some Widget {
        VinylDeskWidget()
    }
}
