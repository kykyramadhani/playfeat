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
    /// The glass dessert: green slime with a tentacle in it.
    static let slimyTentacles = "slimyTentacles"

    /// What goes into each dish: a base and a topping, added in either order.
    static let recipes: [String: Set<String>] = [
        pepperFlatbread: [bakedFlatbread, pepper],
        mushroomFlatbread: [bakedFlatbread, mushroom],
        slimyTentacles: [slime, tentacle],
    ]

    /// What bubbles have to bring for `dish`: its recipe, with the flatbread
    /// caught raw, since the grill does the baking.
    static func bubbleIngredients(of dish: String) -> Set<String> {
        Set((recipes[dish] ?? []).map { $0 == bakedFlatbread ? rawFlatbread : $0 })
    }

    /// A dish's bubble ingredients, its base (flatbread, tentacle) first.
    static func orderedBubbleIngredients(of dish: String) -> [String] {
        let bases: Set = [rawFlatbread, tentacle]
        return bubbleIngredients(of: dish).sorted { bases.contains($0) && !bases.contains($1) }
    }

    /// Everything a bubble can bring: the dishes' ingredients, the
    /// flatbread caught raw.
    static let bubbleItems: Set<String> = recipes.keys.reduce(into: []) { $0.formUnion(bubbleIngredients(of: $1)) }

    /// Every dish `level`'s customers can order: the first order, the pool,
    /// and the angry aliens' dessert when the level has any.
    static func dishes(servedOn level: LevelData) -> Set<String> {
        guard let refill = level.refill else { return [] }
        let poolDishes = refill.orderPool.filter { $0.value > 0 }.keys
        let hasAngryAliens = !refill.angryAt.isEmpty || refill.angryEvery != nil
        return Set([refill.firstOrder] + poolDishes).union(hasAngryAliens ? [angryOrder] : [])
    }

    /// What `level`'s bubbles can hold, decoys included.
    static func pantry(for level: LevelData) -> Set<String> {
        Set(level.pool)
    }

    /// What an angry alien always orders.
    static let angryOrder = slimyTentacles

    /// The dish made of exactly `items`, or nil when they make none.
    static func dish(madeFrom items: [String]) -> String? {
        let ingredients = Set(items)
        guard ingredients.count == items.count else { return nil }
        return recipes.first { $0.value == ingredients }?.key
    }
}
