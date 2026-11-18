//
//  Planet.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  A planet is a run of days (levels) played in order, its Buffet (the
//  marathon, BuffetPlan), and everything that makes its kitchen its own
//  (PlanetKitchen).
//  The gameplay code reads all of it from here, so a new planet is a new
//  definition (see the `Planet/` folder) and its level files, not new code.
//  Level IDs match the `level_<id>.json` files and the keys stars are saved
//  under.
//

import Foundation

nonisolated struct Planet {
    /// How level files name their planet.
    enum ID: String, Codable, CaseIterable {
        case kepler186f = "kepler-186f"
        case k2332b = "k2-332b"
    }

    let id: ID
    /// Shown on the planet's banner; a proper noun, so the same in every language.
    let name: String
    let levelIDs: [String]
    let kitchen: PlanetKitchen
    let buffet: BuffetPlan
    let backdrop: PlanetBackdrop
}
