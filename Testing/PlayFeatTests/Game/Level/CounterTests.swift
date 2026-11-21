//
//  CounterTests.swift
//  PlayFeatTests
//  Created by kyky on 19/11/26.
//
//  Customers stand at a free position picked at random, only among the
//  positions the level opens, and wait while every one is taken.
//

import Testing
@testable import PlayFeat

struct CounterTests {

    private func arrivals(_ count: Int) -> [Arrival] {
        Array(repeating: Arrival(type: .regular, dish: KitchenMenu.pepperFlatbread, patienceSec: 45), count: count)
    }

    @Test func customersOnlyTakeTheOpenSeats() {
        var counter = Counter(openSeats: [1, 3], random: SeededGenerator(state: 1))
        counter.arrive(arrivals(2))

        counter.seatWaiting(at: 0, spots: 3)

        #expect(Set(counter.present.map(\.seat)) == [1, 3])
    }

    @Test func aCustomerWaitsWhileEveryOpenSeatIsTaken() {
        var counter = Counter(openSeats: [0], random: SeededGenerator(state: 1))
        counter.arrive(arrivals(2))

        counter.seatWaiting(at: 0, spots: 2)

        #expect(counter.present.count == 1)
        #expect(counter.waiting.count == 1)
    }

    @Test func whereACustomerStandsIsPickedAtRandom() {
        let seats = (1...20).compactMap { seed -> Int? in
            var counter = Counter(openSeats: [0, 1, 2, 3], random: SeededGenerator(state: UInt64(seed)))
            counter.arrive(arrivals(1))
            counter.seatWaiting(at: 0, spots: 1)
            return counter.present.first?.seat
        }

        #expect(Set(seats).count > 1)
    }
}
