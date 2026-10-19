import Foundation
import AppKit
import WidgetKit

public struct SharedWidgetTrack: Codable, Sendable {
    public var title: String
    public var artist: String
    public var album: String
    public var duration: Double
    public var position: Double
    public var isPlaying: Bool
    public var source: String
    public var lastUpdated: Date

    public init(
        title: String,
        artist: String,
        album: String,
        duration: Double,
        position: Double,
        isPlaying: Bool,
        source: String,
        lastUpdated: Date = Date()
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.isPlaying = isPlaying
        self.source = source
        self.lastUpdated = lastUpdated
    }

    public static let fallback = SharedWidgetTrack(
        title: "Intentions (feat. Quavo)",
        artist: "Justin Bieber",
        album: "Changes",
        duration: 212,
        position: 132,
        isPlaying: true,
        source: "Spotify"
    )
}

public final class SharedWidgetStorage: @unchecked Sendable {
    public static let shared = SharedWidgetStorage()

    private let fileQueue = DispatchQueue(label: "VinylDesk.SharedWidgetStorage")
    private let appSupportURL: URL

    private init() {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = base.appendingPathComponent("VinylDesk", isDirectory: true)

        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }

        self.appSupportURL = appDir
    }

    private var jsonURL: URL {
        appSupportURL.appendingPathComponent("widget_track.json")
    }

    private var artworkURL: URL {
        appSupportURL.appendingPathComponent("widget_artwork.png")
    }

    private var themeURL: URL {
        appSupportURL.appendingPathComponent("widget_theme.json")
    }

    public func saveTrack(_ track: TrackInfo) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }

            let sharedTrack = SharedWidgetTrack(
                title: track.title.isEmpty ? "No Track Playing" : track.title,
                artist: track.artist,
                album: track.album,
                duration: track.duration,
                position: track.position,
                isPlaying: track.isPlaying,
                source: track.source.rawValue
            )

            if let data = try? JSONEncoder().encode(sharedTrack) {
                try? data.write(to: self.jsonURL, options: .atomic)
            }

            if let artworkData = track.artworkData, !artworkData.isEmpty {
                // Downscale and write artwork PNG
                if let nsImage = NSImage(data: artworkData) {
                    if let tiff = nsImage.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff),
                       let png = bitmap.representation(using: .png, properties: [:]) {
                        try? png.write(to: self.artworkURL, options: .atomic)
                    }
                }
            }

            // Trigger WidgetKit timeline refresh
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    public func saveTheme(_ theme: VinylThemeConfig) {
        fileQueue.sync { [weak self] in
            guard let self = self else { return }

            if let data = try? JSONEncoder().encode(theme) {
                try? data.write(to: self.themeURL, options: .atomic)
            }

            // Trigger WidgetKit timeline refresh to adopt new theme immediately
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    public func loadTrack() -> SharedWidgetTrack {
        return fileQueue.sync {
            if let data = try? Data(contentsOf: jsonURL),
               let track = try? JSONDecoder().decode(SharedWidgetTrack.self, from: data) {
                return track
            }
            return .fallback
        }
    }

    public func loadTheme() -> VinylThemeConfig {
        return fileQueue.sync {
            if let data = try? Data(contentsOf: themeURL),
               let theme = try? JSONDecoder().decode(VinylThemeConfig.self, from: data) {
                return theme
            }
            return VinylThemeConfig.presetTimeDashboard
        }
    }

    public func loadArtwork() -> NSImage? {
        if let data = try? Data(contentsOf: artworkURL) {
            return NSImage(data: data)
        }
        return nil
    }
}
