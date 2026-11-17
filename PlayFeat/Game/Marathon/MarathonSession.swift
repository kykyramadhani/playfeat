//
//  MarathonSession.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  One marathon on Kepler-186f, run as in the prototype: a single endless
//  kitchen day cut into 90-second rounds of play. When a round ends,
//  everything freezes for a 15-second break where the player may buy one
//  upgrade card with marathon coins, then play carries on where it stopped.
//  Marathon coins are the tips earned this run; they only buy cards and
//  are gone when it ends. Three customers lost end the run.
//
//  The run starts with one plate and no glass; the glass appears once the
//  dessert does, a second plate after 6 dishes and a second glass after 14.
//

import Foundation

nonisolated enum MarathonCardError: Error, Equatable {
    case notOffered(MarathonCard)
    case onePerBreak
    case notEnoughCoins(have: Int, price: Int)
}

@Observable
final class MarathonSession {
    static let roundSec: TimeInterval = 90
    static let breakSec = 15
    static let secondPlateAtDishes = 6
    static let secondGlassAtDishes = 14

    /// The marathon's kitchen: the prototype's marathon physics. Customers
    /// and bubbles come from MarathonFlow and MarathonBubbleSupply.
    static let level = LevelData(
        id: "marathon", name: "Marathon", planet: "kepler-186f",
        durationSec: roundSec, refill: nil,
        gravity: .init(direction: .down, multiplier: 0.6),
        bubbleLifeSec: 4, bubbleEverySec: 2, usefulBubbleShare: MarathonBubbleSupply.usefulShare,
        cups: true, burnTimeMultiplier: 1, starTargets: [], energyCost: 8,
        pool: MarathonStage.two.bubblePool, bubbles: MarathonBubbleSupply.starters
    )

    /// The whole run, round after round.
    let day: KitchenDay

    private(set) var round = 1
    private(set) var breaksTaken = 0
    private(set) var owned: Set<MarathonCard> = []
    /// The cards on offer at the current break.
    private(set) var offer: [MarathonCard] = []
    private(set) var boughtThisBreak: MarathonCard?
    private(set) var coinsSpent = 0
    private(set) var bakeSec = KitchenRules.bakeSec
    private(set) var grillSlots = 1

    init(positionTypes: [CustomerType], random: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        day = KitchenDay(
            level: Self.level, flow: MarathonFlow(random: random), positionTypes: positionTypes,
            tools: KitchenTools(plates: 1, glasses: 0)
        )
        day.roundEndsAt = Self.roundSec
    }

    // MARK: - Score

    /// Marathon coins still to spend: every tip so far, less the cards bought.
    var coins: Int { day.tips - coinsSpent }
    /// Every marathon coin earned this run, spent or not.
    var coinsEarned: Int { day.tips }
    /// Points and tips: the run's score.
    var points: Int { day.total }
    var dishesServed: Int { day.ordersDelivered }
    var isOver: Bool { day.isOver }
    /// Rounds started, the one being played included.
    var roundsPlayed: Int { round }
    var averageDishesPerRound: Int { dishesServed / max(round, 1) }

    // MARK: - Breaks

    /// The round's time is up: freeze and put up the break's cards.
    func startBreak() {
        breaksTaken += 1
        boughtThisBreak = nil
        offer = MarathonCard.offer(forBreak: breaksTaken, owning: owned)
    }

    /// Back to play for the next round.
    func endBreak() {
        round += 1
        day.roundEndsAt = (day.roundEndsAt ?? 0) + Self.roundSec
    }

    func buy(_ card: MarathonCard) throws(MarathonCardError) {
        guard offer.contains(card) else { throw .notOffered(card) }
        guard boughtThisBreak == nil else { throw .onePerBreak }
        guard coins >= card.price else { throw .notEnoughCoins(have: coins, price: card.price) }
        coinsSpent += card.price
        owned.insert(card)
        boughtThisBreak = card
        apply(card.effect)
    }

    private func apply(_ effect: MarathonCard.Effect) {
        switch effect {
        case .bakeSec(let seconds):
            bakeSec = max(MarathonCard.minBakeSec, seconds)
        case .grillSlots(let slots):
            grillSlots = max(grillSlots, slots)
        case .patienceScale(let scale):
            day.patienceScale = min(MarathonCard.maxPatienceScale, scale)
        case .ingredientValue(let ingredient, let value):
            day.pricing = day.pricing.upgrading([ingredient: value])
        }
    }

    // MARK: - Plates and glasses

    /// What should stand on the counter now.
    var tools: KitchenTools {
        let served = day.ordersDelivered
        let dessertSeen = MarathonStage.stage(afterServing: served) >= .two
            || day.presentCustomers.contains { $0.dish == KitchenMenu.slimyTentacles }
        let glasses = served >= Self.secondGlassAtDishes ? 2 : 1
        return KitchenTools(
            plates: served >= Self.secondPlateAtDishes ? 2 : 1,
            glasses: dessertSeen ? glasses : 0
        )
    }

    /// Puts out any plate or glass the run has just earned.
    func refreshTools() {
        let tools = tools
        if day.tools != tools { day.tools = tools }
    }
}
