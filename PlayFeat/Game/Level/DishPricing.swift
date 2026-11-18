//
//  DishPricing.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  What a served dish is worth: the sum of its ingredients' values, as in
//  the prototype (flatbread 10, pepper 10, mushroom 15, tentacle 10, slime
//  5). The shop's ingredient upgrades and the marathon's cards raise them.
//

nonisolated struct DishPricing: Equatable {
    /// Each bubble ingredient's value before any upgrade.
    static let baseValues: [String: Int] = [
        KitchenMenu.rawFlatbread: 10,
        KitchenMenu.pepper: 10,
        KitchenMenu.mushroom: 15,
        KitchenMenu.tentacle: 10,
        KitchenMenu.slime: 5,
        KitchenMenu.rawNoodles: 10,
        KitchenMenu.coral: 10,
        KitchenMenu.urchin: 10,
        KitchenMenu.rawClam: 15,
        KitchenMenu.seaCookie: 10,
        KitchenMenu.starfishSugar: 5,
    ]

    /// Upgraded values; an ingredient missing here keeps its base value.
    let ingredientValues: [String: Int]

    static let unupgraded = DishPricing(ingredientValues: [:])

    func pay(for dish: String) -> Int {
        KitchenMenu.bubbleIngredients(of: dish).reduce(0) { $0 + value(of: $1) }
    }

    func value(of ingredient: String) -> Int {
        ingredientValues[ingredient] ?? Self.baseValues[ingredient] ?? 0
    }

    /// The ingredients worth more than their base value: drawn premium.
    var upgradedIngredients: Set<String> {
        Set(ingredientValues.filter { $0.value > Self.baseValues[$0.key] ?? 0 }.keys)
    }

    /// These values on top of the current ones.
    func upgrading(_ values: [String: Int]) -> DishPricing {
        DishPricing(ingredientValues: ingredientValues.merging(values) { _, new in new })
    }
}
