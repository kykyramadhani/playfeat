//
//  MarathonFlow.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  The marathon's customers, as in the prototype: one steps up every few
//  seconds, dealt from shuffled groups of the planet's current stage. Every dish
//  served shortens both the patience of later customers and the gap between
//  them, down to a floor. Tips pay one coin per 3 seconds of patience left;
//  three customers lost end the run.
//

import Foundation

nonisolated struct MarathonFlow: CustomerFlow {
    // MARK: - Dials

    static let lostCustomersToEnd = 3
    static let secondsPerTip: TimeInterval = 3

    static let regularStartPatience: TimeInterval = 45
    static let angryStartPatience: TimeInterval = 25
    static let patienceDecay = 0.97
    static let patienceFloor: TimeInterval = 12

    static let startSpacing: TimeInterval = 15
    static let spacingDecay = 0.95
    static let spacingFloor: TimeInterval = 3

    // MARK: - State

    private(set) var patience = regularStartPatience
    private(set) var angryPatience = angryStartPatience
    /// Seconds until the next customer after this one.
    private(set) var spacing = startSpacing
    private(set) var dishesServed = 0
    private var nextArrivalAt: TimeInterval = 0
    private var deck: [CustomerOrder] = []
    private var groupsDealt = 0
    private var random: AnyRandomNumberGenerator
    private let plan: BuffetPlan

    init(plan: BuffetPlan, random: any RandomNumberGenerator) {
        self.plan = plan
        self.random = AnyRandomNumberGenerator(random)
    }

    var stage: MarathonStage { plan.stage(afterServing: dishesServed) }
    var counterSpots: Int { plan.mix(of: stage).maxWaiting }
    var bubblePool: [String] { plan.mix(of: stage).bubblePool }
    var customerSpacing: TimeInterval? { spacing }

    mutating func arrivals(at time: TimeInterval, atCounter: Int) -> [Arrival] {
        guard time >= nextArrivalAt else { return [] }
        nextArrivalAt = time + spacing
        let order = nextOrder()
        let wait = order.type == .angry ? angryPatience : patience
        return [Arrival(type: order.type, dish: order.dish, patienceSec: wait)]
    }

    mutating func spotFreed(at time: TimeInterval) {}

    mutating func counterCleared(at time: TimeInterval) {
        nextArrivalAt = time
    }

    mutating func dishServed(totalServed served: Int) {
        dishesServed = served
        patience = max(Self.patienceFloor, patience * Self.patienceDecay)
        angryPatience = max(Self.patienceFloor, angryPatience * Self.patienceDecay)
        spacing = max(Self.spacingFloor, spacing * Self.spacingDecay)
    }

    func tip(from customer: SeatedCustomer, at time: TimeInterval) -> Int {
        Self.tip(secondsLeft: customer.secondsLeft(at: time))
    }

    static func tip(secondsLeft: TimeInterval) -> Int {
        Int((max(secondsLeft, 0) / secondsPerTip).rounded(.down))
    }

    func isFinished(at time: TimeInterval, lostCustomers: Int, counterIsEmpty: Bool) -> Bool {
        lostCustomers >= Self.lostCustomersToEnd
    }

    // MARK: - Dealing

    private mutating func nextOrder() -> CustomerOrder {
        if deck.isEmpty { dealGroup() }
        return deck.removeFirst()
    }

    /// The first group opens with the first order, so a run starts easy.
    private mutating func dealGroup() {
        var group = plan.mix(of: stage).dealGroup(using: &random)
        if groupsDealt == 0,
           let first = group.firstIndex(where: { $0.dish == plan.firstOrder && $0.type == .regular }) {
            group.swapAt(0, first)
        }
        groupsDealt += 1
        deck += group
    }
}
