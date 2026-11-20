//
//  KitchenShop.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  What each planet's kitchen shop sells, on two tabs. Ingredients raise
//  what the dishes they go in are worth; tools put a second plate, glass or
//  noodle bowl on the counter. An item goes on sale once a set level is
//  cleared, and is sold on that level's planet. Planet 1's values follow the
//  prototype, Planet 2's its level design (18 Nov); prices are placeholders
//  until the economy is balanced.
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

    /// Sold on the planet of the level that puts it on sale.
    var planet: Planet.ID? {
        PlanetCatalog.planet(forLevel: availableAfter)?.id
    }
}

nonisolated enum KitchenShop {
    /// Every planet's ingredients tab, each with the bubble ingredient
    /// whose value it raises.
    static let ingredientUpgrades: [(ingredient: String, upgrade: KitchenUpgrade)] = [
        ingredient(KitchenMenu.rawFlatbread, upgradedTo: 16, price: 45, after: "1-1"),
        ingredient(KitchenMenu.pepper, upgradedTo: 18, price: 35, after: "1-1"),
        ingredient(KitchenMenu.mushroom, upgradedTo: 24, price: 30, after: "1-2"),
        ingredient(KitchenMenu.tentacle, upgradedTo: 17, price: 25, after: "1-3"),
        ingredient(KitchenMenu.slime, upgradedTo: 12, price: 25, after: "1-3"),
        ingredient(KitchenMenu.rawNoodles, upgradedTo: 15, price: 55, after: "2-1"),
        ingredient(KitchenMenu.coral, upgradedTo: 15, price: 30, after: "2-1"),
        ingredient(KitchenMenu.urchin, upgradedTo: 15, price: 30, after: "2-2"),
        ingredient(KitchenMenu.rawClam, upgradedTo: 20, price: 40, after: "2-3"),
        ingredient(KitchenMenu.seaCookie, upgradedTo: 15, price: 30, after: "2-4"),
        ingredient(KitchenMenu.starfishSugar, upgradedTo: 10, price: 20, after: "2-4"),
    ]

    /// Every planet's items, both tabs. Planet 2 sells a second bowl but
    /// no second cookie plate: its counter has room for only one.
    /// ponytail: the design's Planet 2 tool upgrades (Faster Pot, Faster
    /// Grill, Longer Hold, Bigger Grill) wait for their prices from the
    /// balancing sheet.
    static let upgrades: [KitchenUpgrade] = ingredientUpgrades.map(\.upgrade) + [
        KitchenUpgrade(id: plateID, tab: .tools, image: "KitchenPlate", stat: .count(icon: "KitchenPlate"),
                       values: [1, 2], prices: [30], availableAfter: "1-1"),
        KitchenUpgrade(id: glassID, tab: .tools, image: "KitchenGlass", stat: .count(icon: "KitchenGlass"),
                       values: [1, 2], prices: [30], availableAfter: "1-4"),
        KitchenUpgrade(id: bowlID, tab: .tools, image: "NoodleBowl", stat: .count(icon: "NoodleBowl"),
                       values: [1, 2], prices: [30], availableAfter: "2-1"),
    ]

    static let plateID = "tool.plate"
    static let glassID = "tool.glass"
    static let bowlID = "tool.bowl"

    /// What `planet`'s shop sells on `tab`.
    static func upgrades(on tab: KitchenUpgrade.Tab, planet: Planet.ID) -> [KitchenUpgrade] {
        upgrades.filter { $0.tab == tab && $0.planet == planet }
    }

    /// The upgrade that adds a second main station (plate, bowl) on `planet`.
    static func mainStationID(on planet: Planet.ID) -> String {
        switch planet {
        case .kepler186f: plateID
        case .k2332b: bowlID
        }
    }

    /// The upgrade that adds a second dessert station on `planet`, if it sells one.
    static func dessertStationID(on planet: Planet.ID) -> String? {
        switch planet {
        case .kepler186f: glassID
        case .k2332b: nil
        }
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
