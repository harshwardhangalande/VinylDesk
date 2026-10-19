import Foundation
import AppKit

public final class AppleMusicService: @unchecked Sendable {
    public static let shared = AppleMusicService()

    private init() {}

    public var isRunning: Bool {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")
        return !apps.isEmpty
    }

    public func fetchCurrentTrack() -> TrackInfo? {
        guard isRunning else { return nil }

        let scriptSource = """
        tell application "Music"
            if running then
                set pState to player state as string
                if pState is not "stopped" then
                    set tName to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set tDuration to duration of current track
                    set tPosition to player position
                    set tId to id of current track as string
                    return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tDuration & "|||" & tPosition & "|||" & tId
                else
                    return "stopped||||||||||||0|||0|||0"
                end if
            else
                return "stopped||||||||||||0|||0|||0"
            end if
        end tell
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptSource),
              let output = script.executeAndReturnError(&error).stringValue else {
            return nil
        }

        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 7 else { return nil }

        let state = parts[0]
        let name = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let duration = Double(parts[4]) ?? 0
        let position = Double(parts[5]) ?? 0
        let trackId = parts[6]

        guard !name.isEmpty else { return nil }

        let artworkData = fetchArtworkData()

        return TrackInfo(
            id: trackId,
            title: name,
            artist: artist,
            album: album,
            duration: duration,
            position: position,
            isPlaying: state == "playing",
            artworkData: artworkData,
            source: .appleMusic
        )
    }

    private func fetchArtworkData() -> Data? {
        let artworkScript = """
        tell application "Music"
            if running and (count of artworks of current track) > 0 then
                set rawData to raw data of artwork 1 of current track
                return rawData
            end if
        end tell
        """
        guard let script = NSAppleScript(source: artworkScript) else { return nil }
        var scriptError: NSDictionary?
        let descriptor = script.executeAndReturnError(&scriptError)
        let data = descriptor.data
        return data.isEmpty ? nil : data
    }

    public func togglePlayPause() {
        runCommand("tell application \"Music\" to playpause")
    }

    public func nextTrack() {
        runCommand("tell application \"Music\" to next track")
    }

    public func previousTrack() {
        runCommand("tell application \"Music\" to previous track")
    }

    public func seek(to seconds: TimeInterval) {
        runCommand("tell application \"Music\" to set player position to \(seconds)")
    }

    private func runCommand(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            let script = NSAppleScript(source: command)
            script?.executeAndReturnError(&error)
        }
    }
}
