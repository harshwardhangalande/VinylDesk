import Foundation
import Combine
import AppKit

@MainActor
public final class MusicCoordinator: ObservableObject {
    public static let shared = MusicCoordinator()

    @Published public var currentTrack: TrackInfo = TrackInfo.demoTrack
    @Published public var isDemoModeForced: Bool = false
    @Published public var isScratching: Bool = false
    @Published public var scratchAngleOffset: Double = 0.0

    private var pollTimer: AnyCancellable?
    private var demoTimer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupNotificationObservers()
        startPolling()
    }

    private func setupNotificationObservers() {
        // Spotify distributed notification
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTrack()
            }
        }

        // Apple Music distributed notification
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTrack()
            }
        }
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

        // Priority 1: Spotify if playing or running
        if SpotifyService.shared.isRunning, let spotifyTrack = SpotifyService.shared.fetchCurrentTrack() {
            if spotifyTrack.isPlaying || currentTrack.source == .spotify {
                self.updateTrackIfChanged(spotifyTrack)
                return
            }
        }

        // Priority 2: Apple Music
        if AppleMusicService.shared.isRunning, let musicTrack = AppleMusicService.shared.fetchCurrentTrack() {
            if musicTrack.isPlaying || currentTrack.source == .appleMusic {
                self.updateTrackIfChanged(musicTrack)
                return
            }
        }

        // If neither is running and current is not demo, revert gracefully to demo
        if !SpotifyService.shared.isRunning && !AppleMusicService.shared.isRunning {
            if currentTrack.source != .demo {
                self.currentTrack = TrackInfo.demoTrack
            }
        }
    }

    public func updateTrackIfChanged(_ newTrack: TrackInfo) {
        if currentTrack.id != newTrack.id ||
           currentTrack.title != newTrack.title ||
           currentTrack.artist != newTrack.artist ||
           currentTrack.isPlaying != newTrack.isPlaying ||
           currentTrack.source != newTrack.source {
            self.currentTrack = newTrack
        } else {
            self.currentTrack.position = newTrack.position
        }
    }

    private func onTimerTick() {
        guard !isScratching else { return }

        if currentTrack.isPlaying {
            var newPos = currentTrack.position + 1.0
            if newPos >= currentTrack.duration {
                newPos = 0
            }
            currentTrack.position = newPos
        }
    }

    // MARK: - Playback Controls

    public func togglePlayPause() {
        if isDemoModeForced || currentTrack.source == .demo {
            currentTrack.isPlaying.toggle()
        } else if currentTrack.source == .spotify {
            SpotifyService.shared.togglePlayPause()
            currentTrack.isPlaying.toggle()
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.togglePlayPause()
            currentTrack.isPlaying.toggle()
        }
    }

    public func nextTrack() {
        if isDemoModeForced || currentTrack.source == .demo {
            currentTrack.position = 0
            currentTrack.isPlaying = true
        } else if currentTrack.source == .spotify {
            SpotifyService.shared.nextTrack()
            refreshTrack()
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.nextTrack()
            refreshTrack()
        }
    }

    public func previousTrack() {
        if isDemoModeForced || currentTrack.source == .demo {
            currentTrack.position = 0
        } else if currentTrack.source == .spotify {
            SpotifyService.shared.previousTrack()
            refreshTrack()
        } else if currentTrack.source == .appleMusic {
            AppleMusicService.shared.previousTrack()
            refreshTrack()
        }
    }

    public func seek(to progress: Double) {
        let clamped = max(0.0, min(progress, 1.0))
        let targetSeconds = currentTrack.duration * clamped
        currentTrack.position = targetSeconds

        if !isDemoModeForced {
            if currentTrack.source == .spotify {
                SpotifyService.shared.seek(to: targetSeconds)
            } else if currentTrack.source == .appleMusic {
                AppleMusicService.shared.seek(to: targetSeconds)
            }
        }
    }
}
