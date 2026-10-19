import Foundation
import AVFoundation

public final class SoundFXEngine: @unchecked Sendable {
    public static let shared = SoundFXEngine()

    private var audioEngine: AVAudioEngine?
    private var noiseNode: AVAudioPlayerNode?
    private var scratchNode: AVAudioPlayerNode?
    private var isPlayingCrackle: Bool = false

    public var isCrackleEnabled: Bool = true {
        didSet {
            if isCrackleEnabled {
                startCrackle()
            } else {
                stopCrackle()
            }
        }
    }

    public var crackleVolume: Float = 0.35 {
        didSet {
            noiseNode?.volume = crackleVolume
        }
    }

    private init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let noisePlayer = AVAudioPlayerNode()
        let scratchPlayer = AVAudioPlayerNode()

        engine.attach(noisePlayer)
        engine.attach(scratchPlayer)

        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        engine.connect(noisePlayer, to: mainMixer, format: format)
        engine.connect(scratchPlayer, to: mainMixer, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.noiseNode = noisePlayer
            self.scratchNode = scratchPlayer
        } catch {
            print("Failed to start SoundFXEngine audio engine: \(error)")
        }
    }

    // MARK: - Procedural Needle Drop Sound

    public func playNeedleDrop() {
        guard let engine = audioEngine, engine.isRunning else { return }

        let sampleRate: Double = 44100
        let duration: Double = 0.25
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // 70Hz damped low-end thump + brief initial click
            let decay = exp(-t * 28.0)
            let thump = sin(2.0 * .pi * 70.0 * t) * decay * 0.4
            let click = (t < 0.005) ? (Double.random(in: -0.5...0.5) * exp(-t * 800.0)) : 0.0
            let sample = Float(thump + click)
            left[i] = sample
            right[i] = sample
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer) {
            DispatchQueue.main.async {
                player.stop()
                engine.detach(player)
            }
        }
        player.play()
    }

    // MARK: - Procedural Vinyl Crackle Loop

    public func startCrackle() {
        guard isCrackleEnabled, !isPlayingCrackle, let node = noiseNode, let engine = audioEngine, engine.isRunning else { return }

        let sampleRate: Double = 44100
        let duration: Double = 4.0 // 4 second seamless looping buffer
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        var lastSample: Float = 0.0
        for i in 0..<Int(frameCount) {
            // Low-pass filtered pink noise base (subtle turntable rumble)
            let white = Float.random(in: -1.0...1.0)
            lastSample = (lastSample * 0.96) + (white * 0.04)
            var sample = lastSample * 0.12

            // Occasional micro vinyl dust clicks/pops
            if Float.random(in: 0...1) < 0.00045 {
                let pop = Float.random(in: 0.25...0.7) * (Bool.random() ? 1.0 : -1.0)
                sample += pop
            }

            left[i] = sample
            right[i] = sample * Float.random(in: 0.9...1.1)
        }

        node.volume = crackleVolume
        node.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        node.play()
        isPlayingCrackle = true
    }

    public func stopCrackle() {
        noiseNode?.stop()
        isPlayingCrackle = false
    }

    // MARK: - Scratch Sound

    public func playScratchSound(velocity: Double) {
        guard let engine = audioEngine, engine.isRunning else { return }

        let sampleRate: Double = 44100
        let duration: Double = 0.08
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        let freq = max(120.0, min(800.0, abs(velocity) * 15.0))
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let wave = sin(2.0 * .pi * freq * t) * 0.3
            let friction = Float.random(in: -0.15...0.15)
            let sample = Float(wave) + friction
            left[i] = sample
            right[i] = sample
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer) {
            DispatchQueue.main.async {
                player.stop()
                engine.detach(player)
            }
        }
        player.play()
    }
}
