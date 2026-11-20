//
//  KitchenShop.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  What the planet kitchen's shop sells, on two tabs. Ingredients raise
//  what the dishes they go in are worth; tools put a second plate or glass
//  on the counter. On Kepler-186f the grill can't be upgraded yet (that
//  comes on planet 2). An item goes on sale once a set level is cleared,
//  as in the prototype. Values follow the prototype; prices are its
//  placeholders until the economy is balanced.
//

nonisolated struct KitchenUpgrade: Identifiable, Equatable {
    enum Tab: CaseIterable { case ingredients, tools }

    /// Saved under this, with how many levels of it are bought.
    let id: String
    let tab: Tab
    let image: String
    let stat: ShopUpgrade.Stat
    /// The stat at each level, from level 0.
    let values: [Int]
    /// `prices[n]` buys level n + 1.
    let prices: [Int]
    /// The level that has to be cleared (finished with a star) first.
    let availableAfter: String

    func upgrade(isUnlocked: Bool) -> ShopUpgrade {
        ShopUpgrade(image: image, stat: stat, values: values, prices: prices, isUnlocked: isUnlocked)
    }

    /// The stat at `level`, or the top value once past it.
    func value(atLevel level: Int) -> Int {
        values[min(max(level, 0), values.count - 1)]
    }

    func isUnlocked(clearedLevels: Set<String>) -> Bool {
        clearedLevels.contains(availableAfter)
    }
}

nonisolated enum KitchenShop {
    /// The ingredients tab, each with the bubble ingredient whose value it raises.
    static let ingredientUpgrades: [(ingredient: String, upgrade: KitchenUpgrade)] = [
        ingredient(KitchenMenu.rawFlatbread, upgradedTo: 16, price: 45, after: "1-1"),
        ingredient(KitchenMenu.pepper, upgradedTo: 18, price: 35, after: "1-1"),
        ingredient(KitchenMenu.mushroom, upgradedTo: 24, price: 30, after: "1-2"),
        ingredient(KitchenMenu.tentacle, upgradedTo: 17, price: 25, after: "1-3"),
        ingredient(KitchenMenu.slime, upgradedTo: 12, price: 25, after: "1-3"),
    ]

    static let upgrades: [KitchenUpgrade] = ingredientUpgrades.map(\.upgrade) + [
        KitchenUpgrade(id: plateID, tab: .tools, image: "KitchenPlate", stat: .count(icon: "KitchenPlate"),
                       values: [1, 2], prices: [30], availableAfter: "1-1"),
        KitchenUpgrade(id: glassID, tab: .tools, image: "KitchenGlass", stat: .count(icon: "KitchenGlass"),
                       values: [1, 2], prices: [30], availableAfter: "1-4"),
    ]

    static let plateID = "tool.plate"
    static let glassID = "tool.glass"

    static func upgrades(on tab: KitchenUpgrade.Tab) -> [KitchenUpgrade] {
        upgrades.filter { $0.tab == tab }
    }

    static func upgrade(_ id: String) -> KitchenUpgrade? {
        upgrades.first { $0.id == id }
    }

    /// An ingredient's upgrade, shown with the premium look it buys.
    private static func ingredient(
        _ item: String, upgradedTo value: Int, price: Int, after levelID: String
    ) -> (ingredient: String, upgrade: KitchenUpgrade) {
        let base = DishPricing.baseValues[item] ?? 0
        let upgrade = KitchenUpgrade(id: "ingredient.\(item)", tab: .ingredients,
                                     image: KitchenArt.premiumImage(of: item), stat: .coins,
                                     values: [base, value], prices: [price], availableAfter: levelID)
        return (item, upgrade)
    }
}

nonisolated enum ShopPurchaseError: Error, Equatable {
    case notEnoughCoins(have: Int, price: Int)
}
