//
//  BuffetPlan.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  What makes one planet's Buffet (the marathon) its own: the customers and
//  bubbles of each stage, when stage two starts, how the run opens, its
//  gravity and its upgrade cards. The rules every Buffet shares (rounds,
//  breaks, the ramp, tips) stay in MarathonSession and MarathonFlow.
//

import Foundation

nonisolated struct BuffetPlan {
    /// One stage's customers and bubbles.
    struct StageMix {
        /// How many customers wait at the counter at once.
        let maxWaiting: Int
        let bubblePool: [String]
        /// One group of customers, dealt again and again in a fresh random order.
        let group: [CustomerOrder]

        func dealGroup(using generator: inout some RandomNumberGenerator) -> [CustomerOrder] {
            group.shuffled(using: &generator)
        }
    }

    let stageOne: StageMix
    let stageTwo: StageMix
    let stageTwoAtDishes: Int
    /// What the run's first customer orders, so it starts easy.
    let firstOrder: String
    /// The first bubbles, before the supply starts following demand.
    let starters: [LevelData.BubbleEntry]
    let gravity: LevelData.Gravity
    let cards: MarathonCard.Deck

    func stage(afterServing dishesServed: Int) -> MarathonStage {
        dishesServed >= stageTwoAtDishes ? .two : .one
    }

    func mix(of stage: MarathonStage) -> StageMix {
        switch stage {
        case .one: stageOne
        case .two: stageTwo
        }
    }
}
