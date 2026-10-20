import Foundation
import AppKit

public final class WebMusicService: @unchecked Sendable {
    public static let shared = WebMusicService()

    private struct BrowserTarget {
        let appName: String
        let bundleId: String
        let isSafari: Bool
    }

    private let supportedBrowsers: [BrowserTarget] = [
        BrowserTarget(appName: "Safari", bundleId: "com.apple.Safari", isSafari: true),
        BrowserTarget(appName: "Google Chrome", bundleId: "com.google.Chrome", isSafari: false),
        BrowserTarget(appName: "Brave Browser", bundleId: "com.brave.Browser", isSafari: false),
        BrowserTarget(appName: "Arc", bundleId: "company.thebrowser.Browser", isSafari: false),
        BrowserTarget(appName: "Microsoft Edge", bundleId: "com.microsoft.edgemac", isSafari: false)
    ]

    private var lastArtworkUrl: String?
    private var lastArtworkData: Data?

    private init() {}

    public var isAnyBrowserRunning: Bool {
        let runningBundleIds = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        return supportedBrowsers.contains { runningBundleIds.contains($0.bundleId) }
    }

    // MARK: - Fetch Current Web Track

    public func fetchCurrentTrack() -> TrackInfo? {
        let runningBundleIds = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })

        for browser in supportedBrowsers where runningBundleIds.contains(browser.bundleId) {
            if let track = queryBrowser(browser) {
                return track
            }
        }
        return nil
    }

    private func queryBrowser(_ browser: BrowserTarget) -> TrackInfo? {
        let scriptSource: String
        if browser.isSafari {
            scriptSource = """
            tell application "Safari"
                set res to {}
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set u to URL of t
                            if u contains "open.spotify.com" or u contains "music.apple.com" then
                                set tabTitle to name of t
                                set jsData to ""
                                try
                                    set jsData to do JavaScript "(function() { var a = document.querySelector('audio'); var ms = navigator.mediaSession; return JSON.stringify({ title: ms && ms.metadata ? ms.metadata.title : '', artist: ms && ms.metadata ? ms.metadata.artist : '', album: ms && ms.metadata ? ms.metadata.album : '', artwork: ms && ms.metadata && ms.metadata.artwork && ms.metadata.artwork.length ? ms.metadata.artwork[0].src : '', playing: ms ? ms.playbackState === 'playing' : (a ? !a.paused : false), pos: a ? a.currentTime : 0, dur: a ? a.duration : 0 }); })()" in t
                                end try
                                set end of res to (u & "\t" & tabTitle & "\t" & jsData)
                            end if
                        end repeat
                    end repeat
                end try
                return res
            end tell
            """
        } else {
            scriptSource = """
            tell application "\(browser.appName)"
                set res to {}
                try
                    repeat with w in windows
                        repeat with t in tabs of w
                            set u to URL of t
                            if u contains "open.spotify.com" or u contains "music.apple.com" then
                                set tabTitle to title of t
                                set jsData to ""
                                try
                                    set jsData to tell t to execute javascript "(function() { var a = document.querySelector('audio'); var ms = navigator.mediaSession; return JSON.stringify({ title: ms && ms.metadata ? ms.metadata.title : '', artist: ms && ms.metadata ? ms.metadata.artist : '', album: ms && ms.metadata ? ms.metadata.album : '', artwork: ms && ms.metadata && ms.metadata.artwork && ms.metadata.artwork.length ? ms.metadata.artwork[0].src : '', playing: ms ? ms.playbackState === 'playing' : (a ? !a.paused : false), pos: a ? a.currentTime : 0, dur: a ? a.duration : 0 }); })()"
                                end try
                                set end of res to (u & "\t" & tabTitle & "\t" & jsData)
                            end if
                        end repeat
                    end repeat
                end try
                return res
            end tell
            """
        }

        var errorDict: NSDictionary?
        guard let appleScript = NSAppleScript(source: scriptSource) else { return nil }
        let descriptor = appleScript.executeAndReturnError(&errorDict)
        guard errorDict == nil else { return nil }

        let count = descriptor.numberOfItems
        guard count > 0 else { return nil }

        for i in 1...count {
            guard let itemStr = descriptor.atIndex(i)?.stringValue else { continue }
            let parts = itemStr.components(separatedBy: "\t")
            guard parts.count >= 2 else { continue }

            let url = parts[0]
            let tabTitle = parts[1]
            let jsData = parts.count > 2 ? parts[2] : ""

            let isSpotify = url.contains("spotify.com")
            let source: MusicSource = isSpotify ? .spotifyWeb : .appleMusicWeb

            // Try decoding JS metadata first if available
            if !jsData.isEmpty, let data = jsData.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["title"] as? String, !title.isEmpty {
                let artist = json["artist"] as? String ?? ""
                let album = json["album"] as? String ?? ""
                let isPlaying = json["playing"] as? Bool ?? true
                let pos = json["pos"] as? Double ?? 0
                let dur = json["dur"] as? Double ?? 180
                let artworkUrl = json["artwork"] as? String

                let artworkData: Data? = self.lastArtworkData
                if let artUrl = artworkUrl, !artUrl.isEmpty {
                    if artUrl != self.lastArtworkUrl {
                        self.lastArtworkUrl = artUrl
                        ArtworkCache.shared.fetchRemoteArtwork(from: artUrl) { [weak self] downloaded in
                            if let downloaded = downloaded {
                                self?.lastArtworkData = downloaded
                                Task { @MainActor in
                                    MusicCoordinator.shared.updateArtwork(downloaded, forTrackId: "\(title)-\(artist)")
                                }
                            }
                        }
                    }
                }

                return TrackInfo(
                    id: "\(title)-\(artist)",
                    title: title,
                    artist: artist,
                    album: album,
                    duration: dur > 0 ? dur : 180,
                    position: pos,
                    isPlaying: isPlaying,
                    artworkData: artworkData,
                    source: source
                )
            }

            // Fallback: Parse tab title directly
            if let parsed = parseWebTrack(url: url, tabTitle: tabTitle) {
                return TrackInfo(
                    id: "\(parsed.title)-\(parsed.artist)",
                    title: parsed.title,
                    artist: parsed.artist,
                    album: "",
                    duration: 180,
                    position: 0,
                    isPlaying: true,
                    artworkData: self.lastArtworkData,
                    source: source
                )
            }
        }

        return nil
    }

    // MARK: - Title Parser

    public func parseWebTrack(url: String, tabTitle: String) -> (title: String, artist: String)? {
        var raw = tabTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSpotify = url.contains("spotify.com")
        let isApple = url.contains("music.apple.com")

        if isSpotify {
            if let r = raw.range(of: " | Spotify", options: .backwards) { raw.removeSubrange(r.lowerBound..<raw.endIndex) }
            if let r = raw.range(of: " - Spotify", options: .backwards) { raw.removeSubrange(r.lowerBound..<raw.endIndex) }
            if raw.hasPrefix("Spotify – ") { raw = String(raw.dropFirst("Spotify – ".count)) }
            if raw.hasPrefix("Spotify - ") { raw = String(raw.dropFirst("Spotify - ".count)) }
            if raw.contains("Web Player") || raw.contains("Search") || raw.contains("Your Library") { return nil }

            if let r = raw.range(of: " - song and artist by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " - song by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " • ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " · ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " - ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
        } else if isApple {
            if let r = raw.range(of: " - Apple Music", options: .backwards) { raw.removeSubrange(r.lowerBound..<raw.endIndex) }
            if let r = raw.range(of: " | Apple Music", options: .backwards) { raw.removeSubrange(r.lowerBound..<raw.endIndex) }
            if raw.contains("Browse") || raw.contains("Listen Now") || raw.contains("Radio") || raw.contains("Library") { return nil }

            if let r = raw.range(of: " - Song by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " - Single by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " • ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " - ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
        }
        return nil
    }

    // MARK: - Playback Controls

    public func togglePlayPause(for track: TrackInfo) {
        let isSpotify = (track.source == .spotifyWeb)
        let jsSpotify = "document.querySelector('[data-testid=\"control-button-playpause\"]')?.click() || document.querySelector('button[aria-label=\"Play\"], button[aria-label=\"Pause\"]')?.click();"
        let jsApple = "document.querySelector('button.playback-button')?.click() || document.querySelector('button[aria-label=\"Play\"], button[aria-label=\"Pause\"]')?.click();"
        let targetJS = isSpotify ? jsSpotify : jsApple
        executeScriptOnMediaTab(targetUrlSubstring: isSpotify ? "open.spotify.com" : "music.apple.com", js: targetJS)
    }

    public func nextTrack(for track: TrackInfo) {
        let isSpotify = (track.source == .spotifyWeb)
        let jsSpotify = "document.querySelector('[data-testid=\"control-button-skip-forward\"]')?.click() || document.querySelector('button[aria-label=\"Next\"]')?.click();"
        let jsApple = "document.querySelector('button[aria-label=\"Next\"]')?.click() || document.querySelector('button[aria-label=\"Skip forward\"]')?.click();"
        let targetJS = isSpotify ? jsSpotify : jsApple
        executeScriptOnMediaTab(targetUrlSubstring: isSpotify ? "open.spotify.com" : "music.apple.com", js: targetJS)
    }

    public func previousTrack(for track: TrackInfo) {
        let isSpotify = (track.source == .spotifyWeb)
        let jsSpotify = "document.querySelector('[data-testid=\"control-button-skip-back\"]')?.click() || document.querySelector('button[aria-label=\"Previous\"]')?.click();"
        let jsApple = "document.querySelector('button[aria-label=\"Previous\"]')?.click() || document.querySelector('button[aria-label=\"Skip backward\"]')?.click();"
        let targetJS = isSpotify ? jsSpotify : jsApple
        executeScriptOnMediaTab(targetUrlSubstring: isSpotify ? "open.spotify.com" : "music.apple.com", js: targetJS)
    }

    private func executeScriptOnMediaTab(targetUrlSubstring: String, js: String) {
        let runningBundleIds = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })

        for browser in supportedBrowsers where runningBundleIds.contains(browser.bundleId) {
            let scriptSource: String
            if browser.isSafari {
                scriptSource = """
                tell application "Safari"
                    try
                        repeat with w in windows
                            repeat with t in tabs of w
                                if URL of t contains "\(targetUrlSubstring)" then
                                    do JavaScript "\(js)" in t
                                    return
                                end if
                            end repeat
                        end repeat
                    end try
                end tell
                """
            } else {
                scriptSource = """
                tell application "\(browser.appName)"
                    try
                        repeat with w in windows
                            repeat with t in tabs of w
                                if URL of t contains "\(targetUrlSubstring)" then
                                    tell t to execute javascript "\(js)"
                                    return
                                end if
                            end repeat
                        end repeat
                    end try
                end tell
                """
            }

            var err: NSDictionary?
            if let appleScript = NSAppleScript(source: scriptSource) {
                appleScript.executeAndReturnError(&err)
            }
        }
    }
}
