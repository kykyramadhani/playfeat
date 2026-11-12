//
//  GrillTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  The grill's timing: raw, baked at 6 s, warned about at 8 s, burnt at 12 s.
//

import Testing
import Foundation
@testable import PlayFeat

struct GrillTests {

    @Test(arguments: [
        (0.0, Grill.Doneness.cooking),
        (5.9, .cooking),
        (6.0, .cooked),
        (7.9, .cooked),
        (8.0, .overcooking),
        (11.9, .overcooking),
        (12.0, .burnt),
        (60.0, .burnt),
    ])
    func donenessFollowsTimeOnTheGrill(seconds: TimeInterval, expected: Grill.Doneness) {
        #expect(Grill.doneness(after: seconds) == expected)
    }

    @Test func aBakedFlatbreadIsStillBakedWhileTheWarningShows() {
        #expect(Grill.Doneness.overcooking.item == KitchenMenu.bakedFlatbread)
        #expect(Grill.Doneness.overcooking.needsWarning)
        #expect(!Grill.Doneness.cooked.needsWarning)
    }

    @Test func burntFlatbreadIsItsOwnItem() {
        #expect(Grill.Doneness.burnt.item == KitchenMenu.burntFlatbread)
    }

    @Test func onlyARawFlatbreadGoesOnTheGrill() {
        let grill = Grill()

        #expect(grill.accepts(KitchenMenu.rawFlatbread))
        #expect(!grill.accepts(KitchenMenu.bakedFlatbread))
        #expect(!grill.accepts(KitchenMenu.pepper))
    }

    @Test func theGrillCooksOneFlatbreadAtATime() {
        var grill = Grill()
        grill.place(at: 0)

        #expect(!grill.accepts(KitchenMenu.rawFlatbread))
    }

    /// Timed from when it went on, in play time.
    @Test func donenessCountsFromWhenItWasPutOn() {
        var grill = Grill()
        grill.place(at: 10)

        #expect(grill.doneness(at: 15) == .cooking)
        #expect(grill.doneness(at: 16) == .cooked)
    }

    @Test func anEmptyGrillCooksNothing() {
        #expect(Grill().doneness(at: 100) == nil)
    }
}
