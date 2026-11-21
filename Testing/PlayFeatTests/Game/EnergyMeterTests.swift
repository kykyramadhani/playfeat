//
//  EnergyMeterTests.swift
//  PlayFeatTests
//  Created by kyky on 21/11/26.
//
//  The energy PLAY costs: 25 at most, one back every 5 minutes, the refill
//  clock starting when the meter drops below full.
//

import Foundation
import Testing
@testable import PlayFeat

struct EnergyMeterTests {

    private let start = Date(timeIntervalSinceReferenceDate: 0)

    private func later(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    @Test func aNewMeterIsFull() {
        #expect(EnergyMeter().energy(at: start) == EnergyMeter.maxEnergy)
    }

    @Test func spendingTakesTheCost() throws {
        var meter = EnergyMeter()

        try meter.spend(3, at: start)

        #expect(meter.energy(at: start) == 22)
    }

    @Test func onePointComesBackEveryFiveMinutes() throws {
        var meter = EnergyMeter()
        try meter.spend(3, at: start)

        #expect(meter.energy(at: later(299)) == 22)
        #expect(meter.energy(at: later(300)) == 23)
        #expect(meter.energy(at: later(650)) == 24)
    }

    @Test func refillingStopsAtFull() throws {
        var meter = EnergyMeter()
        try meter.spend(3, at: start)

        #expect(meter.energy(at: later(10_000)) == EnergyMeter.maxEnergy)
    }

    /// Spending mid-refill keeps the time already counted towards the next point.
    @Test func spendingAgainKeepsTheRefillProgress() throws {
        var meter = EnergyMeter()
        try meter.spend(3, at: start)

        try meter.spend(4, at: later(100))

        #expect(meter.energy(at: later(100)) == 18)
        #expect(meter.energy(at: later(300)) == 19)
    }

    @Test func aLevelCostingMoreThanIsLeftCantStart() throws {
        var meter = EnergyMeter(stored: 2, refillStartedAt: start)

        #expect(!meter.canAfford(3, at: start))
        #expect(throws: EnergyError.notEnough(have: 2, cost: 3)) { try meter.spend(3, at: start) }
        #expect(meter.energy(at: start) == 2)
    }
}
