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

    private var lastArtworkKey: String?
    private var lastArtworkData: Data?

    private init() {}

    public var isAnyBrowserRunning: Bool {
        let runningBundleIds = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        return supportedBrowsers.contains { runningBundleIds.contains($0.bundleId) }
    }

    public var hasOpenSpotifyTab: Bool {
        return findMediaTab(urlSubstring: "open.spotify.com") != nil
    }

    public var hasOpenAppleMusicTab: Bool {
        return findMediaTab(urlSubstring: "music.apple.com") != nil
    }

    // MARK: - Fetch Current Web Track

    public func fetchCurrentTrack() -> TrackInfo? {
        // Strategy 1: Check system-level MediaRemote for actively playing web audio
        if let mrSnapshot = MediaRemoteBridge.shared.currentSnapshot,
           mrSnapshot.isBrowser && mrSnapshot.isPlaying && (!mrSnapshot.title.isEmpty || !mrSnapshot.artist.isEmpty) {

            // Determine if the browser is playing Spotify or Apple Music
            let isApple = hasOpenAppleMusicTab
            let isSpotify = hasOpenSpotifyTab || !isApple
            let source: MusicSource = isSpotify ? .spotifyWeb : .appleMusicWeb

            let trackId = "\(mrSnapshot.title)-\(mrSnapshot.artist)"
            resolveArtworkIfNeeded(title: mrSnapshot.title, artist: mrSnapshot.artist, trackId: trackId)

            return TrackInfo(
                id: trackId,
                title: mrSnapshot.title.isEmpty ? "Web Playback" : mrSnapshot.title,
                artist: mrSnapshot.artist.isEmpty ? (isSpotify ? "Spotify Web" : "Apple Music Web") : mrSnapshot.artist,
                album: mrSnapshot.album,
                duration: mrSnapshot.duration > 0 ? mrSnapshot.duration : 180,
                position: mrSnapshot.elapsedTime,
                isPlaying: mrSnapshot.isPlaying,
                artworkData: self.lastArtworkData,
                source: source
            )
        }

        // Strategy 2: Check open browser tabs for Spotify and Apple Music
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

            // Method A: Decoded JavaScript mediaSession metadata
            if !jsData.isEmpty, let data = jsData.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["title"] as? String, !title.isEmpty {
                let artist = json["artist"] as? String ?? ""
                let album = json["album"] as? String ?? ""
                let isPlaying = json["playing"] as? Bool ?? true
                let pos = json["pos"] as? Double ?? 0
                let dur = json["dur"] as? Double ?? 180
                let artworkUrl = json["artwork"] as? String

                let trackId = "\(title)-\(artist)"
                if let artUrl = artworkUrl, !artUrl.isEmpty {
                    downloadArtworkDirectly(artUrl: artUrl, trackId: trackId)
                } else {
                    resolveArtworkIfNeeded(title: title, artist: artist, trackId: trackId)
                }

                return TrackInfo(
                    id: trackId,
                    title: title,
                    artist: artist,
                    album: album,
                    duration: dur > 0 ? dur : 180,
                    position: pos,
                    isPlaying: isPlaying,
                    artworkData: self.lastArtworkData,
                    source: source
                )
            }

            // Method B: Parse tab title directly
            if let parsed = parseWebTrack(url: url, tabTitle: tabTitle) {
                let trackId = "\(parsed.title)-\(parsed.artist)"
                resolveArtworkIfNeeded(title: parsed.title, artist: parsed.artist, trackId: trackId)

                return TrackInfo(
                    id: trackId,
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

            // Method C: Spotify Web tab is open on home/player or track URL
            if isSpotify {
                // If it's a specific track URL e.g. open.spotify.com/track/4cOdK...
                if url.contains("/track/") {
                    fetchSpotifyOEmbed(trackUrl: url)
                }

                return TrackInfo(
                    id: "spotify-web-session",
                    title: "Spotify Web",
                    artist: "Connected to Browser",
                    album: "",
                    duration: 180,
                    position: 0,
                    isPlaying: false,
                    artworkData: self.lastArtworkData,
                    source: .spotifyWeb
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

        guard isSpotify || isApple else { return nil }

        if isSpotify {
            // Strip trailing branding
            for suffix in [" | Spotify", " - Spotify", " – Spotify", " — Spotify"] {
                if let r = raw.range(of: suffix, options: .backwards) {
                    raw.removeSubrange(r.lowerBound..<raw.endIndex)
                }
            }
            // Strip leading branding
            for prefix in ["Spotify – ", "Spotify - ", "Spotify — "] {
                if raw.hasPrefix(prefix) {
                    raw = String(raw.dropFirst(prefix.count))
                }
            }

            // Ignore purely generic landing/login pages
            if raw == "Web Player" || raw == "Search" || raw == "Your Library" ||
               raw.hasPrefix("Web Player:") || raw.hasPrefix("Listen to Music") {
                return nil
            }

            // Patterns like " - song and artist by "
            if let r = raw.range(of: " - song and artist by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Patterns like " - song by "
            if let r = raw.range(of: " - song by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Patterns like " - single by " or " - album by "
            if let r = raw.range(of: " - single by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            if let r = raw.range(of: " - album by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Separator " • "
            if let r = raw.range(of: " • ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Separator " · "
            if let r = raw.range(of: " · ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Separator " - "
            if let r = raw.range(of: " - ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Separator " – " (en dash)
            if let r = raw.range(of: " – ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Separator " — " (em dash)
            if let r = raw.range(of: " — ") {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }
            // Separator " by "
            if let r = raw.range(of: " by ", options: .caseInsensitive) {
                let t = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let a = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (t, a)
            }

            if url.contains("/track/") && !raw.isEmpty {
                return (raw, "Spotify Web")
            }
        } else if isApple {
            for suffix in [" - Apple Music", " | Apple Music"] {
                if let r = raw.range(of: suffix, options: .backwards) {
                    raw.removeSubrange(r.lowerBound..<raw.endIndex)
                }
            }
            if raw.contains("Browse") || raw.contains("Listen Now") || raw.contains("Radio") || raw.contains("Library") {
                return nil
            }

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
        // Step 1: System-level MediaRemote toggle (works across all browsers)
        MediaRemoteBridge.shared.togglePlayPause()

        // Step 2: Direct browser tab DOM click fallback
        let isSpotify = (track.source == .spotifyWeb)
        let jsSpotify = "document.querySelector('[data-testid=\"control-button-playpause\"]')?.click() || document.querySelector('button[aria-label=\"Play\"], button[aria-label=\"Pause\"]')?.click();"
        let jsApple = "document.querySelector('button.playback-button')?.click() || document.querySelector('button[aria-label=\"Play\"], button[aria-label=\"Pause\"]')?.click();"
        let targetJS = isSpotify ? jsSpotify : jsApple
        executeScriptOnMediaTab(targetUrlSubstring: isSpotify ? "open.spotify.com" : "music.apple.com", js: targetJS)
    }

    public func nextTrack(for track: TrackInfo) {
        MediaRemoteBridge.shared.nextTrack()

        let isSpotify = (track.source == .spotifyWeb)
        let jsSpotify = "document.querySelector('[data-testid=\"control-button-skip-forward\"]')?.click() || document.querySelector('button[aria-label=\"Next\"]')?.click();"
        let jsApple = "document.querySelector('button[aria-label=\"Next\"]')?.click() || document.querySelector('button[aria-label=\"Skip forward\"]')?.click();"
        let targetJS = isSpotify ? jsSpotify : jsApple
        executeScriptOnMediaTab(targetUrlSubstring: isSpotify ? "open.spotify.com" : "music.apple.com", js: targetJS)
    }

    public func previousTrack(for track: TrackInfo) {
        MediaRemoteBridge.shared.previousTrack()

        let isSpotify = (track.source == .spotifyWeb)
        let jsSpotify = "document.querySelector('[data-testid=\"control-button-skip-back\"]')?.click() || document.querySelector('button[aria-label=\"Previous\"]')?.click();"
        let jsApple = "document.querySelector('button[aria-label=\"Previous\"]')?.click() || document.querySelector('button[aria-label=\"Skip backward\"]')?.click();"
        let targetJS = isSpotify ? jsSpotify : jsApple
        executeScriptOnMediaTab(targetUrlSubstring: isSpotify ? "open.spotify.com" : "music.apple.com", js: targetJS)
    }

    private func findMediaTab(urlSubstring: String) -> (browser: BrowserTarget, url: String)? {
        let runningBundleIds = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })

        for browser in supportedBrowsers where runningBundleIds.contains(browser.bundleId) {
            let scriptSource: String
            if browser.isSafari {
                scriptSource = """
                tell application "Safari"
                    try
                        repeat with w in windows
                            repeat with t in tabs of w
                                if URL of t contains "\(urlSubstring)" then
                                    return URL of t
                                end if
                            end repeat
                        end repeat
                    end try
                    return ""
                end tell
                """
            } else {
                scriptSource = """
                tell application "\(browser.appName)"
                    try
                        repeat with w in windows
                            repeat with t in tabs of w
                                if URL of t contains "\(urlSubstring)" then
                                    return URL of t
                                end if
                            end repeat
                        end repeat
                    end try
                    return ""
                end tell
                """
            }

            var err: NSDictionary?
            if let appleScript = NSAppleScript(source: scriptSource) {
                let res = appleScript.executeAndReturnError(&err)
                if let str = res.stringValue, !str.isEmpty {
                    return (browser, str)
                }
            }
        }
        return nil
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

    // MARK: - Artwork Helpers

    private func downloadArtworkDirectly(artUrl: String, trackId: String) {
        guard artUrl != lastArtworkKey else { return }
        lastArtworkKey = artUrl
        ArtworkCache.shared.fetchRemoteArtwork(from: artUrl) { [weak self] data in
            guard let self = self, let data = data else { return }
            self.lastArtworkData = data
            Task { @MainActor in
                MusicCoordinator.shared.updateArtwork(data, forTrackId: trackId)
            }
        }
    }

    private func resolveArtworkIfNeeded(title: String, artist: String, trackId: String) {
        let key = "\(title):\(artist)"
        guard key != lastArtworkKey else { return }
        lastArtworkKey = key

        let query = "\(title) \(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&entity=song&limit=1") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let artUrl = first["artworkUrl100"] as? String else { return }

            let highResUrl = artUrl.replacingOccurrences(of: "100x100bb", with: "600x600bb")
            ArtworkCache.shared.fetchRemoteArtwork(from: highResUrl) { [weak self] downloaded in
                guard let self = self, let downloaded = downloaded else { return }
                self.lastArtworkData = downloaded
                Task { @MainActor in
                    MusicCoordinator.shared.updateArtwork(downloaded, forTrackId: trackId)
                }
            }
        }.resume()
    }

    private func fetchSpotifyOEmbed(trackUrl: String) {
        guard let endpoint = URL(string: "https://open.spotify.com/oembed?url=\(trackUrl)") else { return }
        URLSession.shared.dataTask(with: endpoint) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            let title = json["title"] as? String ?? ""
            let artUrl = json["thumbnail_url"] as? String ?? ""
            if !artUrl.isEmpty {
                self.downloadArtworkDirectly(artUrl: artUrl, trackId: "spotify-web-session")
            }
            if !title.isEmpty {
                Task { @MainActor in
                    MusicCoordinator.shared.updateTrackIfChanged(TrackInfo(
                        id: "spotify-web-session",
                        title: title,
                        artist: "Spotify Web",
                        album: "",
                        duration: 180,
                        position: 0,
                        isPlaying: false,
                        artworkData: self.lastArtworkData,
                        source: .spotifyWeb
                    ))
                }
            }
        }.resume()
    }
}
