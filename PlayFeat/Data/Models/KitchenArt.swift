//
//  KitchenArt.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Asset names for the planet-kitchen ingredients and dishes, which the level
//  files name by id ("duskFlatbread", "pepperFlatbread").
//

nonisolated enum KitchenArt {
    /// "duskFlatbread" → "DuskFlatbread": each ingredient's asset is its id, capitalised.
    static func ingredientImage(_ ingredient: String) -> String {
        ingredient.prefix(1).uppercased() + ingredient.dropFirst()
    }

    /// The images stacked to draw a finished dish, back to front.
    /// ponytail: the green mug drink is a guess for the sorbet until its art is named in Figma.
    static func dishLayers(_ dish: String) -> [String] {
        switch dish {
        case "pepperFlatbread": ["BakedFlatbread", "EmberPepper"]
        case "mushroomFlatbread": ["BakedFlatbread", "DuskMushroom"]
        case "sunsetSorbet": ["GreenMugDrink"]
        default: []
        }
    }
}
