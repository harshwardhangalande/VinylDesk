import Foundation
import AppKit

public final class MediaRemoteBridge: @unchecked Sendable {
    public static let shared = MediaRemoteBridge()

    public struct Snapshot: Equatable, Sendable {
        public let title: String
        public let artist: String
        public let album: String
        public let duration: Double
        public let elapsedTime: Double
        public let isPlaying: Bool
        public let appPID: pid_t
        public let appBundleId: String?
        public let appName: String?

        public var isBrowser: Bool {
            guard let bid = appBundleId?.lowercased() else { return false }
            return bid.contains("safari") ||
                   bid.contains("webkit") ||
                   bid.contains("chrome") ||
                   bid.contains("brave") ||
                   bid.contains("browser") ||
                   bid.contains("edge")
        }
    }

    private typealias MRGetInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRGetPIDFn = @convention(c) (DispatchQueue, @escaping (pid_t) -> Void) -> Void
    private typealias MRSendCommandFn = @convention(c) (UInt32, AnyObject?) -> Bool
    private typealias MRRegisterFn = @convention(c) (DispatchQueue) -> Void

    private var getNowPlayingInfo: MRGetInfoFn?
    private var getNowPlayingPID: MRGetPIDFn?
    private var sendCommandFn: MRSendCommandFn?

    private let lock = NSLock()
    private var _cachedSnapshot: Snapshot?

    public var currentSnapshot: Snapshot? {
        lock.lock()
        defer { lock.unlock() }
        return _cachedSnapshot
    }

    private init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) {
            if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
                getNowPlayingInfo = unsafeBitCast(sym, to: MRGetInfoFn.self)
            }
            if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID") {
                getNowPlayingPID = unsafeBitCast(sym, to: MRGetPIDFn.self)
            }
            if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
                sendCommandFn = unsafeBitCast(sym, to: MRSendCommandFn.self)
            }
            if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
                let reg = unsafeBitCast(sym, to: MRRegisterFn.self)
                reg(DispatchQueue.main)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSnapshot()
        }

        refreshSnapshot()
    }

    public func refreshSnapshot(completion: ((Snapshot?) -> Void)? = nil) {
        guard let getPID = getNowPlayingPID, let getInfo = getNowPlayingInfo else {
            completion?(nil)
            return
        }

        let queue = DispatchQueue(label: "mediaremote.queue", qos: .userInitiated)
        getPID(queue) { [weak self] pid in
            guard let self = self else { return }

            var bundleId: String? = nil
            var appName: String? = nil
            if pid > 0, let app = NSRunningApplication(processIdentifier: pid) {
                bundleId = app.bundleIdentifier
                appName = app.localizedName
            }

            getInfo(queue) { [weak self] info in
                guard let self = self else { return }

                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
                let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
                let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
                let isPlaying = (rate > 0.0)

                let snapshot = Snapshot(
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    elapsedTime: elapsed,
                    isPlaying: isPlaying,
                    appPID: pid,
                    appBundleId: bundleId,
                    appName: appName
                )

                self.lock.lock()
                self._cachedSnapshot = snapshot
                self.lock.unlock()

                completion?(snapshot)
            }
        }
    }

    @discardableResult
    public func togglePlayPause() -> Bool {
        guard let send = sendCommandFn else { return false }
        return send(2, nil) // 2 = kMRTogglePlayPause
    }

    @discardableResult
    public func nextTrack() -> Bool {
        guard let send = sendCommandFn else { return false }
        return send(4, nil) // 4 = kMRNextTrack
    }

    @discardableResult
    public func previousTrack() -> Bool {
        guard let send = sendCommandFn else { return false }
        return send(5, nil) // 5 = kMRPreviousTrack
    }
}
