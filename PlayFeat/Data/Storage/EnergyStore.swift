//
//  EnergyStore.swift
//  PlayFeat
//  Created by kyky on 21/11/26.
//
//  The player's energy meter, saved in UserDefaults so the refill keeps
//  counting while the app is closed. Created once in PlayFeatApp and read
//  from the environment by the screens that show or spend it.
//

import Foundation

@Observable
final class EnergyStore {
    static let storedKey = "energyStored"
    static let refillStartedAtKey = "energyRefillStartedAt"

    private(set) var meter: EnergyMeter
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let refillStartedAt = defaults.object(forKey: Self.refillStartedAtKey) as? Date
        let stored = defaults.object(forKey: Self.storedKey) as? Int ?? EnergyMeter.maxEnergy
        meter = EnergyMeter(stored: stored, refillStartedAt: refillStartedAt)
    }

    func canAfford(_ cost: Int, at now: Date = .now) -> Bool {
        meter.canAfford(cost, at: now)
    }

    func spend(_ cost: Int, at now: Date = .now) throws(EnergyError) {
        try meter.spend(cost, at: now)
        defaults.set(meter.stored, forKey: Self.storedKey)
        defaults.set(meter.refillStartedAt, forKey: Self.refillStartedAtKey)
    }
}
