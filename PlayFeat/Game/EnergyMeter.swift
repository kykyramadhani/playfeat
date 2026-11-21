//
//  EnergyMeter.swift
//  PlayFeat
//  Created by kyky on 21/11/26.
//
//  The energy PLAY costs, as the playtest's energy config sets it: 25 at
//  most, one more every 5 minutes. A level spends its energy cost when it
//  starts; the refill clock starts the moment the meter drops below full,
//  and keeps whatever time it had towards the next point when more is spent.
//

import Foundation

nonisolated enum EnergyError: Error, Equatable {
    case notEnough(have: Int, cost: Int)
}

nonisolated struct EnergyMeter: Equatable {
    static let maxEnergy = 25
    static let refillSec: TimeInterval = 300

    /// Energy as of `refillStartedAt` (or now, when full).
    private(set) var stored: Int
    /// When the point now refilling started; nil while full.
    private(set) var refillStartedAt: Date?

    init(stored: Int = maxEnergy, refillStartedAt: Date? = nil) {
        self.stored = min(max(stored, 0), Self.maxEnergy)
        self.refillStartedAt = self.stored < Self.maxEnergy ? refillStartedAt : nil
    }

    /// Energy at `now`, refills included.
    func energy(at now: Date) -> Int {
        settled(at: now).stored
    }

    func canAfford(_ cost: Int, at now: Date) -> Bool {
        energy(at: now) >= cost
    }

    /// Takes `cost` energy at `now`; starts the refill clock if the meter was full.
    mutating func spend(_ cost: Int, at now: Date) throws(EnergyError) {
        var meter = settled(at: now)
        guard meter.stored >= cost else { throw .notEnough(have: meter.stored, cost: cost) }
        meter.stored -= cost
        if meter.refillStartedAt == nil, meter.stored < Self.maxEnergy { meter.refillStartedAt = now }
        self = meter
    }

    /// This meter with the points refilled by `now` added in.
    private func settled(at now: Date) -> EnergyMeter {
        guard let start = refillStartedAt else { return self }
        let refilled = Int(max(now.timeIntervalSince(start), 0) / Self.refillSec)
        let gained = min(refilled, Self.maxEnergy - stored)
        let total = stored + gained
        let nextStart = start.addingTimeInterval(Double(gained) * Self.refillSec)
        return EnergyMeter(stored: total, refillStartedAt: total < Self.maxEnergy ? nextStart : nil)
    }
}
