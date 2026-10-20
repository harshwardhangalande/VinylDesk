import Foundation
import Combine
import AppKit

@MainActor
public final class MusicCoordinator: ObservableObject {
    public static let shared = MusicCoordinator()

    @Published public var currentTrack: TrackInfo = TrackInfo.empty
    @Published public var playbackPosition: TimeInterval = 0.0
    @Published public var preferredSource: MusicSource? = nil
    @Published public var isDemoModeForced: Bool = false
    @Published public var isScratching: Bool = false
    @Published public var scratchAngleOffset: Double = 0.0

    private var pollTimer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var notificationTokens = [NSObjectProtocol]()
    private var tickCount = 0

    public init() {
        self.playbackPosition = currentTrack.position
        setupNotificationObservers()
        startPolling()

        VinylThemeManager.shared.$currentTheme
            .map { $0.showAlbumArtworkInDock }
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                DockIconManager.shared.updateDockIcon(
                    artworkData: self.currentTrack.artworkData,
                    isEnabled: isEnabled
                )
            }
            .store(in: &cancellables)
    }

    deinit {
        for token in notificationTokens {
            DistributedNotificationCenter.default().removeObserver(token)
        }
    }

    private func setupNotificationObservers() {
        // Spotify distributed notification
        let spotifyToken = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTrack()
            }
        }
        notificationTokens.append(spotifyToken)

        // Apple Music distributed notification
        let appleMusicToken = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTrack()
            }
        }
        notificationTokens.append(appleMusicToken)

        // MediaRemote notification
        let mrToken = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTrack()
            }
        }
        notificationTokens.append(mrToken)
    }

    public func startPolling() {
        pollTimer?.cancel()
        pollTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.onTimerTick()
            }
    }

    public func refreshTrack() {
        guard !isDemoModeForced else { return }

        // 1. Honor user-selected preferred source if set
        if let pref = preferredSource {
            switch pref {
            case .spotifyWeb, .appleMusicWeb:
                if let webTrack = WebMusicService.shared.fetchCurrentTrack() {
                    self.updateTrackIfChanged(webTrack)
                    return
                }
            case .spotify:
                if SpotifyService.shared.isRunning, let spotifyTrack = SpotifyService.shared.fetchCurrentTrack() {
                    self.updateTrackIfChanged(spotifyTrack)
                    return
                }
            case .appleMusic:
                if AppleMusicService.shared.isRunning, let musicTrack = AppleMusicService.shared.fetchCurrentTrack() {
                    self.updateTrackIfChanged(musicTrack)
                    return
                }
            case .none:
                break
            }
        }

        // 2. Auto-Detection: Priority goes to whichever source is ACTIVELY PLAYING
        if SpotifyService.shared.isRunning, let spotifyTrack = SpotifyService.shared.fetchCurrentTrack(), spotifyTrack.isPlaying {
            self.updateTrackIfChanged(spotifyTrack)
            return
        }

        if let webTrack = WebMusicService.shared.fetchCurrentTrack(), webTrack.isPlaying {
            self.updateTrackIfChanged(webTrack)
            return
        }

        if AppleMusicService.shared.isRunning, let musicTrack = AppleMusicService.shared.fetchCurrentTrack(), musicTrack.isPlaying {
            self.updateTrackIfChanged(musicTrack)
            return
        }

        // 3. If none is playing, check if Spotify Web or Apple Music Web is open in a browser
        if let webTrack = WebMusicService.shared.fetchCurrentTrack() {
            self.updateTrackIfChanged(webTrack)
            return
        }

        // 4. Check native Spotify paused track
        if SpotifyService.shared.isRunning, let spotifyTrack = SpotifyService.shared.fetchCurrentTrack() {
            self.updateTrackIfChanged(spotifyTrack)
            return
        }

        // 5. Check native Apple Music paused track
        if AppleMusicService.shared.isRunning, let musicTrack = AppleMusicService.shared.fetchCurrentTrack() {
            self.updateTrackIfChanged(musicTrack)
            return
        }

        // 6. Nothing active -> Idle empty state
        if currentTrack != TrackInfo.empty {
            self.updateTrackIfChanged(TrackInfo.empty)
        }
    }

    public func updateTrackIfChanged(_ newTrack: TrackInfo) {
        let metadataChanged = currentTrack.id != newTrack.id ||
            currentTrack.title != newTrack.title ||
            currentTrack.artist != newTrack.artist ||
            currentTrack.isPlaying != newTrack.isPlaying ||
            currentTrack.source != newTrack.source ||
            (newTrack.artworkData != nil && currentTrack.artworkData == nil)

        if metadataChanged {
            self.currentTrack = newTrack
            self.playbackPosition = newTrack.position
            SharedWidgetStorage.shared.saveTrack(newTrack)
            DockIconManager.shared.updateDockIcon(
                artworkData: newTrack.artworkData,
                isEnabled: VinylThemeManager.shared.currentTheme.showAlbumArtworkInDock
            )
        } else {
            // Only update position if drifted significantly (> 3 seconds)
            if abs(self.playbackPosition - newTrack.position) > 3.0 {
                self.playbackPosition = newTrack.position
                self.currentTrack.position = newTrack.position
            }
        }
    }

    public func updateArtwork(_ data: Data, forTrackId trackId: String) {
        if currentTrack.id == trackId {
            self.currentTrack.artworkData = data
            SharedWidgetStorage.shared.saveTrack(currentTrack)
            DockIconManager.shared.updateDockIcon(
                artworkData: data,
                isEnabled: VinylThemeManager.shared.currentTheme.showAlbumArtworkInDock
            )
        }
    }

    private func onTimerTick() {
        guard !isScratching else { return }

        if currentTrack.isPlaying {
            var newPos = playbackPosition + 1.0
            if newPos >= currentTrack.duration {
                newPos = 0
            }
            playbackPosition = newPos
            currentTrack.position = newPos
        }

        tickCount += 1
        if tickCount % 2 == 0 {
            refreshTrack()
        }
    }

    // MARK: - Playback Controls

    public func togglePlayPause() {
        if currentTrack.source == .spotify {
            SpotifyService.shared.togglePlayPause()
            currentTrack.isPlaying.toggle()
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.togglePlayPause()
            currentTrack.isPlaying.toggle()
        } else if currentTrack.source == .spotifyWeb || currentTrack.source == .appleMusicWeb {
            WebMusicService.shared.togglePlayPause(for: currentTrack)
            currentTrack.isPlaying.toggle()
        } else {
            MediaRemoteBridge.shared.togglePlayPause()
        }
        SharedWidgetStorage.shared.saveTrack(currentTrack)
    }

    public func nextTrack() {
        if currentTrack.source == .spotify {
            SpotifyService.shared.nextTrack()
            refreshTrack()
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.nextTrack()
            refreshTrack()
        } else if currentTrack.source == .spotifyWeb || currentTrack.source == .appleMusicWeb {
            WebMusicService.shared.nextTrack(for: currentTrack)
            refreshTrack()
        } else {
            MediaRemoteBridge.shared.nextTrack()
        }
    }

    public func previousTrack() {
        if currentTrack.source == .spotify {
            SpotifyService.shared.previousTrack()
            refreshTrack()
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.previousTrack()
            refreshTrack()
        } else if currentTrack.source == .spotifyWeb || currentTrack.source == .appleMusicWeb {
            WebMusicService.shared.previousTrack(for: currentTrack)
            refreshTrack()
        } else {
            MediaRemoteBridge.shared.previousTrack()
        }
    }

    public func seek(to progress: Double) {
        let clamped = max(0.0, min(progress, 1.0))
        let targetSeconds = currentTrack.duration * clamped
        playbackPosition = targetSeconds
        currentTrack.position = targetSeconds

        if currentTrack.source == .spotify {
            SpotifyService.shared.seek(to: targetSeconds)
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.seek(to: targetSeconds)
        }
    }
}
