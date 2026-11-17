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

    /// Levels 1–3 teach the grill and the two flatbreads, level 4 brings the
    /// glass and its dessert, and from level 5 the angry red alien comes in.
    static let kepler186f = Planet(
        name: "Kepler-186f",
        levelIDs: ["1-1", "1-2", "1-3", "1-4", "1-5", "1-6"]
    )
}
