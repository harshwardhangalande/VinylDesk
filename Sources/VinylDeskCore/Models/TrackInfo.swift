import Foundation
import AppKit

public enum MusicSource: String, Sendable, CaseIterable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case demo = "Demo Player"
}

public struct TrackInfo: Equatable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public var duration: TimeInterval
    public var position: TimeInterval
    public var isPlaying: Bool
    public var artworkData: Data?
    public let source: MusicSource

    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        position: TimeInterval = 0,
        isPlaying: Bool = false,
        artworkData: Data? = nil,
        source: MusicSource = .demo
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = max(1, duration)
        self.position = max(0, min(position, duration))
        self.isPlaying = isPlaying
        self.artworkData = artworkData
        self.source = source
    }

    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0.0), 1.0)
    }

    public var formattedPosition: String {
        Self.formatTime(position)
    }

    public var formattedDuration: String {
        Self.formatTime(duration)
    }

    public static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public static let demoTrack = TrackInfo(
        id: "demo-track-1",
        title: "Midnight Tokyo Lofi",
        artist: "The Analog Collective",
        album: "Vinyl Session Vol. 1",
        duration: 194.0,
        position: 42.0,
        isPlaying: true,
        source: .demo
    )
}
