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

    /// Serves `dish` to whoever ordered it, wherever they stand.
    @discardableResult
    private func serve(_ dish: String, in day: KitchenDay) -> Bool {
        guard let seat = day.presentCustomers.first(where: { $0.dish == dish })?.seat else { return false }
        return day.serve(dish, at: seat)
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
        serve(KitchenMenu.pepperFlatbread, in: day)

        run(day, to: 2.8, from: 1.2)
        #expect(day.presentCustomers.isEmpty)
        run(day, to: 3.4, from: 3)

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

        serve(KitchenMenu.pepperFlatbread, in: day)
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
        let customer = day.presentCustomers[0]
        serve(KitchenMenu.pepperFlatbread, in: day)

        #expect(day.presentCustomers.isEmpty)
        #expect(day.aliensOnScreen == [customer])
        #expect(day.orderSheetsOnScreen == [customer])
        #expect(day.isServed(customer))

        run(day, to: 2.2, from: 1.2)
        #expect(day.orderSheetsOnScreen.isEmpty)
        #expect(day.aliensOnScreen == [customer])

        run(day, to: 2.6, from: 2.4)
        #expect(day.aliensOnScreen.isEmpty)
    }

    /// The first customer already waits at the opening bell, but nobody
    /// shows at the counter until the countdown is over and the day starts.
    @Test func nobodyShowsUntilTheCountdownIsOver() {
        let day = makeDay()
        #expect(!day.presentCustomers.isEmpty)
        #expect(day.aliensOnScreen.isEmpty)
        #expect(day.orderSheetsOnScreen.isEmpty)

        day.start()

        #expect(day.aliensOnScreen == day.presentCustomers)
    }

    @Test func aServedCustomersFaceStaysAsItWasWhenServed() {
        let day = makeDay()
        run(day, to: 1)
        let customer = day.presentCustomers[0]
        let patienceWhenServed = customer.patienceLeft(at: day.elapsed)
        serve(KitchenMenu.pepperFlatbread, in: day)

        run(day, to: 2, from: 1.2)

        #expect(day.patienceShown(for: customer) == patienceWhenServed)
    }

    // MARK: - Scoring

    /// Pepper Flatbread is a flatbread (10) and a pepper (10).
    @Test func servingPaysTheDishsIngredientPoints() {
        let day = makeDay()
        run(day, to: 1)

        #expect(serve(KitchenMenu.pepperFlatbread, in: day))
        #expect(day.points == 20)
        #expect(day.presentCustomers.isEmpty)
    }

    /// The marathon report's average wait: how long each served customer stood at the counter.
    @Test func theAverageWaitCountsFromWhenACustomerStoodAtTheCounter() {
        let day = makeDay()
        run(day, to: 5)

        serve(KitchenMenu.pepperFlatbread, in: day)

        #expect(abs(day.averageWaitSec - day.elapsed) < 0.001)
    }

    /// Over half the patience left is the green zone's 5-point tip.
    @Test func aQuickServeTipsTheGreenZone() {
        let day = makeDay()
        run(day, to: 5)

        serve(KitchenMenu.pepperFlatbread, in: day)

        #expect(day.tips == 5)
        #expect(day.total == 25)
    }

    /// Between 20% and 50% of the patience left is the yellow zone's 2 points.
    @Test func aSlowServeTipsTheYellowZone() {
        let day = makeDay()
        run(day, to: 30)

        serve(KitchenMenu.pepperFlatbread, in: day)

        #expect(day.tips == 2)
    }

    @Test func anAngryCustomersTipCountsDouble() {
        let day = makeDay(makeLevel(firstOrder: KitchenMenu.slimyTentacles, angryAt: [1]))
        run(day, to: 1)

        serve(KitchenMenu.slimyTentacles, in: day)

        #expect(day.tips == 10)
    }

    @Test func aDishTheCustomerDidntOrderIsTurnedAway() {
        let day = makeDay()
        run(day, to: 1)

        #expect(!day.serve(KitchenMenu.mushroomFlatbread, at: day.presentCustomers[0].seat))
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
        serve(KitchenMenu.pepperFlatbread, in: day)

        run(day, to: 9, from: 1.2)

        #expect(day.ordersMissed == 1)
        #expect(day.points == 10)
        #expect(day.pointsLost == 10)
    }

    @Test func starsCountFromTheTotal() {
        let day = makeDay()
        run(day, to: 1)
        serve(KitchenMenu.pepperFlatbread, in: day)

        // 20 points + 5 tip = 25: one star of [20, 40, 60].
        #expect(day.stars == 1)
    }
}
