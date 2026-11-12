//
//  KitchenMenu.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  Every item a planet kitchen handles, by the id the level files use, and
//  the dishes they combine into. One place to spell them, so the stations,
//  the art lookup and the tests can't disagree about a name.
//

nonisolated enum KitchenMenu {
    // MARK: - Ingredients

    static let rawFlatbread = "duskFlatbread"
    /// What the grill turns a raw flatbread into.
    static let bakedFlatbread = "bakedFlatbread"
    /// What a baked flatbread left on the grill too long turns into.
    static let burntFlatbread = "burntFlatbread"
    static let pepper = "emberPepper"
    static let mushroom = "duskMushroom"
    static let slime = "slime"
    static let tentacle = "tentacle"

    // MARK: - Dishes

    static let pepperFlatbread = "pepperFlatbread"
    static let mushroomFlatbread = "mushroomFlatbread"
    static let sunsetSorbet = "sunsetSorbet"

    /// What goes into each dish. The order things are added in doesn't matter.
    static let recipes: [String: Set<String>] = [
        pepperFlatbread: [bakedFlatbread, pepper],
        mushroomFlatbread: [bakedFlatbread, mushroom],
        sunsetSorbet: [slime, tentacle],
    ]

    /// The dish made of exactly `items`, or nil when they make none.
    static func dish(madeFrom items: [String]) -> String? {
        let ingredients = Set(items)
        guard ingredients.count == items.count else { return nil }
        return recipes.first { $0.value == ingredients }?.key
    }
}
