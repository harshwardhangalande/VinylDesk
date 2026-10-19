import Foundation
import AppKit

public final class SpotifyService: @unchecked Sendable {
    public static let shared = SpotifyService()

    private init() {}

    public var isRunning: Bool {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client")
        return !apps.isEmpty
    }

    public func fetchCurrentTrack() -> TrackInfo? {
        guard isRunning else { return nil }

        let scriptSource = """
        tell application "Spotify"
            if running then
                set pState to player state as string
                set tName to name of current track
                set tArtist to artist of current track
                set tAlbum to album of current track
                set tDuration to (duration of current track) / 1000.0
                set tPosition to player position
                set tArtwork to artwork url of current track
                set tId to id of current track
                return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPosition & "|||" & tArtwork & "|||" & tId
            else
                return "stopped||||||||||||0|||0||||||"
            end if
        end tell
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptSource),
              let output = script.executeAndReturnError(&error).stringValue else {
            return nil
        }

        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 8 else { return nil }

        let state = parts[0]
        let name = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let duration = Double(parts[4]) ?? 0
        let position = Double(parts[5]) ?? 0
        let artworkUrlString = parts[6]
        let trackId = parts[7]

        guard !name.isEmpty else { return nil }

        let artworkData = getOrFetchArtwork(for: trackId, urlString: artworkUrlString)

        return TrackInfo(
            id: trackId,
            title: name,
            artist: artist,
            album: album,
            duration: duration,
            position: position,
            isPlaying: state == "playing",
            artworkData: artworkData,
            source: .spotify
        )
    }

    private var artworkDataCache = [String: Data]()
    private let cacheQueue = DispatchQueue(label: "VinylDesk.SpotifyCache")

    private func getOrFetchArtwork(for trackId: String, urlString: String) -> Data? {
        let cached = cacheQueue.sync { artworkDataCache[trackId] }
        if let cached = cached {
            return cached
        }

        guard let url = URL(string: urlString), !urlString.isEmpty else { return nil }

        // Fetch asynchronously off the main thread
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            self?.cacheQueue.sync {
                self?.artworkDataCache[trackId] = data
            }

            await MainActor.run {
                MusicCoordinator.shared.updateArtwork(data, forTrackId: trackId)
            }
        }

        return nil
    }

    public func togglePlayPause() {
        runCommand("tell application \"Spotify\" to playpause")
    }

    public func nextTrack() {
        runCommand("tell application \"Spotify\" to next track")
    }

    public func previousTrack() {
        runCommand("tell application \"Spotify\" to previous track")
    }

    public func seek(to seconds: TimeInterval) {
        runCommand("tell application \"Spotify\" to set player position to \(seconds)")
    }

    private func runCommand(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            let script = NSAppleScript(source: command)
            script?.executeAndReturnError(&error)
        }
    }
}
