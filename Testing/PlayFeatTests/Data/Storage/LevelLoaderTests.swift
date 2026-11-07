//
//  LevelLoaderTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  The shipped level files load and pass validation, and a broken one is
//  rejected with a reason.
//

import Foundation
import Testing
@testable import PlayFeat

struct LevelLoaderTests {

    @Test(arguments: ["1-1", "1-4"])
    func shippedLevelLoads(_ levelID: String) throws {
        let level = try LevelLoader.load(levelID)

        #expect(level.id == levelID)
    }

    @Test func day4MatchesTheDesignDoc() throws {
        let level = try LevelLoader.load("1-4")

        #expect(level.gravity == .init(direction: .down, multiplier: 0.6))
        #expect(level.bubbleEverySec == 2)
        #expect(level.usefulBubbleShare == 0.6)
        #expect(level.customers.filter { $0.type == .angry }.map(\.arriveAt) == [27, 54])
    }

    @Test func aMissingLevelSaysWhichOne() {
        #expect {
            try LevelLoader.load("9-9")
        } throws: { error in
            guard case LevelLoaderError.fileMissing(let id) = error else { return false }
            return id == "9-9"
        }
    }

    @Test func aLaneOutsideOneToFourIsRejected() {
        let level = makeLevel(bubbles: [.init(at: 0, ingredient: "emberPepper", lane: 5)])

        #expect(throws: LevelDataError.laneOutOfRange(5)) { try level.validate() }
    }

    @Test func randomCustomersMustMatchThePool() {
        let level = makeLevel(
            customers: [.init(arriveAt: 0, type: .regular, order: "random", patienceSec: 35)],
            orderPool: ["sunsetSorbet": 2]
        )

        #expect(throws: LevelDataError.orderPoolMismatch(randomCustomers: 1, poolDishes: 2)) {
            try level.validate()
        }
    }
}
