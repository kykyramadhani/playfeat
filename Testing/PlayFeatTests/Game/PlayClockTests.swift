//
//  PlayClockTests.swift
//  PlayFeatTests
//
//  The play clock every deadline is measured on.
//

import Testing
import Foundation
@testable import PlayFeat

struct PlayClockTests {

    @Test func advancingCreditsTheTimeBetweenTicks() {
        var clock = PlayClock(wallTime: 100)

        clock.advance(to: 100.1)
        clock.advance(to: 100.3)

        #expect(abs(clock.elapsed - 0.3) < 0.0001)
    }

    /// A stall must not hand the player a dish failure they never saw coming.
    @Test func aLongGapIsCappedToOneTick() {
        var clock = PlayClock(wallTime: 100)

        clock.advance(to: 105)

        #expect(clock.elapsed == PlayClock.maxTickDelta)
    }

    /// Paused time is skipped, not credited in one lump on resume.
    @Test func holdingSkipsThePausedTime() {
        var clock = PlayClock(wallTime: 100)
        clock.hold(at: 100.2)   // paused...
        clock.hold(at: 160)     // ...for a minute

        clock.advance(to: 160.1)

        #expect(abs(clock.elapsed - 0.1) < 0.0001)
    }
}
