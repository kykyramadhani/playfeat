//
//  GrillTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  The grill by the prototype's timings: baked at 6 s, glowing 8 s after
//  that, burnt 12 s after that, both stretched by a level's multiplier.
//

import Testing
@testable import PlayFeat

struct GrillTests {

    @Test func aFlatbreadBakesGlowsThenBurns() {
        let grill = Grill()

        #expect(grill.doneness(afterCooking: 5.9) == .cooking)
        #expect(grill.doneness(afterCooking: 6) == .cooked)
        #expect(grill.doneness(afterCooking: 14) == .overcooking)
        #expect(grill.doneness(afterCooking: 18) == .burnt)
    }

    /// Level 1-1 doubles the time a baked flatbread lasts.
    @Test func theBurnMultiplierStretchesTheTimeAfterBaking() {
        let grill = Grill(burnMultiplier: 2)

        #expect(grill.doneness(afterCooking: 6) == .cooked)
        #expect(grill.doneness(afterCooking: 21.9) == .cooked)
        #expect(grill.doneness(afterCooking: 22) == .overcooking)
        #expect(grill.doneness(afterCooking: 30) == .burnt)
    }

    @Test func itTakesRawAndBakedFlatbreadsOnly() {
        let grill = Grill()

        #expect(grill.accepts(KitchenMenu.rawFlatbread))
        #expect(grill.accepts(KitchenMenu.bakedFlatbread))
        #expect(!grill.accepts(KitchenMenu.burntFlatbread))
        #expect(!grill.accepts(KitchenMenu.pepper))
    }

    @Test func cookingCountsFromWhenTheFlatbreadWentOn() {
        var grill = Grill()

        grill.place(onSlot: 0, at: 10, cookedBefore: 0)

        #expect(grill.doneness(onSlot: 0, at: 15) == .cooking)
        #expect(grill.doneness(onSlot: 0, at: 16) == .cooked)
    }

    /// A baked flatbread put back carries on from where it was.
    @Test func aBakedFlatbreadPutBackCarriesOn() {
        var grill = Grill()

        grill.place(onSlot: 0, at: 0, cookedBefore: grill.cookedBefore(KitchenMenu.bakedFlatbread, remembered: 13))

        #expect(grill.doneness(onSlot: 0, at: 1) == .overcooking)
    }

    @Test func clearingASlotEmptiesIt() {
        var grill = Grill()
        grill.place(onSlot: 0, at: 0, cookedBefore: 0)

        grill.clear(0)

        #expect(!grill.isTaken(0))
        #expect(grill.doneness(onSlot: 0, at: 5) == nil)
    }

    @Test func theSecondGrillSpotAddsASlot() {
        var grill = Grill()

        grill.growSlots(to: 2)

        #expect(grill.slots.count == 2)
    }

    // MARK: - Cooking ring

    @Test func theRingFillsYellowWhileBaking() {
        let gauge = Grill().gauge(afterCooking: 3)

        #expect(gauge.phase == .baking)
        #expect(gauge.fraction == 0.5)
    }

    /// Once baked the ring fills red over the 12 s until the flatbread burns.
    @Test func theRingFillsRedTowardsBurning() {
        let gauge = Grill().gauge(afterCooking: 12)

        #expect(gauge.phase == .baked)
        #expect(gauge.fraction == 0.5)
        #expect(!gauge.isAboutToBurn)
    }

    @Test func theWarningSignGoesUpThreeSecondsBeforeBurning() {
        let grill = Grill()

        #expect(!grill.gauge(afterCooking: 14.9).isAboutToBurn)
        #expect(grill.gauge(afterCooking: 15).isAboutToBurn)
    }

    @Test func aBurntFlatbreadsRingIsFull() {
        let gauge = Grill().gauge(afterCooking: 18)

        #expect(gauge.phase == .burnt)
        #expect(gauge.fraction == 1)
    }
}
