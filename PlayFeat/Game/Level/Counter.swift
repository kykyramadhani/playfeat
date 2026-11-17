//
//  Counter.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  Who stands at the kitchen counter. Each alien drawing is a position that
//  takes one type of customer (the angry alien has its own). Customers who
//  step up while no position of their type is free wait until one is, and
//  their patience only starts once they stand at it. A position frees when
//  its customer is served or gives up.
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
    /// The type of customer each position takes.
    let positionTypes: [CustomerType]
    /// Who stands at each position right now.
    private(set) var seats: [SeatedCustomer?]
    /// Stepped up, waiting for a position of their type.
    private(set) var waiting: [Arrival] = []

    init(positionTypes: [CustomerType]) {
        self.positionTypes = positionTypes
        seats = Array(repeating: nil, count: positionTypes.count)
    }

    var present: [SeatedCustomer] { seats.compactMap { $0 } }

    /// Everyone at the counter or waiting for it.
    var headcount: Int { present.count + waiting.count }

    var isEmpty: Bool { headcount == 0 }

    mutating func arrive(_ arrivals: [Arrival]) {
        waiting += arrivals
    }

    /// Stands waiting customers at free positions of their type, oldest
    /// first, while fewer than `spots` stand at the counter.
    mutating func seatWaiting(at time: TimeInterval, spots: Int) {
        while present.count < spots,
              let next = waiting.indices.first(where: { freePosition(for: waiting[$0].type) != nil }),
              let seat = freePosition(for: waiting[next].type) {
            let arrival = waiting.remove(at: next)
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
        guard seats.indices.contains(seat), let customer = seats[seat] else { return nil }
        seats[seat] = nil
        return customer
    }

    private func freePosition(for type: CustomerType) -> Int? {
        seats.indices.first { seats[$0] == nil && positionTypes[$0] == type }
    }
}
