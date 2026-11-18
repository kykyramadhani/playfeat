//
//  MarathonStage.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  The marathon's stages, as in the prototype: the run opens on stage one
//  and moves to stage two once enough dishes are served. What each stage
//  orders, which bubbles it brings and how many customers wait at once is
//  the planet's (BuffetPlan).
//

import Foundation

nonisolated struct CustomerOrder: Equatable {
    let type: CustomerType
    let dish: String

    /// `count` regular customers who all order `dish`.
    static func regulars(_ dish: String, count: Int) -> [CustomerOrder] {
        Array(repeating: CustomerOrder(type: .regular, dish: dish), count: count)
    }
}

nonisolated enum MarathonStage: Int, Comparable {
    /// The planet's simplest dishes, 2 customers at once.
    case one = 1
    /// Adds the dessert and angry aliens, 3 customers at once.
    case two = 2

    static func < (lhs: MarathonStage, rhs: MarathonStage) -> Bool { lhs.rawValue < rhs.rawValue }
}
