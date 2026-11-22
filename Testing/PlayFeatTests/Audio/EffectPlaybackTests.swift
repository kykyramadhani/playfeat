import AVFoundation
import Testing
@testable import PlayFeat

@MainActor
struct EffectPlaybackTests {
    @Test(arguments: [MusicTrack.story, MusicTrack.buffet])
    func returningToMenuKeepsItsTrackPlaying(gameplayTrack: String) {
        let audio = AudioManager()
        audio.musicVolume = 0
        defer { audio.stopAll() }

        audio.startMusic(MusicTrack.menu)
        #expect(audio.currentMusicName == MusicTrack.menu)
        audio.stopMusic(ifPlaying: MusicTrack.menu)
        #expect(audio.currentMusicName == nil) // Menu fade starts before the countdown.

        audio.startMusic(gameplayTrack)
        #expect(audio.currentMusicName == gameplayTrack)
        // During the return transition the menu can appear before the old
        // gameplay view disappears. Its teardown must leave the music alone.
        audio.startMusic(MusicTrack.menu)
        audio.stopMusic(ifPlaying: gameplayTrack)
        #expect(audio.currentMusicName == MusicTrack.menu)
    }

    @Test(arguments: SoundEffect.allCases)
    func everyEffectResolvesAndDecodes(effect: SoundEffect) throws {
        let url = try #require(effect.resourceURL(), "Missing \(effect.rawValue)")
        let file = try AVAudioFile(forReading: url)
        #expect(file.length > 0)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 64))
        try file.read(into: buffer, frameCount: 64)
        #expect(buffer.frameLength > 0)
    }

    @Test func speedOverridesAndAnimationTimingKeepPitchIndependent() {
        #expect(SoundEffect.dayEnd.playbackRate == 5)
        #expect(SoundEffect.angryArrive.playbackRate == 2)
        let unit = AVAudioUnitTimePitch()
        unit.rate = SoundEffect.dayEnd.playbackRate
        unit.pitch = EffectPlayback.pitchCents(semitones: 2)
        #expect(unit.rate == 5) // A real audio unit must accept x5, not clamp to x2.
        #expect(unit.pitch == 200)
        let fuelRate = EffectPlayback.rate(sourceDuration: 1.302, targetDuration: 0.25, defaultRate: 1)
        #expect(abs(Double(fuelRate) - 5.208) < 0.001)
        #expect(EffectPlayback.pitchCents(semitones: -5) == -100)
        #expect(EffectPlayback.pitchCents(semitones: 5) == 200)
    }

    @Test func reportModesAndRetainedMusicStayDistinct() throws {
        #expect(SoundEffect.storyReport.rawValue == "sfx_round_over")
        #expect(SoundEffect.runOver.rawValue == "sfx_run_over")
        #expect(SoundEffect.storyReport.resourceURL()?.lastPathComponent == "sfx_round_over.wav")
        #expect(SoundEffect.runOver.resourceURL()?.lastPathComponent == "sfx_run_over.wav")
        #expect(MusicTrack.buffet == "music_buffet")
        for name in [MusicTrack.menu, MusicTrack.story, MusicTrack.buffet] {
            let url = try #require(Bundle.main.url(forResource: name, withExtension: "wav"))
            #expect(try AVAudioFile(forReading: url).length > 0)
        }
        #expect(Bundle.main.url(forResource: "music buffet", withExtension: "wav") == nil)
        #expect(Bundle.main.url(forResource: "dry-fart", withExtension: "wav") == nil)
    }

    @Test func overlappingVoicesAndLoopsReleaseTheirGraph() {
        let player = EffectPlayer()
        player.volume = 0
        player.preload()
        player.play(.dayEnd)
        player.play(.angryArrive)
        player.play(.gasCollected, duration: 0.25)
        #expect(player.activeVoiceCount == 3)
        player.startLoop(.bakeLoop, key: "kitchen.grill")
        player.startLoop(.boilingPot, key: "kitchen.pot")
        player.startLoop(.bakeLoop, key: "kitchen.grill")
        #expect(player.activeLoopCount == 2)
        #expect(player.activeVoiceCount == 5)
        player.stopLoops(prefix: "kitchen.")
        #expect(player.activeLoopCount == 0)
        player.suspend()
        #expect(player.activeVoiceCount == 0)
        player.play(.uiClick)
        #expect(player.activeVoiceCount == 0)
        player.resume()
        player.play(.uiClick)
        #expect(player.activeVoiceCount == 1)
        for _ in 0..<20 { player.play(.uiClick) }
        #expect(player.activeVoiceCount == 16)
        #expect(player.activePitchCents.allSatisfy { (-100...200).contains($0) })
        #expect(Set(player.activePitchCents).count > 1)
        player.stopAll()
        #expect(player.activeVoiceCount == 0)
    }
}
