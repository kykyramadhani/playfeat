//
//  CookingToolTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  The cooking tools by the design's timings. Planet 1's grill: baked at
//  6 s, glowing 8 s after that, burnt 12 s after that. Planet 2's pot: done
//  at 6 s, glowing 6 s after, mushy 10 s after. Both stretched by a level's
//  multiplier.
//

import Testing
@testable import PlayFeat

private typealias Menu = KitchenMenu

struct CookingToolTests {

    // MARK: - Planet 1 grill

    @Test func aFlatbreadBakesGlowsThenBurns() {
        let grill = CookingTool.flatbreadGrill()

        #expect(grill.doneness(afterCooking: 5.9) == .cooking)
        #expect(grill.doneness(afterCooking: 6) == .cooked)
        #expect(grill.doneness(afterCooking: 14) == .overcooking)
        #expect(grill.doneness(afterCooking: 18) == .ruined)
    }

    /// Level 1-1 doubles the time a baked flatbread lasts.
    @Test func theBurnMultiplierStretchesTheTimeAfterBaking() {
        let grill = CookingTool.flatbreadGrill(burnMultiplier: 2)

        #expect(grill.doneness(afterCooking: 6) == .cooked)
        #expect(grill.doneness(afterCooking: 21.9) == .cooked)
        #expect(grill.doneness(afterCooking: 22) == .overcooking)
        #expect(grill.doneness(afterCooking: 30) == .ruined)
    }

    @Test func itTakesRawAndBakedFlatbreadsOnly() {
        let grill = CookingTool.flatbreadGrill()

        #expect(grill.accepts(Menu.rawFlatbread))
        #expect(grill.accepts(Menu.bakedFlatbread))
        #expect(!grill.accepts(Menu.burntFlatbread))
        #expect(!grill.accepts(Menu.pepper))
    }

    @Test func cookingCountsFromWhenTheFlatbreadWentOn() {
        var grill = CookingTool.flatbreadGrill()

        grill.place(Menu.rawFlatbread, onSlot: 0, at: 10, cookedBefore: 0)

        #expect(grill.doneness(onSlot: 0, at: 15) == .cooking)
        #expect(grill.doneness(onSlot: 0, at: 16) == .cooked)
    }

    /// A baked flatbread put back carries on from where it was.
    @Test func aBakedFlatbreadPutBackCarriesOn() {
        var grill = CookingTool.flatbreadGrill()

        let cookedBefore = grill.cookedBefore(Menu.bakedFlatbread, remembered: 13)
        grill.place(Menu.bakedFlatbread, onSlot: 0, at: 0, cookedBefore: cookedBefore)

        #expect(grill.doneness(onSlot: 0, at: 1) == .overcooking)
    }

    @Test func clearingASlotEmptiesIt() {
        var grill = CookingTool.flatbreadGrill()
        grill.place(Menu.rawFlatbread, onSlot: 0, at: 0, cookedBefore: 0)

        grill.clear(0)

        #expect(!grill.isTaken(0))
        #expect(grill.doneness(onSlot: 0, at: 5) == nil)
    }

    @Test func theSecondGrillSpotAddsASlot() {
        var grill = CookingTool.flatbreadGrill()

        grill.growSlots(to: 2)

        #expect(grill.slots.count == 2)
    }

    @Test func anItemTheToolDoesNotCookIsNotPlaced() {
        var grill = CookingTool.flatbreadGrill()

        grill.place(Menu.pepper, onSlot: 0, at: 0, cookedBefore: 0)

        #expect(!grill.isTaken(0))
    }

    // MARK: - Planet 2 pot and grill

    @Test func thePotBoilsNoodlesThenTheyGoMushyTenSecondsLater() {
        var pot = CookingTool.noodlePot()
        pot.place(Menu.rawNoodles, onSlot: 0, at: 0, cookedBefore: 0)

        #expect(pot.item(onSlot: 0, at: 5.9) == Menu.rawNoodles)
        #expect(pot.item(onSlot: 0, at: 6) == Menu.boiledNoodles)
        #expect(pot.doneness(onSlot: 0, at: 12) == .overcooking)
        #expect(pot.item(onSlot: 0, at: 16) == Menu.mushyNoodles)
    }

    @Test func thePotTakesNoodlesButNotAClam() {
        let pot = CookingTool.noodlePot()

        #expect(pot.accepts(Menu.rawNoodles))
        #expect(pot.accepts(Menu.boiledNoodles))
        #expect(!pot.accepts(Menu.rawClam))
        #expect(!pot.accepts(Menu.mushyNoodles))
    }

    @Test func planetTwosGrillOpensAClamAndBurnsItTenSecondsLater() {
        var grill = CookingTool(kind: .grill, recipes: [.clam], timing: .underwaterKitchen)
        grill.place(Menu.rawClam, onSlot: 0, at: 0, cookedBefore: 0)

        #expect(!grill.accepts(Menu.rawFlatbread))
        #expect(grill.item(onSlot: 0, at: 6) == Menu.grilledClam)
        #expect(grill.item(onSlot: 0, at: 16) == Menu.burntClam)
    }

    // MARK: - Cooking ring

    @Test func theRingFillsYellowWhileBaking() {
        let gauge = CookingTool.flatbreadGrill().gauge(afterCooking: 3)

        #expect(gauge.phase == .baking)
        #expect(gauge.fraction == 0.5)
    }

    /// Once baked the ring fills red over the 12 s until the flatbread burns.
    @Test func theRingFillsRedTowardsBurning() {
        let gauge = CookingTool.flatbreadGrill().gauge(afterCooking: 12)

        #expect(gauge.phase == .baked)
        #expect(gauge.fraction == 0.5)
        #expect(!gauge.isAboutToBurn)
    }

    @Test func theWarningSignGoesUpThreeSecondsBeforeBurning() {
        let grill = CookingTool.flatbreadGrill()

        #expect(!grill.gauge(afterCooking: 14.9).isAboutToBurn)
        #expect(grill.gauge(afterCooking: 15).isAboutToBurn)
    }

    @Test func aBurntFlatbreadsRingIsFull() {
        let gauge = CookingTool.flatbreadGrill().gauge(afterCooking: 18)

        #expect(gauge.phase == .burnt)
        #expect(gauge.fraction == 1)
    }
}
