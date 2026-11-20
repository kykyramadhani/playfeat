//
//  KitchenMenu.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  Every item a planet kitchen handles, by the id the level files use, and
//  the dishes they combine into. One place to spell them, so the stations,
//  the art lookup and the tests can't disagree about a name. Ids are unique
//  across planets, so one table serves them all; what differs per planet
//  (tools, stations, the angry order) lives in `PlanetKitchen`.
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

    // MARK: - Planet 2 ingredients

    static let rawNoodles = "tideNoodles"
    /// What the pot turns raw noodles into.
    static let boiledNoodles = "boiledTideNoodles"
    /// Boiled noodles left in the pot too long.
    static let mushyNoodles = "mushyTideNoodles"
    static let coral = "coralLeaf"
    static let urchin = "bubbleUrchin"
    static let rawClam = "lanternClam"
    /// What the grill turns a raw clam into.
    static let grilledClam = "grilledLanternClam"
    static let burntClam = "burntLanternClam"
    static let seaCookie = "seaCookie"
    static let starfishSugar = "starfishSugar"

    // MARK: - Dishes

    static let pepperFlatbread = "pepperFlatbread"
    static let mushroomFlatbread = "mushroomFlatbread"
    /// The glass dessert: green slime with a tentacle in it.
    static let slimyTentacles = "slimyTentacles"
    static let coralNoodles = "coralNoodles"
    static let urchinNoodles = "urchinNoodles"
    static let clamNoodles = "clamNoodles"
    /// Planet 2's dessert: a sea cookie with starfish sugar on top.
    static let starCookie = "starCookie"

    /// What goes into each dish: a base and a topping, added in either order.
    static let recipes: [String: Set<String>] = [
        pepperFlatbread: [bakedFlatbread, pepper],
        mushroomFlatbread: [bakedFlatbread, mushroom],
        slimyTentacles: [slime, tentacle],
        coralNoodles: [boiledNoodles, coral],
        urchinNoodles: [boiledNoodles, urchin],
        clamNoodles: [boiledNoodles, grilledClam],
        starCookie: [seaCookie, starfishSugar],
    ]

    /// Whether `item` is a finished dish a customer can order.
    static func isDish(_ item: String) -> Bool {
        recipes[item] != nil
    }

    /// What bubbles have to bring for `dish`: its recipe, with anything
    /// cooked caught raw, since the tools do the cooking.
    static func bubbleIngredients(of dish: String) -> Set<String> {
        Set((recipes[dish] ?? []).map(CookingRecipe.bubbleItem(for:)))
    }

    /// The items a dish is built on, which bubbles bring first.
    private static let bases: Set = [rawFlatbread, tentacle, rawNoodles, seaCookie]

    /// A dish's bubble ingredients, its base (flatbread, noodles, ...) first.
    static func orderedBubbleIngredients(of dish: String) -> [String] {
        bubbleIngredients(of: dish).sorted { bases.contains($0) && !bases.contains($1) }
    }

    /// Everything a bubble can bring: the dishes' ingredients, anything
    /// cooked caught raw.
    static let bubbleItems: Set<String> = recipes.keys.reduce(into: []) { $0.formUnion(bubbleIngredients(of: $1)) }

    /// Every dish `level`'s customers can order: the first order, the pool,
    /// and the angry aliens' order when the level has any.
    static func dishes(servedOn level: LevelData) -> Set<String> {
        guard let refill = level.refill else { return [] }
        let poolDishes = refill.orderPool.filter { $0.value > 0 }.keys
        let hasAngryAliens = !refill.angryAt.isEmpty || refill.angryEvery != nil
        let angryOrder = PlanetCatalog.planet(level.planet).kitchen.angryOrder
        return Set([refill.firstOrder] + poolDishes).union(hasAngryAliens ? [angryOrder] : [])
    }

    /// What `level`'s bubbles can hold, decoys included.
    static func pantry(for level: LevelData) -> Set<String> {
        Set(level.pool)
    }

    /// The dish made of exactly `items`, or nil when they make none.
    static func dish(madeFrom items: [String]) -> String? {
        let ingredients = Set(items)
        guard ingredients.count == items.count else { return nil }
        return recipes.first { $0.value == ingredients }?.key
    }
}
