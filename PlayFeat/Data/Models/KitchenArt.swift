//
//  KitchenArt.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Asset names for the planet-kitchen items, which the level files name by
//  id ("duskFlatbread", "pepperFlatbread"). Some items look different once
//  put down on a station: the mushroom is chopped on the plate, and the
//  tentacle, the slime and the finished dessert are drawn as the whole glass.
//  An upgraded ingredient (shop or marathon card) has a premium look, and so
//  does everything made from it that has premium art.
//

import CoreGraphics

nonisolated enum KitchenArt {
    /// The item's picture in a bubble, in a hand and on an order sheet;
    /// premium when the ingredient it comes from is in `upgraded`.
    static func image(of item: String, upgraded: Set<String> = []) -> String {
        premium(premiumImages[item], upgraded) ?? images[item] ?? item
    }

    /// The item's picture once put down on a station.
    static func placedImage(of item: String, upgraded: Set<String> = []) -> String {
        premium(premiumPlacedImages[item], upgraded) ?? placedImages[item] ?? image(of: item, upgraded: upgraded)
    }

    /// The premium picture, when its ingredient has been upgraded.
    private static func premium(_ art: PremiumArt?, _ upgraded: Set<String>) -> String? {
        art.flatMap { upgraded.contains($0.upgradedBy) ? $0.image : nil }
    }

    /// Pictures of the whole glass with something in it. Each is cut so its
    /// mug sits in the middle, `glassMugPixels` wide, so the scene can draw
    /// any of them straight over the counter's empty glass.
    static let glassStateImages: Set<String> = [
        "TentacleGlass", "SlimeGlass", "SlimyTentaclesGlass", "PremiumTentacleGlass", "PremiumSlimyTentaclesGlass",
    ]
    static let glassMugPixels: CGFloat = 346

    private static let images: [String: String] = [
        KitchenMenu.rawFlatbread: "FlatbreadRaw",
        KitchenMenu.bakedFlatbread: "FlatbreadBaked",
        KitchenMenu.burntFlatbread: "FlatbreadBurnt",
        KitchenMenu.pepper: "Pepper",
        KitchenMenu.mushroom: "GlowyMushroom",
        KitchenMenu.tentacle: "KitchenTentacle",
        KitchenMenu.slime: "Slime",
        KitchenMenu.pepperFlatbread: "PepperFlatbread",
        KitchenMenu.mushroomFlatbread: "MushroomFlatbread",
        KitchenMenu.slimyTentacles: "SlimyTentaclesGlass",
    ]

    private static let placedImages: [String: String] = [
        KitchenMenu.mushroom: "MushroomTopping",
        KitchenMenu.tentacle: "TentacleGlass",
        KitchenMenu.slime: "SlimeGlass",
    ]

    /// A premium picture and the ingredient whose upgrade earns it.
    private struct PremiumArt {
        let upgradedBy: String
        let image: String
    }

    private static let premiumImages: [String: PremiumArt] = [
        KitchenMenu.rawFlatbread: PremiumArt(upgradedBy: KitchenMenu.rawFlatbread, image: "PremiumFlatbreadRaw"),
        KitchenMenu.bakedFlatbread: PremiumArt(upgradedBy: KitchenMenu.rawFlatbread, image: "PremiumFlatbreadBaked"),
        KitchenMenu.burntFlatbread: PremiumArt(upgradedBy: KitchenMenu.rawFlatbread, image: "PremiumFlatbreadBurnt"),
        KitchenMenu.pepper: PremiumArt(upgradedBy: KitchenMenu.pepper, image: "PremiumPepper"),
        KitchenMenu.mushroom: PremiumArt(upgradedBy: KitchenMenu.mushroom, image: "PremiumGlowyMushroom"),
        KitchenMenu.slime: PremiumArt(upgradedBy: KitchenMenu.slime, image: "PremiumSlime"),
        KitchenMenu.tentacle: PremiumArt(upgradedBy: KitchenMenu.tentacle, image: "PremiumTentacle"),
        KitchenMenu.slimyTentacles: PremiumArt(upgradedBy: KitchenMenu.tentacle, image: "PremiumSlimyTentaclesGlass"),
    ]

    private static let premiumPlacedImages: [String: PremiumArt] = [
        KitchenMenu.mushroom: PremiumArt(upgradedBy: KitchenMenu.mushroom, image: "PremiumMushroomTopping"),
        KitchenMenu.tentacle: PremiumArt(upgradedBy: KitchenMenu.tentacle, image: "PremiumTentacleGlass"),
    ]
}
