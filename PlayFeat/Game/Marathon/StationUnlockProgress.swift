//
//  StationUnlockProgress.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  The marathon HUD's side bar as numbers: how far the dishes served have
//  filled it, and where each plate or glass the run puts out is marked.
//  The bar is full at the last unlock.
//

import Foundation

nonisolated struct StationUnlockProgress: Equatable {
    let dishesServed: Int
    /// Dishes served at which another station comes out, lowest first.
    let unlocks: [Int]

    /// The dishes that fill the bar: the last unlock.
    var goal: Int { unlocks.last ?? 0 }

    /// How full the bar is, from 0 to 1.
    var filledShare: Double { share(at: dishesServed) }

    /// How far up the bar `dishes` sits, from 0 to 1.
    func share(at dishes: Int) -> Double {
        guard goal > 0 else { return 1 }
        return (Double(dishes) / Double(goal)).clamped(to: 0...1)
    }
}
