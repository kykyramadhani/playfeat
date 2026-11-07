//
//  OrderDealerTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  Random customers share the shuffled order pool: same dishes every play,
//  only their order changes. Fixed orders are never touched.
//

import Testing
@testable import PlayFeat

struct OrderDealerTests {

    private let level = makeLevel(
        customers: [
            .init(arriveAt: 0, type: .regular, order: "pepperFlatbread", patienceSec: 35),
            .init(arriveAt: 9, type: .regular, order: "random", patienceSec: 35),
            .init(arriveAt: 18, type: .angry, order: "sunsetSorbet", patienceSec: 25),
            .init(arriveAt: 27, type: .regular, order: "random", patienceSec: 35),
            .init(arriveAt: 36, type: .regular, order: "random", patienceSec: 35)
        ],
        orderPool: ["mushroomFlatbread": 2, "sunsetSorbet": 1]
    )

    @Test func fixedOrdersStayAsWritten() {
        var generator = SeededGenerator(state: 7)
        let customers = OrderDealer.schedule(level, using: &generator)

        #expect(customers[0].dish == "pepperFlatbread")
        #expect(customers[2] == ScheduledCustomer(arriveAt: 18, type: .angry, dish: "sunsetSorbet", patienceSec: 25))
    }

    @Test func randomCustomersGetExactlyThePool() {
        for seed in 1...50 {
            var generator = SeededGenerator(state: UInt64(seed))
            let dealt = OrderDealer.schedule(level, using: &generator)
            let randomDishes = [1, 3, 4].map { dealt[$0].dish }

            #expect(randomDishes.sorted() == ["mushroomFlatbread", "mushroomFlatbread", "sunsetSorbet"])
        }
    }

    @Test func theSameSeedDealsTheSameDay() {
        var first = SeededGenerator(state: 42)
        var second = SeededGenerator(state: 42)

        #expect(OrderDealer.schedule(level, using: &first) == OrderDealer.schedule(level, using: &second))
    }
}
