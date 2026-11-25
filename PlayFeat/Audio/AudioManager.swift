//
//  AudioManager.swift
//  PlayFeat
//
//  Created by Owen Limantoro on 22/08/26.
//

import AVFoundation

/// Plays independently pitched effects, keyed activity loops and music.
/// EffectPlayer uses AVAudioUnitTimePitch for -1...+2 semitone variation;
/// speed overrides do not change pitch or the duration of animation-fit cues.
///
/// There is exactly one instance, created in `PlayFeatApp` and handed out by
/// dependency injection — never reached for globally:
///
/// - SwiftUI views read it from the environment:
///   `@Environment(AudioManager.self) private var audio`
/// - `KitchenScene` receives it through its `audio` property.
///
/// Buttons don't call it directly: `ClickButton` plays the UI click.
///
///     audio.play(.putOrder)          // one-shot
///     audio.startClockWarning()      // begin looping tick
///     audio.stopClockWarning()       // stop the loop

@Observable
final class AudioManager: NSObject {
    // MARK: - Persistence

    /// UserDefaults keys the Settings screen reads and writes. AudioManager
    /// only reads them, once, at launch — the Settings sliders own writing them.
    static let musicVolumeKey = "settings.musicVolume"
    static let sfxVolumeKey = "settings.sfxVolume"

    // MARK: - Settings

    /// Master toggle. Set to false to mute all SFX (e.g. from a settings screen).
    var isEnabled: Bool = true {
        didSet { if !isEnabled { stopAll() } }
    }

    /// Master volume for one-shot effects, 0.0...1.0.
    ///
    /// The volumes are `@ObservationIgnored` on purpose: their `didSet` clamps
    /// by assigning the property again. Under `@Observable` that assignment
    /// re-enters the setter forever and crashes with EXC_BAD_ACCESS. No view
    /// reads them (SettingsView keeps its own @AppStorage copy), so nothing
    /// needs to observe them anyway.
    @ObservationIgnored var effectsVolume: Float = 1.0 {
        didSet {
            effectsVolume = min(max(effectsVolume, 0), 1)
            effects.volume = effectsVolume
        }
    }

    /// Background-music volume, 0.0...1.0. Kept under the effects so a chime or
    /// the bell always reads clearly over the loop. Changing it takes effect on
    /// any music already playing.
    @ObservationIgnored var musicVolume: Float = 0.45 {
        didSet {
            musicVolume = min(max(musicVolume, 0), 1)
            musicPlayer?.volume = musicVolume
        }
    }

    @ObservationIgnored private let effects = EffectPlayer()

    /// Dedicated player for the looping background music.
    @ObservationIgnored private var musicPlayer: AVAudioPlayer?

    /// The music track currently loaded, so a repeat `startMusic` for the same
    /// track is a no-op rather than a restart from the top.
    @ObservationIgnored private(set) var currentMusicName: String?

    /// The music was faded out by `fadeOutMusic()` and is waiting for
    /// `fadeInMusic()`. Cleared by a fade-in that lands before the fade-out
    /// finishes, so a late pause can't silence music that was meant to return.
    @ObservationIgnored private var isMusicFadedOut = false

    /// How long the music takes to fade out on leaving the app, and back in.
    private static let backgroundFadeDuration: TimeInterval = 0.6

    // MARK: - Init

    override init() {
        super.init()
        configureAudioSession()
        effects.preload()
        loadSavedVolumes()
    }

    // MARK: - Public API: one-shot effects

    /// Every playback gets independent random pitch in -1...+2 semitones.
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        effects.play(effect)
    }

    /// Fit an effect to a UI animation, at a set pitch instead of a random one.
    func play(_ effect: SoundEffect, duration: TimeInterval, semitones: Float) {
        guard isEnabled else { return }
        effects.play(effect, duration: duration, semitones: semitones)
    }

    func startLoop(_ effect: SoundEffect, key: String) {
        guard isEnabled else { return }
        effects.startLoop(effect, key: key)
    }

    func stopLoop(key: String) { effects.stopLoop(key) }

    func stopKitchenLoops() { effects.stopLoops(prefix: "kitchen.") }

    func startClockWarning() { startLoop(.clockRunningOut, key: "clock") }

    func stopClockWarning() { stopLoop(key: "clock") }

    func suspendEffects() { effects.suspend() }

    func resumeEffects() { effects.resume() }

    // MARK: - Public API: background music

    /// Starts (or fades in) the looping background-music track `name`, a
    /// base file name from `MusicTrack`.
    ///
    /// Calling this again for the track already playing does nothing, so it is
    /// safe to call on every round start without restarting the loop.
    func startMusic(
        _ name: String,
        fadeIn: TimeInterval = 1.5
    ) {
        guard isEnabled else { return }

        // Resume a paused track from its current position.
        if name == currentMusicName {
            if isMusicFadedOut { fadeInMusic(); return }
            if musicPlayer?.isPlaying == true { return }
        }

        // Different track: fade the old one out first.
        if currentMusicName != nil { stopMusic() }
        
        guard let wavURL = resourceURL(forResourceNamed: name) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: wavURL)
            player.numberOfLoops = -1  // loop for the whole session
            player.volume = 0  // faded up below
            player.enableRate = true
            player.prepareToPlay()
            player.play()
            player.setVolume(musicVolume, fadeDuration: fadeIn)
            musicPlayer = player
            currentMusicName = name
        } catch {
            print("[AudioManager] Failed to start music \(name): \(error)")
        }
    }

    /// Fades the selected track out. A screen can pass its own track name so
    /// late teardown during an animated transition leaves the new track playing.
    func stopMusic(ifPlaying name: String? = nil, fadeOut: TimeInterval = 0.6) {
        if let name, name != currentMusicName { return }
        stopClockWarning()
        guard let player = musicPlayer else { return }
        musicPlayer = nil
        currentMusicName = nil
        isMusicFadedOut = false

        guard fadeOut > 0 else {
            player.stop()
            return
        }

        player.setVolume(0, fadeDuration: fadeOut)
        // Held by the closure so it survives the fade, then actually stops.
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOut) {
            player.stop()
        }
    }

    /// Sets the background music's playback speed directly. `1.0` is normal
    /// speed, `2.0` is double-time; `AVAudioPlayer` only honours the range
    /// `0.5...2.0`, so anything outside is clamped here rather than silently
    /// ignored by the OS.
    ///
    /// This is an *absolute* setter, not a relative nudge — pass the tempo you
    /// want, not the amount to change by. (The old `changeRate(by:)` added to
    /// the current rate on every call, which pinned it to the 2.0 ceiling after
    /// a round or two.)
    func setMusicRate(_ rate: Float) {
        guard let player = musicPlayer else { return }
        player.rate = min(max(rate, 0.5), 2.0)
    }

    /// Fades the music down and pauses it in place, e.g. when the app goes to
    /// the background. `fadeInMusic()` picks it up where it left off.
    func fadeOutMusic() {
        guard let player = musicPlayer, player.isPlaying else { return }
        isMusicFadedOut = true
        player.setVolume(0, fadeDuration: Self.backgroundFadeDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.backgroundFadeDuration) { [weak self] in
            guard let self, isMusicFadedOut, musicPlayer === player else { return }
            player.pause()
        }
    }

    /// Fades music paused by `fadeOutMusic()` back up to the player's volume.
    /// Does nothing if the music wasn't faded out.
    func fadeInMusic() {
        guard isMusicFadedOut else { return }
        isMusicFadedOut = false
        guard isEnabled, let player = musicPlayer else { return }
        // Already playing if we're back before the fade-out finished, or if
        // iOS suspended the app before the pause ran — play() is a no-op then.
        player.play()
        player.setVolume(musicVolume, fadeDuration: Self.backgroundFadeDuration)
    }

    /// Stops every sound immediately (e.g. on returning to the main menu).
    func stopAll() {
        effects.stopAll()
        stopClockWarning()
        stopMusic(fadeOut: 0)
    }
}

extension AudioManager {
    /// Applies the volumes the player last chose in Settings. Absent keys leave
    /// the defaults above in place — a fresh install starts at those.
    private func loadSavedVolumes() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: Self.sfxVolumeKey) != nil {
            effectsVolume = Float(defaults.double(forKey: Self.sfxVolumeKey))
        }
        
        if defaults.object(forKey: Self.musicVolumeKey) != nil {
            musicVolume = Float(defaults.double(forKey: Self.musicVolumeKey))
        }
    }

    /// `.ambient` lets game sound mix with the user's music and respect the mute
    /// switch — the usual choice for a casual game. Switch to `.playback` if you
    /// want sound to play even when the silent switch is on.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(
                .ambient,
                mode: .default
            )
            
            try session.setActive(true)
            
        } catch {
            print("[AudioManager] Failed to configure audio session: \(error)")
        }
    }

    /// Music streams from disk; effects decode WAV/MP3 through AVAudioFile.
    private func resourceURL(forResourceNamed name: String) -> URL? {
        for ext in ["wav", "mp3", "m4a", "caf"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        }
        print("[AudioManager] Missing music: \(name)")
        return nil
    }
}
