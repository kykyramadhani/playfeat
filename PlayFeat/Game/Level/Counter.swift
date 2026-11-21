//
//  Counter.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  Who stands at the kitchen counter. Each alien drawing is a position; a
//  customer stands at a free one picked at random among those the level
//  opens. Customers who step up while every open position is taken wait
//  until one frees, and their patience only starts once they stand. A
//  position frees when its customer is served or gives up.
//

import Foundation

nonisolated struct SeatedCustomer: Equatable {
    let dish: String
    let type: CustomerType
    /// Which position (alien drawing) they stand at.
    let seat: Int
    let seatedAt: TimeInterval
    let patienceSec: TimeInterval

    var leavesAt: TimeInterval { seatedAt + patienceSec }

    /// 1 when they step up, 0 when they give up and leave.
    func patienceLeft(at time: TimeInterval) -> Double {
        guard patienceSec > 0 else { return 0 }
        return min(max((leavesAt - time) / patienceSec, 0), 1)
    }

    func secondsLeft(at time: TimeInterval) -> TimeInterval {
        max(leavesAt - time, 0)
    }
}

/// A customer stepping up, before they stand at a position.
nonisolated struct Arrival: Equatable {
    let type: CustomerType
    let dish: String
    let patienceSec: TimeInterval
}

nonisolated struct Counter {
    /// The positions customers may take, by index into the kitchen's seats.
    let openSeats: [Int]
    /// Who stands at each taken position.
    private(set) var seats: [Int: SeatedCustomer] = [:]
    /// Stepped up, waiting for a free position.
    private(set) var waiting: [Arrival] = []
    private var random: AnyRandomNumberGenerator

    init(openSeats: [Int], random: any RandomNumberGenerator) {
        self.openSeats = openSeats
        self.random = AnyRandomNumberGenerator(random)
    }

    var present: [SeatedCustomer] { seats.values.sorted { $0.seat < $1.seat } }

    /// Everyone at the counter or waiting for it.
    var headcount: Int { present.count + waiting.count }

    var isEmpty: Bool { headcount == 0 }

    mutating func arrive(_ arrivals: [Arrival]) {
        waiting += arrivals
    }

    /// Stands waiting customers at free positions, oldest first, while
    /// fewer than `spots` stand at the counter.
    mutating func seatWaiting(at time: TimeInterval, spots: Int) {
        while present.count < spots, !waiting.isEmpty,
              let seat = openSeats.filter({ seats[$0] == nil }).randomElement(using: &random) {
            let arrival = waiting.removeFirst()
            seats[seat] = SeatedCustomer(
                dish: arrival.dish, type: arrival.type, seat: seat, seatedAt: time, patienceSec: arrival.patienceSec
            )
        }
    }

    /// Takes away everyone whose patience has run out by `time`.
    /// - Returns: who gave up.
    mutating func removeGiveUps(at time: TimeInterval) -> [SeatedCustomer] {
        let gaveUp = present.filter { $0.leavesAt <= time }
        for customer in gaveUp { seats[customer.seat] = nil }
        return gaveUp
    }

    /// The customer at `seat` takes their dish and leaves. Nil if nobody stands there.
    mutating func serve(seat: Int) -> SeatedCustomer? {
        seats.removeValue(forKey: seat)
    }
}
