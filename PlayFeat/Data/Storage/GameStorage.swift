//
//  GameStorage.swift
//  GetCooking
//
//  Created by Owen Limantoro on 23/08/26.
//

import Foundation

struct GameStorage {
    static let coinKey = "coins"


    static var coins: Int {
        get {
            UserDefaults.standard.integer(forKey: self.coinKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: self.coinKey)
        }
    }
    
    nonisolated static func bestStarsKey(forLevel levelID: String) -> String { "bestStars_\(levelID)" }

    /// A planet's progress from the best stars saved for its levels.
    static func progress(on planet: Planet) -> PlanetProgress {
        PlanetProgress(bestStars: planet.levelIDs.map(bestStars(forLevel:)))
    }

    static func bestStars(forLevel levelID: String) -> Int {
        UserDefaults.standard.integer(forKey: bestStarsKey(forLevel: levelID))
    }

    /// Keeps the higher of `stars` and the level's previous best.
    static func recordStars(_ stars: Int, forLevel levelID: String) {
        guard stars > bestStars(forLevel: levelID) else { return }
        UserDefaults.standard.set(stars, forKey: bestStarsKey(forLevel: levelID))
    }

    static let seenIntroductionsKey = "seenIntroductions"

    /// Recipe-book unlocks and other story introductions already seen.
    static var seenIntroductions: Set<String> {
        seenIntroductions(in: .standard)
    }

    static func seenIntroductions(in defaults: UserDefaults) -> Set<String> {
        Set(defaults.stringArray(forKey: seenIntroductionsKey) ?? [])
    }

    static func markIntroductionSeen(_ id: String, in defaults: UserDefaults = .standard) {
        markIntroductionsSeen([id], in: defaults)
    }

    static func markIntroductionsSeen(_ ids: [String], in defaults: UserDefaults = .standard) {
        let previous = seenIntroductions(in: defaults)
        let updated = previous.union(ids)
        guard updated != previous else { return }
        defaults.set(updated.sorted(), forKey: seenIntroductionsKey)
    }

    // MARK: - Kitchen shop

    static func upgradeLevelKey(_ id: String) -> String { "upgrade_\(id)" }

    /// How many levels of a KitchenShop upgrade the player has bought.
    static func upgradeLevel(_ id: String) -> Int {
        UserDefaults.standard.integer(forKey: upgradeLevelKey(id))
    }

    /// Pays `price` coins for the next level of upgrade `id`.
    static func buyUpgrade(_ id: String, price: Int) throws(ShopPurchaseError) {
        guard coins >= price else { throw .notEnoughCoins(have: coins, price: price) }
        coins -= price
        UserDefaults.standard.set(upgradeLevel(id) + 1, forKey: upgradeLevelKey(id))
    }

    /// Plates (or noodle bowls) on `planet`'s counter: one to start, two
    /// with that planet's shop upgrade.
    static func kitchenPlates(on planet: Planet.ID) -> Int {
        ownedTools(KitchenShop.mainStationID(on: planet))
    }

    /// Glasses (or cookie plates), the same way; one where none is sold.
    static func kitchenGlasses(on planet: Planet.ID) -> Int {
        KitchenShop.dessertStationID(on: planet).map(ownedTools) ?? 1
    }

    private static func ownedTools(_ id: String) -> Int {
        KitchenShop.upgrade(id)?.value(atLevel: upgradeLevel(id)) ?? 1
    }

    /// What each ingredient adds to a dish's pay, after its upgrade.
    static var dishPricing: DishPricing {
        let values = KitchenShop.ingredientUpgrades.map { item in
            (item.ingredient, item.upgrade.value(atLevel: upgradeLevel(item.upgrade.id)))
        }
        return DishPricing(ingredientValues: Dictionary(uniqueKeysWithValues: values))
    }

    /// Banks a finished planet-kitchen day: its stars, if they beat the
    /// level's best, and its income.
    static func recordDay(onLevel levelID: String, stars: Int, income: Int) {
        recordStars(stars, forLevel: levelID)
        coins = max(coins + income, 0)
    }

    /// Levels finished with at least one star: what the shop and the
    /// marathon open on.
    static func clearedLevels(on planet: Planet) -> Set<String> {
        Set(planet.levelIDs.filter { bestStars(forLevel: $0) > 0 })
    }

    static func marathonBestKey(on planet: Planet.ID) -> String { "marathonBestPoints_\(planet.rawValue)" }

    static func bestMarathonScore(on planet: Planet.ID, in defaults: UserDefaults = .standard) -> Int {
        defaults.integer(forKey: marathonBestKey(on: planet))
    }

    /// Keeps the higher of `score` and the planet's best Buffet points.
    /// - Returns: whether `score` is a new best.
    @discardableResult
    static func recordMarathon(score: Int, on planet: Planet.ID, in defaults: UserDefaults = .standard) -> Bool {
        guard score > bestMarathonScore(on: planet, in: defaults) else { return false }
        defaults.set(score, forKey: marathonBestKey(on: planet))
        return true
    }
}
