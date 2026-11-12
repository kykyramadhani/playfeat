//
//  CustomerSeating.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Where and when each customer of a day sits down. The kitchen has a fixed
//  number of seats; a customer who arrives to a full kitchen waits for the
//  next seat to free up, and their patience starts counting once seated.
//
//  Serving doesn't exist yet, so a seat frees when its customer's patience
//  runs out. That makes the whole day's seating known up front.
//

import Foundation

nonisolated struct SeatedCustomer: Equatable {
    let dish: String
    let seat: Int
    let seatedAt: TimeInterval
    let patienceSec: TimeInterval

    var leavesAt: TimeInterval { seatedAt + patienceSec }

    func isPresent(at time: TimeInterval) -> Bool {
        time >= seatedAt && time < leavesAt
    }

    /// 1 when they sit down, 0 when they give up and leave.
    func patienceLeft(at time: TimeInterval) -> Double {
        guard patienceSec > 0 else { return 0 }
        return min(max((leavesAt - time) / patienceSec, 0), 1)
    }
}

nonisolated enum CustomerSeating {
    /// Seats `customers` in arrival order, each at the seat that frees first.
    static func seat(_ customers: [ScheduledCustomer], seatCount: Int) -> [SeatedCustomer] {
        guard seatCount > 0 else { return [] }
        var seatFreeAt = Array(repeating: TimeInterval(0), count: seatCount)

        return customers.sorted { $0.arriveAt < $1.arriveAt }.map { customer in
            let seat = seatFreeAt.indices.min { seatFreeAt[$0] < seatFreeAt[$1] } ?? 0
            let seatedAt = max(customer.arriveAt, seatFreeAt[seat])
            seatFreeAt[seat] = seatedAt + customer.patienceSec
            return SeatedCustomer(
                dish: customer.dish,
                seat: seat,
                seatedAt: seatedAt,
                patienceSec: customer.patienceSec
            )
        }
    }
}
