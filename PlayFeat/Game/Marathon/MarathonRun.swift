//
//  MarathonRun.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Score, tips and difficulty of one endless marathon run. Every dish served
//  shortens patience and the gap between customers; 3 lost customers end it.
//  Numbers are the proposal in "11. Developer review", pending team agreement.
//

import Foundation

nonisolated struct MarathonRun {
    // MARK: - Dials

    static let lostCustomersToEnd = 3
    static let lostCustomerPenalty = 10
    /// One tip point per this many seconds of patience left, rounded down.
    static let secondsPerTip: TimeInterval = 3
    static let angryTipMultiplier = 2

    static let regularStartPatience: TimeInterval = 45
    static let angryStartPatience: TimeInterval = 25
    static let patienceDecay = 0.97
    static let patienceFloor: TimeInterval = 12

    static let startTimeBetweenCustomers: TimeInterval = 15
    static let timeBetweenCustomersDecay = 0.95
    static let timeBetweenCustomersFloor: TimeInterval = 3

    // MARK: - State

    private(set) var dishesServed = 0
    private(set) var lostCustomers = 0
    private(set) var score = 0
    private(set) var tips = 0

    var total: Int { score + tips }
    var isOver: Bool { lostCustomers >= Self.lostCustomersToEnd }
    var stage: MarathonStage { .stage(afterServing: dishesServed) }

    func patience(for type: CustomerType) -> TimeInterval {
        let start = type == .angry ? Self.angryStartPatience : Self.regularStartPatience
        return decayed(start, by: Self.patienceDecay, floor: Self.patienceFloor)
    }

    var timeBetweenCustomers: TimeInterval {
        decayed(
            Self.startTimeBetweenCustomers,
            by: Self.timeBetweenCustomersDecay,
            floor: Self.timeBetweenCustomersFloor
        )
    }

    // MARK: - Events

    /// - Parameter points: what the dish is worth before tips.
    mutating func serve(_ type: CustomerType, points: Int, patienceLeft: TimeInterval) {
        dishesServed += 1
        score += points
        tips += Self.tip(for: type, patienceLeft: patienceLeft)
    }

    mutating func loseCustomer() {
        lostCustomers += 1
        score -= Self.lostCustomerPenalty
    }

    static func tip(for type: CustomerType, patienceLeft: TimeInterval) -> Int {
        let base = Int((max(patienceLeft, 0) / secondsPerTip).rounded(.down))
        return type == .angry ? base * angryTipMultiplier : base
    }

    // MARK: - Helpers

    private func decayed(_ start: TimeInterval, by factor: Double, floor: TimeInterval) -> TimeInterval {
        max(start * pow(factor, Double(dishesServed)), floor)
    }
}

// MARK: - Ranking

nonisolated extension MarathonRun {
    /// Higher total ranks first; ties go to the run with more tips.
    static func ranksAbove(_ lhs: MarathonRun, _ rhs: MarathonRun) -> Bool {
        (lhs.total, lhs.tips) > (rhs.total, rhs.tips)
    }
}
