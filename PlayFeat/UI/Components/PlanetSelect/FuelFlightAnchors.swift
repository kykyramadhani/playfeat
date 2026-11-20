//
//  FuelFlightAnchors.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  Where the level cards and the fuel gauge sit on the planet board, so a
//  newly earned star can fly from its card to the gauge.
//

import SwiftUI

nonisolated struct FuelFlightAnchors: PreferenceKey {
    struct Value {
        /// Each level card's bounds, by its index on the board.
        var cards: [Int: Anchor<CGRect>] = [:]
        var gauge: Anchor<CGRect>?
    }

    static var defaultValue: Value { Value() }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        let next = nextValue()
        value.cards.merge(next.cards) { _, newer in newer }
        value.gauge = next.gauge ?? value.gauge
    }
}
