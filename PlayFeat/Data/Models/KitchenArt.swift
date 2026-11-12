//
//  KitchenArt.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Asset names for the planet-kitchen ingredients and dishes, which the level
//  files name by id ("duskFlatbread", "pepperFlatbread").
//

import CoreGraphics

nonisolated enum KitchenArt {
    /// "duskFlatbread" → "DuskFlatbread": each ingredient's asset is its id,
    /// capitalised, unless it is still borrowing a placeholder.
    static func ingredientImage(_ ingredient: String) -> String {
        placeholderImages[ingredient] ?? ingredient.prefix(1).uppercased() + ingredient.dropFirst()
    }

    /// ponytail: these have no art yet, so they borrow existing pictures.
    /// Delete an entry once its own imageset (named as above) is added.
    private static let placeholderImages = [
        KitchenMenu.burntFlatbread: "BakedFlatbread",
        KitchenMenu.slime: "GreenMugDrink",
        KitchenMenu.tentacle: "EmberPepper",
    ]

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

    /// The images that draw any kitchen item, dish or ingredient, back to front.
    static func layers(for item: String) -> [String] {
        let dish = dishLayers(item)
        return dish.isEmpty ? [ingredientImage(item)] : dish
    }

    /// How far an item's art is darkened toward black, 0 for none. Burnt
    /// flatbread borrows the baked one's picture and is told apart this way.
    static func darkening(of item: String) -> CGFloat {
        item == KitchenMenu.burntFlatbread ? 0.65 : 0
    }
}
