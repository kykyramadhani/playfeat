//
//  KitchenDayTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//
//  A story day by the prototype's rules: the clock, the refill customer
//  flow with its overtime, and the scoring (dish points, zone tips, the
//  penalty for a lost customer that never takes the score below zero).
//

import Testing
@testable import PlayFeat

@MainActor
struct KitchenDayTests {

    /// Plays the day from 0 to `seconds` in small steps, as the scene would.
    private func run(_ day: KitchenDay, to seconds: Double, from start: Double = 0) {
        day.start()
        var time = start
        while time <= seconds {
            day.tick(at: time)
            time += 0.2
        }
    }

    // MARK: - Clock

    @Test func theClockOnlyRunsOnceTheDayHasStarted() {
        let day = makeDay()
        day.tick(at: 100)
        day.tick(at: 100.2)
        #expect(day.elapsed == 0)

        day.start()
        day.tick(at: 100.4)

        #expect(abs(day.elapsed - 0.2) < 0.0001)
        #expect(abs(day.timeLeft - 89.8) < 0.0001)
    }

    @Test func pausingHoldsTheClockWithoutCreditingThePause() {
        let day = makeDay()
        day.start()
        day.tick(at: 0)
        day.tick(at: 0.2)

        day.pause()
        day.tick(at: 30)
        day.start()
        day.tick(at: 30.1)

        #expect(abs(day.elapsed - 0.3) < 0.0001)
    }

    // MARK: - Refill flow

    @Test func theFirstCustomerOrdersTheFirstOrderAtTheOpeningBell() {
        let day = makeDay()

        #expect(day.presentCustomers.map(\.dish) == [KitchenMenu.pepperFlatbread])
    }

    /// The other counter spots fill `refillDelaySec` apart.
    @Test func theOtherSpotsFillOneDelayApart() {
        let day = makeDay(makeLevel(counterSpots: 2, orderPool: [KitchenMenu.mushroomFlatbread: 1]))
        run(day, to: 1.8)
        #expect(day.presentCustomers.count == 1)

        run(day, to: 2.2, from: 2)

        #expect(day.presentCustomers.map(\.dish).sorted() == [KitchenMenu.mushroomFlatbread, KitchenMenu.pepperFlatbread])
    }

    @Test func aServedCustomersSpotRefillsAfterTheDelay() {
        let day = makeDay()
        run(day, to: 1)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        run(day, to: 2.8, from: 1.2)
        #expect(day.presentCustomers.isEmpty)
        run(day, to: 3.4, from: 3)

        #expect(day.presentCustomers.count == 1)
    }

    /// Nobody new steps up in the day's last 20 s, so every order taken can
    /// still be made: a spot freed at 69 s would refill at 71 s, too late.
    @Test func noNewCustomerStepsUpAfterSeventySeconds() {
        let day = makeDay(makeLevel(patienceSec: 200))
        run(day, to: 69)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        run(day, to: 85, from: 69.2)

        #expect(day.presentCustomers.isEmpty)
    }

    /// A spot freed at 67 s refills at 69 s, still before the cutoff.
    @Test func aRefillDueBeforeSeventySecondsStillStepsUp() {
        let day = makeDay(makeLevel(patienceSec: 200))
        run(day, to: 67)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        run(day, to: 69.6, from: 67.2)

        #expect(day.presentCustomers.count == 1)
    }

    @Test func theLevelsAngryCustomersOrderTheDessert() {
        let day = makeDay(makeLevel(counterSpots: 2, angryAt: [2], refillDelaySec: 0))

        let angry = day.presentCustomers.first { $0.type == .angry }
        #expect(angry?.dish == Planet.kepler186f.kitchen.angryOrder)
        #expect(angry?.patienceSec == 25)
    }

    /// No one new steps up after the day's 90 s; whoever is at the counter
    /// can still be served, and the day ends once they're gone.
    @Test func overtimeLastsUntilTheCounterIsEmpty() {
        let day = makeDay(makeLevel(patienceSec: 200))
        run(day, to: 91)
        #expect(day.timeLeft == 0)
        #expect(!day.isOver)

        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)
        run(day, to: 95, from: 91.2)

        #expect(day.presentCustomers.isEmpty)
        #expect(day.isOver)
    }

    // MARK: - Leaving after a serve

    /// The served alien stays while the dish goes in; its order sheet goes
    /// first, then the alien.
    @Test func aServedCustomerLeavesTheirSheetFirstThenTheScreen() {
        let day = makeDay()
        run(day, to: 1)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        #expect(day.presentCustomers.isEmpty)
        #expect(day.aliensOnScreen.map(\.seat) == [0])
        #expect(day.orderSheetsOnScreen.map(\.seat) == [0])

        run(day, to: 2.2, from: 1.2)
        #expect(day.orderSheetsOnScreen.isEmpty)
        #expect(day.aliensOnScreen.map(\.seat) == [0])

        run(day, to: 2.6, from: 2.4)
        #expect(day.aliensOnScreen.isEmpty)
    }

    @Test func aServedCustomersFaceStaysAsItWasWhenServed() {
        let day = makeDay()
        run(day, to: 1)
        let customer = day.presentCustomers[0]
        let patienceWhenServed = customer.patienceLeft(at: day.elapsed)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        run(day, to: 2, from: 1.2)

        #expect(day.patienceShown(for: customer) == patienceWhenServed)
    }

    // MARK: - Scoring

    /// Pepper Flatbread is a flatbread (10) and a pepper (10).
    @Test func servingPaysTheDishsIngredientPoints() {
        let day = makeDay()
        run(day, to: 1)

        #expect(day.serve(KitchenMenu.pepperFlatbread, at: 0))
        #expect(day.points == 20)
        #expect(day.presentCustomers.isEmpty)
    }

    /// Over half the patience left is the green zone's 5-point tip.
    @Test func aQuickServeTipsTheGreenZone() {
        let day = makeDay()
        run(day, to: 5)

        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        #expect(day.tips == 5)
        #expect(day.total == 25)
    }

    /// Between 20% and 50% of the patience left is the yellow zone's 2 points.
    @Test func aSlowServeTipsTheYellowZone() {
        let day = makeDay()
        run(day, to: 30)

        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        #expect(day.tips == 2)
    }

    @Test func anAngryCustomersTipCountsDouble() {
        let day = makeDay(makeLevel(firstOrder: KitchenMenu.slimyTentacles, angryAt: [1]))
        run(day, to: 1)

        _ = day.serve(KitchenMenu.slimyTentacles, at: 2)

        #expect(day.tips == 10)
    }

    @Test func aDishTheCustomerDidntOrderIsTurnedAway() {
        let day = makeDay()
        run(day, to: 1)

        #expect(!day.serve(KitchenMenu.mushroomFlatbread, at: 0))
        #expect(day.points == 0)
    }

    /// A customer who gives up takes 10 points off, but never below zero.
    @Test func aLostCustomerCostsTenPointsButNeverBelowZero() {
        let day = makeDay(makeLevel(patienceSec: 5))
        run(day, to: 6)

        #expect(day.ordersMissed == 1)
        #expect(day.points == 0)
        #expect(day.pointsLost == 0)
    }

    @Test func aLostCustomerAfterAServeTakesTheirTenPoints() {
        let day = makeDay(makeLevel(patienceSec: 5))
        run(day, to: 1)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        run(day, to: 9, from: 1.2)

        #expect(day.ordersMissed == 1)
        #expect(day.points == 10)
        #expect(day.pointsLost == 10)
    }

    @Test func starsCountFromTheTotal() {
        let day = makeDay()
        run(day, to: 1)
        _ = day.serve(KitchenMenu.pepperFlatbread, at: 0)

        // 20 points + 5 tip = 25: one star of [20, 40, 60].
        #expect(day.stars == 1)
    }
}
