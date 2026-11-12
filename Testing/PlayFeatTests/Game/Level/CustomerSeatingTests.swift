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
        let seated = CustomerSeating.seat([customer(at: 0), customer(at: 5)], seatCount: 2)

        #expect(seated.map(\.seat) == [0, 1])
        #expect(seated.map(\.seatedAt) == [0, 5])
    }

    @Test func aCustomerWhoFindsEverySeatTakenWaitsForTheNextToFree() {
        let seated = CustomerSeating.seat(
            [customer(at: 0, patience: 30), customer(at: 5, patience: 20), customer(at: 10)],
            seatCount: 2
        )

        // Seat 1 frees at 25, before seat 0 frees at 30.
        #expect(seated[2].seat == 1)
        #expect(seated[2].seatedAt == 25)
    }

    @Test func patienceRunsFromFullWhenSeatedToEmptyWhenTheyLeave() {
        let seated = CustomerSeating.seat([customer(at: 10, patience: 20)], seatCount: 1)[0]

        #expect(seated.patienceLeft(at: 10) == 1)
        #expect(seated.patienceLeft(at: 20) == 0.5)
        #expect(seated.isPresent(at: 29.9))
        #expect(!seated.isPresent(at: 30))
    }
}
