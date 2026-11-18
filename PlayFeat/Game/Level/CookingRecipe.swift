//
//  CookingRecipe.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  What a cooking tool turns an item into: caught raw, cooked when done,
//  ruined when left too long. One table for every planet's tools, so the
//  pot and the grill share one set of cooking rules.
//

nonisolated struct CookingRecipe: Equatable {
    let raw: String
    let cooked: String
    /// What the item becomes when left too long: burnt, or mushy.
    let ruined: String

    /// Planet 1: the grill bakes the flatbread.
    static let flatbread = CookingRecipe(
        raw: KitchenMenu.rawFlatbread, cooked: KitchenMenu.bakedFlatbread, ruined: KitchenMenu.burntFlatbread
    )
    /// Planet 2: the pot boils the noodles.
    static let noodles = CookingRecipe(
        raw: KitchenMenu.rawNoodles, cooked: KitchenMenu.boiledNoodles, ruined: KitchenMenu.mushyNoodles
    )
    /// Planet 2: the grill opens the clam.
    static let clam = CookingRecipe(
        raw: KitchenMenu.rawClam, cooked: KitchenMenu.grilledClam, ruined: KitchenMenu.burntClam
    )

    static let all: [CookingRecipe] = [flatbread, noodles, clam]

    /// The recipe that makes or ruins `item`, or nil when no tool cooks it.
    static func recipe(of item: String) -> CookingRecipe? {
        all.first { [$0.raw, $0.cooked, $0.ruined].contains(item) }
    }

    /// What a bubble has to bring for `item`: the raw version of anything
    /// cooked, the item itself otherwise.
    static func bubbleItem(for item: String) -> String {
        recipe(of: item)?.raw ?? item
    }
}
