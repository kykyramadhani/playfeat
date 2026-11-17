//
//  MarathonStage.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  The marathon's stages, as in the prototype: which dishes customers order,
//  which ingredients the bubbles bring, and how many customers wait at once.
//

import Foundation

nonisolated struct CustomerOrder: Equatable {
    let type: CustomerType
    let dish: String
}

nonisolated enum MarathonStage: Int, Comparable {
    /// Pepper and Mushroom Flatbread, 2 customers at once.
    case one = 1
    /// Adds Slimy Tentacles and angry aliens, 3 customers at once.
    case two = 2

    static let stageTwoAtDishes = 8

    static func stage(afterServing dishesServed: Int) -> MarathonStage {
        dishesServed >= stageTwoAtDishes ? .two : .one
    }

    static func < (lhs: MarathonStage, rhs: MarathonStage) -> Bool { lhs.rawValue < rhs.rawValue }

    var maxWaiting: Int {
        switch self {
        case .one: 2
        case .two: 3
        }
    }

    var bubblePool: [String] {
        let flatbreads = [KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom]
        switch self {
        case .one: return flatbreads
        case .two: return flatbreads + [KitchenMenu.tentacle, KitchenMenu.slime]
        }
    }

    /// The next customers, in a fresh random order every time. Stage two has
    /// exactly one angry alien per group, at a random place.
    func dealGroup(using generator: inout some RandomNumberGenerator) -> [CustomerOrder] {
        groupOrders.shuffled(using: &generator)
    }

    private var groupOrders: [CustomerOrder] {
        switch self {
        case .one:
            regulars(KitchenMenu.pepperFlatbread, count: 3) + regulars(KitchenMenu.mushroomFlatbread, count: 2)
        case .two:
            [CustomerOrder(type: .angry, dish: KitchenMenu.angryOrder)]
                + regulars(KitchenMenu.pepperFlatbread, count: 2)
                + regulars(KitchenMenu.mushroomFlatbread, count: 1)
                + regulars(KitchenMenu.slimyTentacles, count: 1)
        }
    }

    private func regulars(_ dish: String, count: Int) -> [CustomerOrder] {
        Array(repeating: CustomerOrder(type: .regular, dish: dish), count: count)
    }
}
