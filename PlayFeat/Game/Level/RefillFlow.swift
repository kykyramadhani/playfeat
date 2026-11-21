//
//  RefillFlow.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  A story day's customers, the prototype's refill flow: customers exist
//  only once they step up. Each counter spot has its own timer; the first
//  customer steps up at once and the other spots fill `refillDelaySec`
//  apart. When a spot frees, the next customer steps up `refillDelaySec`
//  later. Nobody new comes in the day's last `closingSec` (after 80 s of a
//  90 s day), so every order taken can still be finished. Whoever is at the
//  counter when the clock runs out can still be served (overtime); the day
//  ends once they're gone.
//

import Foundation

nonisolated struct RefillFlow: CustomerFlow {
    let refill: LevelData.Refill
    let durationSec: TimeInterval
    let bubblePool: [String]
    /// What the level's planet's angry aliens order.
    let angryOrder: String

    /// When each spot's next customer steps up; nil while the spot is taken.
    private var stepUpTimes: [TimeInterval?]
    /// Customers who have stepped up so far, counting from 1.
    private(set) var steppedUp = 0
    private var random: AnyRandomNumberGenerator

    /// A level without a refill plan (validation rejects one from a file)
    /// has nobody step up.
    init(level: LevelData, random: any RandomNumberGenerator) {
        let refill = level.refill ?? Self.nobody
        self.refill = refill
        durationSec = level.durationSec
        bubblePool = level.pool
        angryOrder = PlanetCatalog.planet(level.planet).kitchen.angryOrder
        self.random = AnyRandomNumberGenerator(random)
        stepUpTimes = (0..<refill.counterSpots).map { TimeInterval($0) * refill.refillDelaySec }
    }

    /// The end of the day nobody new steps up in. Short on purpose: overtime
    /// already lets the last orders be finished after the clock runs out, and
    /// a longer gap left the counter empty for the day's closing stretch.
    static let closingSec: TimeInterval = 10

    /// Customers step up until this play time.
    var lastArrivalSec: TimeInterval { durationSec - Self.closingSec }

    var counterSpots: Int { refill.counterSpots }
    var customerSpacing: TimeInterval? { nil }

    private static let nobody = LevelData.Refill(
        counterSpots: 0, refillDelaySec: 0, firstOrder: KitchenMenu.pepperFlatbread, orderPool: [:],
        angryAt: [], angryEvery: nil, patienceSec: 0, angryPatienceSec: 0
    )

    mutating func arrivals(at time: TimeInterval, atCounter: Int) -> [Arrival] {
        guard time < lastArrivalSec else { return [] }
        var arrivals: [Arrival] = []
        for spot in stepUpTimes.indices {
            guard let due = stepUpTimes[spot], time >= due, atCounter + arrivals.count < counterSpots else { continue }
            stepUpTimes[spot] = nil
            steppedUp += 1
            arrivals.append(customer(number: steppedUp))
        }
        return arrivals
    }

    mutating func spotFreed(at time: TimeInterval) {
        guard let spot = stepUpTimes.firstIndex(where: { $0 == nil }) else { return }
        stepUpTimes[spot] = time + refill.refillDelaySec
    }

    mutating func dishServed(totalServed served: Int) {}

    func tip(from customer: SeatedCustomer, at time: TimeInterval) -> Int {
        let zoneTip = KitchenRules.PatienceZone(patienceLeft: customer.patienceLeft(at: time)).tip
        return customer.type == .angry ? zoneTip * KitchenRules.angryTipMultiplier : zoneTip
    }

    func isFinished(at time: TimeInterval, lostCustomers: Int, counterIsEmpty: Bool) -> Bool {
        time >= durationSec && counterIsEmpty
    }

    // MARK: - Orders

    /// Customer `number` (from 1): an angry alien wanting the dessert when
    /// the level says so, the first order for customer 1, and otherwise a
    /// regular drawn from the order pool's weights.
    private mutating func customer(number: Int) -> Arrival {
        if Self.isAngry(number, refill: refill) {
            return Arrival(type: .angry, dish: angryOrder, patienceSec: refill.angryPatienceSec)
        }
        let dish = number == 1 ? refill.firstOrder : Self.draw(from: refill.orderPool, using: &random)
        return Arrival(type: .regular, dish: dish, patienceSec: refill.patienceSec)
    }

    static func isAngry(_ number: Int, refill: LevelData.Refill) -> Bool {
        refill.angryAt.contains(number) || refill.angryEvery.map { number % $0 == 0 } ?? false
    }

    /// A dish picked with the pool's weights. Sorted first so a seeded
    /// generator draws the same dish every run.
    static func draw(from pool: [String: Double], using random: inout some RandomNumberGenerator) -> String {
        let weighted = pool.filter { $0.value > 0 }.sorted { $0.key < $1.key }
        var roll = Double.random(in: 0..<weighted.reduce(0) { $0 + $1.value }, using: &random)
        for (dish, weight) in weighted {
            roll -= weight
            if roll < 0 { return dish }
        }
        return weighted.last?.key ?? KitchenMenu.pepperFlatbread
    }
}
