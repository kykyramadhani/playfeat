//
//  ShopUpgrade.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  One upgrade the shop sells: an ingredient that sells for more, or a tool
//  that works faster. Each level costs coins to reach; past the last level it
//  is maxed out, and a locked one can't be bought at all yet.
//

nonisolated struct ShopUpgrade: Equatable {
    /// What the upgrade improves, which decides the icon beside its numbers.
    enum Stat: Equatable {
        /// Coins a dish with it earns.
        case coins
        /// Seconds the tool takes.
        case seconds
        /// How many of the tool stand on the counter, shown beside a small one of it.
        case count(icon: String)
    }

    /// What the card offers right now.
    enum Offer: Equatable {
        case buy(from: Int, to: Int, price: Int, canAfford: Bool)
        case maxed(value: Int)
        case locked
    }

    let image: String
    let stat: Stat
    /// The stat at each level, from level 0.
    let values: [Int]
    /// Coins to buy each next level: `prices[n]` takes level n to n + 1.
    let prices: [Int]
    let isUnlocked: Bool

    func offer(atLevel level: Int, coins: Int) -> Offer {
        guard isUnlocked, values.indices.contains(level) else { return .locked }
        guard values.indices.contains(level + 1), prices.indices.contains(level) else {
            return .maxed(value: values[level])
        }
        let price = prices[level]
        return .buy(from: values[level], to: values[level + 1], price: price, canAfford: coins >= price)
    }
}
