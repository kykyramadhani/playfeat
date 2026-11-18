//
//  IngredientNeeds.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  What the counter's orders still need from the bubbles, given what is
//  already in the kitchen. Bubbles are aimed at these, as in the prototype.
//

nonisolated enum IngredientNeeds {
    /// What a kitchen item counts as towards an order: a dish as itself, a
    /// raw or cooked item as that item to come, a ruined one as nothing.
    static func countedItem(_ item: String) -> String? {
        guard let recipe = CookingRecipe.recipe(of: item) else { return item }
        return item == recipe.ruined ? nil : recipe.raw
    }

    /// The ingredients `orders` (oldest first) still lack once `inventory`
    /// is used up, oldest order's first. An order whose dish is already
    /// made needs nothing.
    static func missing(for orders: [String], inventory: [String]) -> [String] {
        var stock = inventory.compactMap(countedItem).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        var missing: [String] = []
        for dish in orders {
            if take(dish, from: &stock) { continue }
            for ingredient in KitchenMenu.orderedBubbleIngredients(of: dish) where !take(ingredient, from: &stock) {
                missing.append(ingredient)
            }
        }
        return missing
    }

    /// Every ingredient `orders` are made from.
    static func all(for orders: [String]) -> [String] {
        orders.flatMap(KitchenMenu.orderedBubbleIngredients(of:))
    }

    private static func take(_ item: String, from stock: inout [String: Int]) -> Bool {
        guard let count = stock[item], count > 0 else { return false }
        stock[item] = count - 1
        return true
    }
}
