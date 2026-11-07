//
//  MarathonRunTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  The marathon proposal: stages by dishes served, decaying patience and
//  customer gaps with floors, tips, penalties and ranking.
//

import Foundation
import Testing
@testable import PlayFeat

struct MarathonRunTests {

    private func run(serving dishes: Int) -> MarathonRun {
        var run = MarathonRun()
        for _ in 0..<dishes { run.serve(.regular, points: 10, patienceLeft: 0) }
        return run
    }

    @Test func stageTwoStartsAtEightDishes() {
        #expect(run(serving: 7).stage == .one)
        #expect(run(serving: 8).stage == .two)
        #expect(MarathonStage.one.maxWaiting == 2)
        #expect(MarathonStage.two.maxWaiting == 3)
    }

    @Test func everyDishShortensPatienceAndTheGap() {
        let afterOne = run(serving: 1)

        #expect(abs(afterOne.patience(for: .regular) - 45 * 0.97) < 1e-9)
        #expect(abs(afterOne.patience(for: .angry) - 25 * 0.97) < 1e-9)
        #expect(abs(afterOne.timeBetweenCustomers - 15 * 0.95) < 1e-9)
    }

    @Test func aLongRunBottomsOutAtTheFloors() {
        let longRun = run(serving: 500)

        #expect(longRun.patience(for: .regular) == 12)
        #expect(longRun.patience(for: .angry) == 12)
        #expect(longRun.timeBetweenCustomers == 3)
    }

    @Test(arguments: [(CustomerType.regular, 8.9, 2), (.angry, 8.9, 4), (.regular, 2.9, 0), (.regular, -1, 0)])
    func tipsAreOnePerThreeSecondsLeft(type: CustomerType, patienceLeft: TimeInterval, tip: Int) {
        #expect(MarathonRun.tip(for: type, patienceLeft: patienceLeft) == tip)
    }

    @Test func threeLostCustomersEndTheRunAndCostTenEach() {
        var run = MarathonRun()
        run.loseCustomer()
        run.loseCustomer()
        #expect(!run.isOver)

        run.loseCustomer()
        #expect(run.isOver)
        #expect(run.score == -30)
    }

    @Test func rankingIsByTotalThenTips() {
        var tipHeavy = MarathonRun()
        tipHeavy.serve(.regular, points: 10, patienceLeft: 30)   // 10 + 10 tips
        var scoreHeavy = MarathonRun()
        scoreHeavy.serve(.regular, points: 20, patienceLeft: 0)  // 20 + 0 tips

        #expect(MarathonRun.ranksAbove(tipHeavy, scoreHeavy))
        #expect(!MarathonRun.ranksAbove(scoreHeavy, tipHeavy))
    }

    @Test func stageOneGroupsAreThreePepperAndTwoMushroom() {
        var generator = SeededGenerator(state: 1)
        let dishes = MarathonStage.one.dealGroup(using: &generator).map(\.dish)

        #expect(dishes.sorted() == ["mushroomFlatbread", "mushroomFlatbread",
                                    "pepperFlatbread", "pepperFlatbread", "pepperFlatbread"])
    }

    @Test func stageTwoGroupsHaveExactlyOneAngryAlienOrderingSorbet() {
        for seed in 1...50 {
            var generator = SeededGenerator(state: UInt64(seed))
            let group = MarathonStage.two.dealGroup(using: &generator)
            let angry = group.filter { $0.type == .angry }

            #expect(group.count == 5)
            #expect(angry == [CustomerOrder(type: .angry, dish: "sunsetSorbet")])
        }
    }
}
