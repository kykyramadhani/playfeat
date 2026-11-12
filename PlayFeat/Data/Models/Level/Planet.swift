//
//  Planet.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  A planet is a run of days (levels) played in order, ending in its
//  marathon. Level IDs match the `level_<id>.json` files and the keys stars
//  are saved under.
//

import Foundation

nonisolated struct Planet {
    /// Shown on the planet's banner; a proper noun, so the same in every language.
    let name: String
    let levelIDs: [String]
    /// Every ingredient this planet's bubbles can hold.
    let pantry: Set<String>

    static let kepler186f = Planet(
        name: "Kepler-186f",
        levelIDs: ["1-1", "1-2", "1-3", "1-4"],
        pantry: ["duskFlatbread", "emberPepper", "duskMushroom"]
    )
}
