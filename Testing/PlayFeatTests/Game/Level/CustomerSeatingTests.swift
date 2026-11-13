//
//  CustomerSeatingTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//

import Testing
@testable import PlayFeat

struct CustomerSeatingTests {

    private func customer(at arriveAt: Double, patience: Double = 30) -> ScheduledCustomer {
        ScheduledCustomer(arriveAt: arriveAt, type: .regular, dish: "pepperFlatbread", patienceSec: patience)
    }

    @Test func customersTakeFreeSeatsAsTheyArrive() {
        var seating = CustomerSeating(customers: [customer(at: 0), customer(at: 5)], seatCount: 2)

        _ = seating.advance(to: 6)

        #expect(seating.present.map(\.seat) == [0, 1])
        #expect(seating.present.map(\.seatedAt) == [0, 5])
    }

    @Test func aCustomerWhoFindsEverySeatTakenWaitsForTheNextToFree() {
        var seating = CustomerSeating(
            customers: [customer(at: 0, patience: 30), customer(at: 5, patience: 20), customer(at: 10)],
            seatCount: 2
        )

        let gaveUp = seating.advance(to: 26)

        // Seat 1 frees at 25, when its customer gives up, before seat 0 at 30.
        #expect(gaveUp.map(\.seat) == [1])
        #expect(seating.seats[1]?.seatedAt == 25)
    }

    /// Serving frees the seat at once, so whoever is waiting sits down then
    /// rather than when the served customer would have run out of patience.
    @Test func servingACustomerLetsTheNextOneSitDown() {
        var seating = CustomerSeating(customers: [customer(at: 0), customer(at: 2)], seatCount: 1)
        _ = seating.advance(to: 5)

        let served = seating.serve(seat: 0, at: 5)
        _ = seating.advance(to: 5.1)

        #expect(served?.seatedAt == 0)
        #expect(seating.seats[0]?.seatedAt == 5)
    }

    @Test func patienceRunsFromFullWhenSeatedToEmptyWhenTheyLeave() {
        var seating = CustomerSeating(customers: [customer(at: 10, patience: 20)], seatCount: 1)
        _ = seating.advance(to: 10)
        let seated = seating.seats[0]

        #expect(seated?.patienceLeft(at: 10) == 1)
        #expect(seated?.patienceLeft(at: 20) == 0.5)
        #expect(seating.advance(to: 30).count == 1)
        #expect(seating.present.isEmpty)
    }
}
