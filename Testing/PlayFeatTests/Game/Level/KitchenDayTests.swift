//
//  KitchenDayTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//

import Testing
@testable import PlayFeat

@MainActor
struct KitchenDayTests {

    private func makeDay() -> KitchenDay {
        var generator = SeededGenerator(state: 1)
        return KitchenDay(level: makeLevel(), seatCount: 2, using: &generator)
    }

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

    // MARK: - Serving

    /// Plays the day up to `seconds` in small steps, as the scene would.
    private func run(_ day: KitchenDay, for seconds: Double) {
        day.start()
        var time = 0.0
        while time <= seconds {
            day.tick(at: time)
            time += 0.2
        }
    }

    @Test func theFirstCustomerIsWaitingBeforeTheDayStarts() {
        let day = makeDay()

        #expect(day.presentCustomers.map(\.dish) == ["pepperFlatbread"])
    }

    @Test func servingTheOrderedDishPaysAndTheCustomerLeaves() {
        let day = makeDay()
        run(day, for: 9)

        let served = day.serve("pepperFlatbread", at: 0)

        #expect(served)
        #expect(day.coins == KitchenDay.coinsPerDish)
        // 45 s of patience, ~9 used: ~36 s left buys 11–12 tip points at one per 3 s.
        #expect((11...12).contains(day.tips))
        #expect(day.presentCustomers.isEmpty)
    }

    @Test func aDishTheCustomerDidntOrderIsTurnedAway() {
        let day = makeDay()
        run(day, for: 1)

        #expect(!day.serve("mushroomFlatbread", at: 0))
        #expect(!day.serve("pepperFlatbread", at: 1))
        #expect(day.coins == 0)
        #expect(day.presentCustomers.count == 1)
    }

    @Test func theDayIsOverWhenItsDurationRunsOut() {
        let day = makeDay()
        day.start()
        var time = 0.0
        while !day.isOver, time < 200 {
            day.tick(at: time)
            time += 0.2
        }

        #expect(day.isOver)
        #expect(day.timeLeft == 0)
    }
}
