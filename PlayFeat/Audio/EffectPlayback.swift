import AVFoundation

/// Musical semitones, converted to the cents AVAudioUnitTimePitch expects.
/// Pitch varies per playback, independently of its speed or target duration.
nonisolated enum EffectPlayback {
    static let semitoneRange: ClosedRange<Float> = -1...2

    static func pitchCents(semitones: Float) -> Float {
        min(max(semitones, semitoneRange.lowerBound), semitoneRange.upperBound) * 100
    }

    static func rate(sourceDuration: TimeInterval, targetDuration: TimeInterval?, defaultRate: Float) -> Float {
        guard let targetDuration, targetDuration > 0, sourceDuration > 0 else { return defaultRate }
        return Float(min(max(sourceDuration / targetDuration, 1.0 / 32), 32))
    }
}

/// Each overlapping effect has its own pitch unit. Music stays on its own
/// player, so clicking never changes the music's pitch. Buffers are shared.
final class EffectPlayer {
    private struct Voice {
        let player: AVAudioPlayerNode
        let pitch: AVAudioUnitTimePitch
        let effect: SoundEffect
    }

    private let engine = AVAudioEngine()
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var voices: [UUID: Voice] = [:]
    private var oneShots: [UUID] = []
    private var loops: [String: UUID] = [:]
    private var isSuspended = false

    /// Useful for checking graph cleanup without relying on audible output.
    var activeVoiceCount: Int { voices.count }
    var activeLoopCount: Int { loops.count }
    var activePitchCents: [Float] { voices.values.map { $0.pitch.pitch } }

    var volume: Float = 1 {
        didSet { engine.mainMixerNode.outputVolume = volume }
    }

    func preload() {
        for effect in SoundEffect.allCases {
            guard let url = effect.resourceURL() else {
                print("[Audio] Missing effect: \(effect.rawValue)")
                continue
            }
            do {
                let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                    frameCapacity: AVAudioFrameCount(file.length)) else { continue }
                try file.read(into: buffer)
                buffers[effect] = buffer
            } catch {
                print("[Audio] Cannot decode \(effect.rawValue): \(error)")
            }
        }
    }

    func play(_ effect: SoundEffect, duration: TimeInterval? = nil) {
        // Bound CPU and memory when a control is tapped repeatedly.
        if oneShots.count >= 16, let oldest = oneShots.first { stop(oldest) }
        guard let id = makeVoice(effect, duration: duration) else { return }
        oneShots.append(id)
        guard let buffer = buffers[effect], let voice = voices[id] else { return }
        voice.player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            // Graph mutations must happen off the audio render thread.
            DispatchQueue.main.async { self?.stop(id) }
        }
        voice.player.play()
    }

    func startLoop(_ effect: SoundEffect, key: String) {
        if let id = loops[key], voices[id]?.effect == effect { return }
        stopLoop(key)
        guard let id = makeVoice(effect), let buffer = buffers[effect], let voice = voices[id] else { return }
        loops[key] = id
        voice.player.scheduleBuffer(buffer, at: nil, options: .loops)
        voice.player.play()
    }

    func stopLoop(_ key: String) {
        guard let id = loops.removeValue(forKey: key) else { return }
        stop(id)
    }

    func stopLoops(prefix: String) {
        for key in Array(loops.keys) where key.hasPrefix(prefix) { stopLoop(key) }
    }

    func stopAll() {
        for id in Array(voices.keys) { stop(id) }
        engine.stop()
    }

    func suspend() {
        isSuspended = true
        stopAll()
    }

    func resume() { isSuspended = false }

    private func makeVoice(_ effect: SoundEffect, duration: TimeInterval? = nil) -> UUID? {
        guard !isSuspended, let buffer = buffers[effect] else { return nil }
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = EffectPlayback.pitchCents(semitones: Float.random(in: EffectPlayback.semitoneRange))
        pitch.rate = EffectPlayback.rate(
            sourceDuration: Double(buffer.frameLength) / buffer.format.sampleRate,
            targetDuration: duration, defaultRate: effect.playbackRate
        )
        player.volume = effect.gain
        engine.attach(player)
        engine.attach(pitch)
        engine.connect(player, to: pitch, format: buffer.format)
        engine.connect(pitch, to: engine.mainMixerNode, format: buffer.format)
        let id = UUID()
        voices[id] = Voice(player: player, pitch: pitch, effect: effect)
        do {
            if !engine.isRunning { try engine.start() }
            return id
        } catch {
            stop(id)
            print("[Audio] Cannot start effects: \(error)")
            return nil
        }
    }

    private func stop(_ id: UUID) {
        guard let voice = voices.removeValue(forKey: id) else { return }
        oneShots.removeAll { $0 == id }
        for key in Array(loops.keys) where loops[key] == id { loops[key] = nil }
        voice.player.stop()
        engine.detach(voice.player)
        engine.detach(voice.pitch)
    }
}
