//
//  KitchenArt.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Asset names for the planet-kitchen items, which the level files name by
//  id ("duskFlatbread", "pepperFlatbread"). Some items look different once
//  put down on a station: the mushroom is chopped on the plate, the
//  tentacle, the slime and the finished dessert are drawn as the whole glass,
//  noodles as the whole pot while they boil, and the noodle dishes as the
//  whole bowl. An upgraded ingredient (shop or marathon card) has a premium
//  look, and so does everything made from it that has premium art.
//

import CoreGraphics

nonisolated enum KitchenArt {
    /// The item's picture in a bubble, in a hand and on an order sheet;
    /// premium when the ingredient it comes from is in `upgraded`.
    static func image(of item: String, upgraded: Set<String> = []) -> String {
        premium(premiumImages[item], upgraded) ?? images[item] ?? item
    }

    /// The ingredient's premium picture, as the shop shows its upgrade.
    static func premiumImage(of ingredient: String) -> String {
        image(of: ingredient, upgraded: [ingredient])
    }

    /// A cooking tool's picture on the counter.
    static func image(of tool: CookingTool.Kind) -> String {
        switch tool {
        case .grill: "KitchenGrill"
        case .pot: "KitchenPot"
        }
    }

    /// The item's picture while it cooks on `tool`: the whole pot with the
    /// noodles in it, or else as it looks put down anywhere.
    static func image(of item: String, cookingOn tool: CookingTool.Kind, upgraded: Set<String> = []) -> String {
        cookingImages[tool]?[item] ?? placedImage(of: item, upgraded: upgraded)
    }

    /// The item's picture once put down on a station.
    static func placedImage(of item: String, upgraded: Set<String> = []) -> String {
        premium(premiumPlacedImages[item], upgraded) ?? placedImages[item] ?? image(of: item, upgraded: upgraded)
    }

    /// The premium picture, when its ingredient has been upgraded.
    private static func premium(_ art: PremiumArt?, _ upgraded: Set<String>) -> String? {
        art.flatMap { upgraded.contains($0.upgradedBy) ? $0.image : nil }
    }

    // MARK: - Whole-station pictures

    /// How many art points one pixel of `image` covers, when `image` shows a
    /// whole station (glass, pot, bowl) with something in it; nil for a
    /// picture of just the item. Each such picture is cut so its station
    /// sits in the middle, so the scene draws it straight over the station.
    static func wholeStationScale(of image: String) -> CGFloat? {
        wholeStationPictures.first { $0.images.contains(image) }?.artPointsPerPixel
    }

    /// Pictures of the whole glass with something in it, drawn whole even
    /// in a hand (the bowl's and pot's are trimmed to the food there).
    static let glassStateImages: Set<String> = [
        "TentacleGlass", "SlimeGlass", "SlimyTentaclesGlass", "PremiumTentacleGlass", "PremiumSlimyTentaclesGlass",
    ]

    private struct WholeStationPictures {
        let images: Set<String>
        /// The station's width on the counter over its width in the pictures.
        let artPointsPerPixel: CGFloat
    }

    private static let wholeStationPictures = [
        // The new glass state art is drawn at three pixels per art point.
        WholeStationPictures(images: glassStateImages, artPointsPerPixel: 1 / 3),
        // Cut to the pot's box in the design's counter frames, stove and all.
        WholeStationPictures(images: ["PotNoodlesCooking", "PotNoodlesCooked"],
                             artPointsPerPixel: CounterLayout.potSize.width / 528),
        WholeStationPictures(
            images: [
                "NoodlesBoiled", "PremiumNoodlesInBowl", "CoralNoodles", "UrchinNoodles", "ClamNoodles",
                "PremiumCoralNoodles", "PremiumUrchinNoodles", "PremiumClamNoodles",
            ],
            artPointsPerPixel: bowlArtPointsPerPixel
        ),
    ]

    /// The bowl's pictures are cut around it from the design's 1366 × 1024
    /// dish frames, in which the bowl is 589 pixels wide.
    private static let bowlArtPointsPerPixel = CounterLayout.noodleBowlSize.width / 589

    // MARK: - Stations food sits inside

    /// How food sits down inside a station rather than on it: where its
    /// middle goes, and a mask that cuts it off at the station's front rim
    /// so it shows only above it. Offsets are in pixels of the station's
    /// whole pictures, from their middle, y down.
    struct StationInterior {
        let maskImage: String
        let maskCentre: CGVector
        let foodCentre: CGVector
        let artPointsPerPixel: CGFloat
    }

    /// The inside of the station drawn as `stationImage`; nil for a station
    /// food just sits on, such as a plate.
    static func interior(of stationImage: String) -> StationInterior? {
        interiors[stationImage]
    }

    /// The noodle bowl: food sits where the noodles heap up in the dish
    /// pictures and is cut off where the noodles meet the bowl's front, the
    /// mask being the noodle heap's outline carried up to the top.
    private static let interiors = [
        "NoodleBowl": StationInterior(
            maskImage: "NoodleBowlRimMask",
            maskCentre: CGVector(dx: 15, dy: -245.5),
            foodCentre: CGVector(dx: 15, dy: -101.5),
            artPointsPerPixel: bowlArtPointsPerPixel
        ),
    ]

    // MARK: - Names

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
        KitchenMenu.rawNoodles: "NoodlesRaw",
        KitchenMenu.boiledNoodles: "NoodlesBoiled",
        KitchenMenu.coral: "Coral",
        KitchenMenu.urchin: "Urchin",
        KitchenMenu.rawClam: "ClamRaw",
        KitchenMenu.grilledClam: "ClamGrilled",
        KitchenMenu.seaCookie: "SeaCookie",
        KitchenMenu.starfishSugar: "StarfishSugar",
        KitchenMenu.coralNoodles: "CoralNoodles",
        KitchenMenu.urchinNoodles: "UrchinNoodles",
        KitchenMenu.clamNoodles: "ClamNoodles",
        // ponytail: not drawn yet. The ruined noodles and clam borrow the
        // burnt flatbread, and the plain Star Cookie borrows its premium look,
        // the only picture of the finished cookie so far.
        KitchenMenu.mushyNoodles: "FlatbreadBurnt",
        KitchenMenu.burntClam: "FlatbreadBurnt",
        KitchenMenu.starCookie: "PremiumStarCookie",
    ]

    private static let placedImages: [String: String] = [
        KitchenMenu.mushroom: "MushroomTopping",
        KitchenMenu.tentacle: "TentacleGlass",
        KitchenMenu.slime: "SlimeGlass",
    ]

    /// Pictures of a cooking tool with the item cooking in it.
    private static let cookingImages: [CookingTool.Kind: [String: String]] = [
        .pot: [KitchenMenu.rawNoodles: "PotNoodlesCooking", KitchenMenu.boiledNoodles: "PotNoodlesCooked"],
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
        KitchenMenu.rawNoodles: PremiumArt(upgradedBy: KitchenMenu.rawNoodles, image: "PremiumNoodlesRaw"),
        KitchenMenu.boiledNoodles: PremiumArt(upgradedBy: KitchenMenu.rawNoodles, image: "PremiumNoodlesBoiled"),
        KitchenMenu.coral: PremiumArt(upgradedBy: KitchenMenu.coral, image: "PremiumCoral"),
        KitchenMenu.urchin: PremiumArt(upgradedBy: KitchenMenu.urchin, image: "PremiumUrchin"),
        KitchenMenu.rawClam: PremiumArt(upgradedBy: KitchenMenu.rawClam, image: "PremiumClamRaw"),
        KitchenMenu.grilledClam: PremiumArt(upgradedBy: KitchenMenu.rawClam, image: "PremiumClamGrilled"),
        KitchenMenu.seaCookie: PremiumArt(upgradedBy: KitchenMenu.seaCookie, image: "PremiumSeaCookie"),
        KitchenMenu.starfishSugar: PremiumArt(upgradedBy: KitchenMenu.starfishSugar, image: "PremiumStarfishSugar"),
        // The premium noodle dishes glow with the premium noodles.
        KitchenMenu.coralNoodles: PremiumArt(upgradedBy: KitchenMenu.rawNoodles, image: "PremiumCoralNoodles"),
        KitchenMenu.urchinNoodles: PremiumArt(upgradedBy: KitchenMenu.rawNoodles, image: "PremiumUrchinNoodles"),
        KitchenMenu.clamNoodles: PremiumArt(upgradedBy: KitchenMenu.rawNoodles, image: "PremiumClamNoodles"),
        KitchenMenu.starCookie: PremiumArt(upgradedBy: KitchenMenu.seaCookie, image: "PremiumStarCookie"),
    ]

    private static let premiumPlacedImages: [String: PremiumArt] = [
        KitchenMenu.mushroom: PremiumArt(upgradedBy: KitchenMenu.mushroom, image: "PremiumMushroomTopping"),
        KitchenMenu.tentacle: PremiumArt(upgradedBy: KitchenMenu.tentacle, image: "PremiumTentacleGlass"),
        KitchenMenu.boiledNoodles: PremiumArt(upgradedBy: KitchenMenu.rawNoodles, image: "PremiumNoodlesInBowl"),
    ]
}
