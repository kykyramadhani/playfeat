import Testing
@testable import PlayFeat

@MainActor
struct KitchenSoundscapeTests {
    private func advance(_ day: KitchenDay, to end: Double) {
        day.start()
        day.tick(at: 0)
        var time = 0.1
        while time <= end + 0.001 {
            day.tick(at: time)
            time += 0.1
        }
    }

    @Test func anArrivalDoesNotRepeatEveryFrameOrAfterPause() {
        let day = makeDay()
        let sounds = SoundRecorder()
        let audio = KitchenSoundscape(sounds: sounds)
        day.start()
        audio.update(day: day, cookers: [:])
        audio.update(day: day, cookers: [:])
        day.pause()
        audio.update(day: day, cookers: [:])
        day.start()
        audio.update(day: day, cookers: [:])
        #expect(sounds.played == [.customerArrive])
    }

    @Test func angryCustomersHaveTheirOwnArrivalCue() {
        let day = makeDay(makeLevel(angryAt: [1]))
        let sounds = SoundRecorder()
        let audio = KitchenSoundscape(sounds: sounds)
        day.start()
        audio.update(day: day, cookers: [:])
        #expect(sounds.played == [.angryArrive])
    }

    @Test func redPatienceAndDepartureAreEachAnnouncedOnce() {
        let day = makeDay(makeLevel(patienceSec: 10))
        let sounds = SoundRecorder()
        let audio = KitchenSoundscape(sounds: sounds)
        advance(day, to: 8.2)
        audio.update(day: day, cookers: [:])
        audio.update(day: day, cookers: [:])
        #expect(sounds.played.filter { $0 == .patienceRed }.count == 1)
        var time = 8.3
        while time < 10.2 { day.tick(at: time); time += 0.1 }
        audio.update(day: day, cookers: [:])
        audio.update(day: day, cookers: [:])
        #expect(sounds.played.filter { $0 == .customerLeaves }.count == 1)
    }

    @Test func cookingLoopsReadyWarningAndRuinFollowTheToolClock() {
        let day = makeDay()
        let sounds = SoundRecorder()
        let audio = KitchenSoundscape(sounds: sounds)
        var grill = CookingTool.flatbreadGrill()
        grill.place(KitchenMenu.rawFlatbread, onSlot: 0, at: 0, cookedBefore: 0)
        day.start()
        audio.update(day: day, cookers: [.grill: grill])
        #expect(sounds.loops["kitchen.grill.cooking"] == .bakeLoop)

        advance(day, to: 6.2)
        audio.update(day: day, cookers: [.grill: grill])
        audio.update(day: day, cookers: [.grill: grill])
        #expect(sounds.played.filter { $0 == .bakeReady }.count == 1)
        #expect(sounds.loops["kitchen.grill.cooking"] == nil)

        // Use the same wall-clock baseline so deadlines remain in play time.
        var time = 6.3
        while time <= 18.3 {
            day.tick(at: time)
            audio.update(day: day, cookers: [.grill: grill])
            if time > 14.2, time < 17.8 { #expect(sounds.loops["kitchen.grill.warning"] == .bakeWarning) }
            time += 0.1
        }
        #expect(sounds.played.filter { $0 == .bakeBurnt }.count == 1)
        #expect(sounds.loops.isEmpty)
    }

    @Test func pausingStopsBothToolsAndReaddingCookedFoodDoesNotDing() {
        let day = makeDay()
        let sounds = SoundRecorder()
        let audio = KitchenSoundscape(sounds: sounds)
        var grill = CookingTool.flatbreadGrill()
        var pot = CookingTool.noodlePot()
        grill.place(KitchenMenu.rawFlatbread, onSlot: 0, at: 0, cookedBefore: 0)
        pot.place(KitchenMenu.rawNoodles, onSlot: 0, at: 0, cookedBefore: 0)
        day.start()
        audio.update(day: day, cookers: [.grill: grill, .pot: pot])
        #expect(sounds.loops["kitchen.pot.cooking"] == .boilingPot)
        day.pause()
        audio.update(day: day, cookers: [.grill: grill, .pot: pot])
        #expect(sounds.loops.isEmpty)
        audio.clearCooking()
        grill.place(KitchenMenu.bakedFlatbread, onSlot: 0, at: 0, cookedBefore: 6)
        day.start()
        audio.update(day: day, cookers: [.grill: grill])
        #expect(!sounds.played.contains(.bakeReady))
    }
}
