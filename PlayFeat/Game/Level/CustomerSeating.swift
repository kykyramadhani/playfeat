//
//  CustomerSeating.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Who sits where in a planet kitchen as the day goes on. The kitchen has a
//  fixed number of seats; a customer who arrives to a full kitchen waits for
//  the next seat to free up, and their patience starts counting once seated.
//  A seat frees when its customer is served or gives up.
//

import Foundation

nonisolated struct SeatedCustomer: Equatable {
    let dish: String
    let type: CustomerType
    let seat: Int
    let seatedAt: TimeInterval
    let patienceSec: TimeInterval

    var leavesAt: TimeInterval { seatedAt + patienceSec }

    /// 1 when they sit down, 0 when they give up and leave.
    func patienceLeft(at time: TimeInterval) -> Double {
        guard patienceSec > 0 else { return 0 }
        return min(max((leavesAt - time) / patienceSec, 0), 1)
    }
}

nonisolated struct CustomerSeating {
    /// Customers still to sit down, in arrival order.
    private var queue: [ScheduledCustomer]
    /// Who sits at each seat right now.
    private(set) var seats: [SeatedCustomer?]
    /// When each seat last emptied, so the next customer's patience starts
    /// from the moment they could actually sit down.
    private var seatFreeSince: [TimeInterval]

    init(customers: [ScheduledCustomer], seatCount: Int) {
        queue = customers.sorted { $0.arriveAt < $1.arriveAt }
        seats = Array(repeating: nil, count: max(seatCount, 0))
        seatFreeSince = Array(repeating: 0, count: max(seatCount, 0))
    }

    var present: [SeatedCustomer] { seats.compactMap { $0 } }

    /// Plays the seating forward to `time`: customers whose patience ran out
    /// leave, and arrivals take the seats that free up, in the order it
    /// happened. Returns the customers who gave up.
    mutating func advance(to time: TimeInterval) -> [SeatedCustomer] {
        var gaveUp: [SeatedCustomer] = []
        while true {
            let leaving = nextToGiveUp(by: time)
            let arriving = nextSeating(by: time)

            if let leaving, leaving.leavesAt <= arriving?.at ?? .infinity {
                gaveUp.append(leaving)
                free(leaving.seat, at: leaving.leavesAt)
            } else if let arriving {
                seatNext(at: arriving.seat, time: arriving.at)
            } else {
                return gaveUp
            }
        }
    }

    /// The customer at `seat` gets their dish and leaves. Nil if nobody sits there.
    mutating func serve(seat: Int, at time: TimeInterval) -> SeatedCustomer? {
        guard seats.indices.contains(seat), let customer = seats[seat] else { return nil }
        free(seat, at: time)
        return customer
    }

    // MARK: - Steps

    private func nextToGiveUp(by time: TimeInterval) -> SeatedCustomer? {
        present.filter { $0.leavesAt <= time }.min { $0.leavesAt < $1.leavesAt }
    }

    /// The seat the next arrival takes and when, if that happens by `time`.
    /// They take the empty seat that freed first.
    private func nextSeating(by time: TimeInterval) -> (seat: Int, at: TimeInterval)? {
        guard let customer = queue.first,
              let seat = seats.indices.filter({ seats[$0] == nil }).min(by: { seatFreeSince[$0] < seatFreeSince[$1] })
        else { return nil }
        let seatedAt = max(customer.arriveAt, seatFreeSince[seat])
        return seatedAt <= time ? (seat, seatedAt) : nil
    }

    private mutating func seatNext(at seat: Int, time: TimeInterval) {
        let customer = queue.removeFirst()
        seats[seat] = SeatedCustomer(
            dish: customer.dish,
            type: customer.type,
            seat: seat,
            seatedAt: time,
            patienceSec: customer.patienceSec
        )
    }

    private mutating func free(_ seat: Int, at time: TimeInterval) {
        seats[seat] = nil
        seatFreeSince[seat] = time
    }
}
