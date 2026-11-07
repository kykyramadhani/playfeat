//
//  MarathonStage.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  The marathon's stages: which dishes customers order and how many wait at
//  once. Proposal from "11. Developer review", pending team agreement.
//

import Foundation

nonisolated struct CustomerOrder: Equatable {
    let type: CustomerType
    let dish: String
}

nonisolated enum MarathonStage: Equatable {
    /// Pepper and Mushroom Flatbread, 2 customers at once.
    case one
    /// Adds Sunset Sorbet and angry aliens, 3 customers at once.
    case two

    static let stageTwoAtDishes = 8

    static func stage(afterServing dishesServed: Int) -> MarathonStage {
        dishesServed >= stageTwoAtDishes ? .two : .one
    }

    var maxWaiting: Int {
        switch self {
        case .one: 2
        case .two: 3
        }
    }

    /// The next 5 customers, in a fresh random order every time. Stage two has
    /// exactly one angry alien per group, at a random place.
    func dealGroup(using generator: inout some RandomNumberGenerator) -> [CustomerOrder] {
        groupOrders.shuffled(using: &generator)
    }

    private var groupOrders: [CustomerOrder] {
        switch self {
        case .one:
            regulars("pepperFlatbread", count: 3) + regulars("mushroomFlatbread", count: 2)
        case .two:
            [CustomerOrder(type: .angry, dish: "sunsetSorbet")]
                + regulars("pepperFlatbread", count: 2)
                + regulars("mushroomFlatbread", count: 1)
                + regulars("sunsetSorbet", count: 1)
        }
    }

    private func regulars(_ dish: String, count: Int) -> [CustomerOrder] {
        Array(repeating: CustomerOrder(type: .regular, dish: dish), count: count)
    }
}
