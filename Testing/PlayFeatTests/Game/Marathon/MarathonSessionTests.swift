//
//  MarathonSessionTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//
//  The marathon by the prototype's rules: one continuous day in 90-second
//  rounds, customers on a shrinking beat, coins from tips, one upgrade card
//  per break, and plates and glasses that come out as dishes are served.
//

import Testing
@testable import PlayFeat

@MainActor
struct MarathonSessionTests {

    private func makeSession() -> MarathonSession {
        MarathonSession(positionTypes: KitchenLayout.positionTypes, random: SeededGenerator(state: 3))
    }

    /// Plays from `start` to `end` in small steps, as the scene would.
    private func play(_ day: KitchenDay, from start: Double = 0, to end: Double) {
        day.start()
        var time = start
        while time <= end {
            day.tick(at: time)
            time += 0.2
        }
    }

    /// Serves whoever stands at the counter, first come first served.
    private func serveEveryone(in day: KitchenDay) {
        for customer in day.presentCustomers.sorted(by: { $0.seatedAt < $1.seatedAt }) {
            _ = day.serve(customer.dish, at: customer.seat)
        }
    }

    // MARK: - Customers

    @Test func theRunOpensOnAPepperFlatbread() {
        let session = makeSession()

        #expect(session.day.presentCustomers.map(\.dish) == [KitchenMenu.pepperFlatbread])
    }

    @Test func everyServedDishShortensPatienceAndTheGap() {
        var flow = MarathonFlow(random: SeededGenerator(state: 1))

        flow.dishServed(totalServed: 1)

        #expect(flow.patience == MarathonFlow.regularStartPatience * MarathonFlow.patienceDecay)
        #expect(flow.spacing == MarathonFlow.startSpacing * MarathonFlow.spacingDecay)
    }

    @Test func patienceAndTheGapNeverDropBelowTheirFloors() {
        var flow = MarathonFlow(random: SeededGenerator(state: 1))

        for served in 1...200 { flow.dishServed(totalServed: served) }

        #expect(flow.patience == MarathonFlow.patienceFloor)
        #expect(flow.spacing == MarathonFlow.spacingFloor)
    }

    /// From 8 dishes the dessert and the angry alien join, and three wait at once.
    @Test func stageTwoStartsAtEightDishes() {
        var flow = MarathonFlow(random: SeededGenerator(state: 1))
        #expect(flow.counterSpots == 2)

        for served in 1...8 { flow.dishServed(totalServed: served) }

        #expect(flow.stage == .two)
        #expect(flow.counterSpots == 3)
        #expect(flow.bubblePool.contains(KitchenMenu.tentacle))
    }

    /// One coin per 3 seconds of patience left.
    @Test func tipsPayOneCoinPerThreeSecondsLeft() {
        #expect(MarathonFlow.tip(secondsLeft: 44.9) == 14)
        #expect(MarathonFlow.tip(secondsLeft: 2) == 0)
    }

    /// Two fit at the counter at first, so the third waits outside and only
    /// starts losing patience once a spot frees: the third loss comes at 90 s.
    @Test func threeLostCustomersEndTheRun() {
        let session = makeSession()
        session.day.roundEndsAt = 1_000

        play(session.day, to: 100)

        #expect(session.day.ordersMissed >= MarathonFlow.lostCustomersToEnd)
        #expect(session.isOver)
    }

    // MARK: - Rounds and coins

    @Test func theClockStopsAtTheRoundsEnd() {
        let session = makeSession()
        let day = session.day

        play(day, to: 5)
        serveEveryone(in: day)
        play(day, from: 5.2, to: 95)

        #expect(day.isRoundOver || day.isOver)
        #expect(day.elapsed <= MarathonSession.roundSec + 0.25)
    }

    @Test func marathonCoinsAreTheTipsEarned() {
        let session = makeSession()
        play(session.day, to: 3)

        serveEveryone(in: session.day)

        #expect(session.coins == session.day.tips)
        #expect(session.coins > 0)
    }

    @Test func aBreakThenTheNextRoundMovesTheClockOn() {
        let session = makeSession()

        session.startBreak()
        session.endBreak()

        #expect(session.round == 2)
        #expect(session.day.roundEndsAt == MarathonSession.roundSec * 2)
    }

    // MARK: - Cards

    @Test func theFirstBreakOffersItsSetHand() {
        #expect(MarathonCard.offer(forBreak: 1, owning: []) == [.fasterGrill1, .blazingPepper, .cozySeats])
    }

    /// Faster Grill II needs Faster Grill I; without it the next fallback card stands in.
    @Test func aCardThatCantBeBoughtIsSwappedForAFallback() {
        let offer = MarathonCard.offer(forBreak: 2, owning: [])

        #expect(!offer.contains(.fasterGrill2))
        #expect(offer == [.secondGrillSpot, .royalMushroom, .slimierSlime])
    }

    @Test func fromTheFourthBreakTheFallbackDeals() {
        #expect(MarathonCard.offer(forBreak: 4, owning: [.slimierSlime])
            == [.goldenFlatbread, .doubleTentacle, .royalMushroom])
    }

    @Test func aCardCostsCoinsAndOnlyOneFitsABreak() throws {
        let session = makeSession()
        play(session.day, to: 3)
        serveEveryone(in: session.day)
        session.startBreak()
        let coins = session.coins

        #expect(throws: MarathonCardError.notEnoughCoins(have: coins, price: 50)) { try session.buy(.cozySeats) }
        #expect(session.coinsSpent == 0)
    }

    @Test func aBreakTakesOneCardAtMost() throws {
        let session = makeSession()
        session.startBreak()

        #expect(throws: MarathonCardError.notOffered(.fasterGrill2)) { try session.buy(.fasterGrill2) }
    }

    // MARK: - Plates and glasses

    @Test func theRunStartsWithOnePlateAndNoGlass() {
        let session = makeSession()

        #expect(session.tools == KitchenTools(plates: 1, glasses: 0))
    }
}
