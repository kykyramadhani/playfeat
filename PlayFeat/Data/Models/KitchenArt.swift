//
//  KitchenArt.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Asset names for the planet-kitchen items, which the level files name by
//  id ("duskFlatbread", "pepperFlatbread"). Some items look different once
//  put down on a station: the mushroom is chopped on the plate, and the
//  tentacle and the finished dessert are drawn as the whole glass.
//

import CoreGraphics

nonisolated enum KitchenArt {
    /// The item's picture in a bubble, in a hand and on an order sheet.
    static func image(of item: String) -> String {
        images[item] ?? item
    }

    /// A cooking tool's picture on the counter.
    static func image(of tool: CookingTool.Kind) -> String {
        switch tool {
        case .grill: "KitchenGrill"
        // ponytail: the shop's pot stands in until the kitchen pot is drawn.
        case .pot: "CookingPot"
        }
    }

    /// The item's picture once put down on a station.
    static func placedImage(of item: String) -> String {
        placedImages[item] ?? image(of: item)
    }

    /// Pictures of the whole glass with something in it. Each is cut so its
    /// mug sits in the middle, `glassMugPixels` wide, so the scene can draw
    /// any of them straight over the counter's empty glass.
    static let glassStateImages: Set<String> = ["TentacleGlass", "SlimyTentaclesGlass"]
    static let glassMugPixels: CGFloat = 346

    private static let images: [String: String] = [
        KitchenMenu.rawFlatbread: "FlatbreadRaw",
        KitchenMenu.bakedFlatbread: "FlatbreadBaked",
        KitchenMenu.burntFlatbread: "FlatbreadBurnt",
        KitchenMenu.pepper: "Pepper",
        KitchenMenu.mushroom: "GlowyMushroom",
        KitchenMenu.tentacle: "KitchenTentacle",
        // ponytail: the slime has no picture of its own in Figma yet; the green
        // mug drink stands in until the designers add one.
        KitchenMenu.slime: "GreenMugDrink",
        KitchenMenu.pepperFlatbread: "PepperFlatbread",
        KitchenMenu.mushroomFlatbread: "MushroomFlatbread",
        KitchenMenu.slimyTentacles: "SlimyTentaclesGlass",
        // ponytail: Planet 2 has no art yet; Planet 1 and shop pictures stand
        // in, one per item so playtesters can still tell them apart.
        KitchenMenu.rawNoodles: "FlatbreadRaw",
        KitchenMenu.boiledNoodles: "FlatbreadBaked",
        KitchenMenu.mushyNoodles: "FlatbreadBurnt",
        KitchenMenu.coral: "CoralLettuce",
        KitchenMenu.urchin: "GlowyMushroom",
        KitchenMenu.rawClam: "KitchenTentacle",
        KitchenMenu.grilledClam: "PremiumTentacle",
        KitchenMenu.burntClam: "FlatbreadBurnt",
        KitchenMenu.seaCookie: "Coin",
        KitchenMenu.starfishSugar: "FuelGaugeStar",
        KitchenMenu.coralNoodles: "PepperFlatbread",
        KitchenMenu.urchinNoodles: "MushroomFlatbread",
        KitchenMenu.clamNoodles: "PremiumFlatbreadBaked",
        KitchenMenu.starCookie: "LevelStar",
    ]

    private static let placedImages: [String: String] = [
        KitchenMenu.mushroom: "MushroomTopping",
        KitchenMenu.tentacle: "TentacleGlass",
        KitchenMenu.urchin: "MushroomTopping",
    ]
}
