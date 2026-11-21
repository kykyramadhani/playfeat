//
//  ArtAssetTests.swift
//  PlayFeatTests
//
//  Split out of GetCookingTests.swift (created by Kyky on 11/08/26).
//

import Testing
import Foundation
import CoreGraphics
import SpriteKit
import UIKit
@testable import PlayFeat

@MainActor
struct ArtAssetTests {

    /// Every ingredient plus the bubble and plate must resolve to a real image.
    /// This is the test that fires when art is renamed or dropped into the
    /// wrong catalog — otherwise the only symptom is an empty bubble on screen.
    @Test func everyReferencedAssetExists() {
        for ingredient in Ingredient.allCases {
            #expect(TrimmedArt.image(named: ingredient.imageName) != nil,
                    "missing art '\(ingredient.imageName)' for \(ingredient.displayName)")
        }

        // Catalog lookups are case-sensitive even though the filesystem the
        // assets are authored on is not, which is how `salad` shipped as
        // "Salad" and left the finished dish invisible.
        for recipe in Recipe.all {
            #expect(TrimmedArt.image(named: recipe.finishedDishImageName) != nil,
                    "missing finished-dish art '\(recipe.finishedDishImageName)' for \(recipe.name)")
        }

        #expect(TrimmedArt.image(named: GameArt.bubble) != nil)
        #expect(TrimmedArt.image(named: GameArt.plate) != nil)
    }

    /// The serving station's two pieces. `BellNode` builds them by name, and a
    /// missing one leaves the player carrying the plate at empty space with no
    /// other symptom.
    @Test func theServingStationArtExists() {
        #expect(UIImage(named: "Tray") != nil)
        #expect(UIImage(named: "RingingBell") != nil)
    }

    @Test func countdownArtworkPreservesItsDesignCanvas() throws {
        for step in GetReadyOverlay.Step.allCases {
            let image = try #require(UIImage(named: step.rawValue))
            #expect(image.size == DesignCanvas.size)
        }
    }

    /// The marathon HUD's coin and lost-customer cross, and its colours.
    /// Referenced by name, so a rename leaves an empty plaque.
    @Test(arguments: ["MarathonCoinIcon", "LostCustomerCross"])
    func theMarathonHUDArtExists(name: String) {
        #expect(UIImage(named: name) != nil, "missing marathon HUD art '\(name)'")
    }

    @Test(arguments: ["LostCustomerMark", "LostCustomerMarkSpare", "BuffetProgressTrack", "WarningRed"])
    func theMarathonHUDColoursExist(name: String) {
        #expect(UIColor(named: name) != nil, "missing marathon HUD colour '\(name)'")
    }

    /// The served-dish count's icon. Referenced by name from `PointCard`, so a
    /// rename leaves the badge showing a bare number with no other symptom.
    @Test func theServedDishIconExists() {
        #expect(UIImage(named: "ServedDish") != nil)
    }

    /// The planet kitchen draws every item by name, in a bubble and once put
    /// down, plain and upgraded; a missing picture is an empty bubble, sheet
    /// or station.
    @Test(arguments: [
        KitchenMenu.rawFlatbread, KitchenMenu.bakedFlatbread, KitchenMenu.burntFlatbread,
        KitchenMenu.pepper, KitchenMenu.mushroom, KitchenMenu.slime, KitchenMenu.tentacle,
        KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread, KitchenMenu.slimyTentacles,
        KitchenMenu.rawNoodles, KitchenMenu.boiledNoodles, KitchenMenu.mushyNoodles,
        KitchenMenu.coral, KitchenMenu.urchin, KitchenMenu.rawClam, KitchenMenu.grilledClam, KitchenMenu.burntClam,
        KitchenMenu.seaCookie, KitchenMenu.starfishSugar,
        KitchenMenu.coralNoodles, KitchenMenu.urchinNoodles, KitchenMenu.clamNoodles, KitchenMenu.starCookie,
    ])
    func everyKitchenItemHasArt(item: String) {
        let everythingUpgraded = Set(DishPricing.baseValues.keys)
        let cooking = CookingTool.Kind.allCases.flatMap { tool in
            [
                KitchenArt.image(of: item, cookingOn: tool),
                KitchenArt.image(of: item, cookingOn: tool, upgraded: everythingUpgraded),
            ]
        }
        let names = [
            KitchenArt.image(of: item), KitchenArt.placedImage(of: item),
            KitchenArt.image(of: item, upgraded: everythingUpgraded),
            KitchenArt.placedImage(of: item, upgraded: everythingUpgraded),
        ] + cooking
        for name in names {
            #expect(UIImage(named: name) != nil, "missing kitchen art '\(name)' for '\(item)'")
        }
    }

    /// Each planet's counter draws its cooking tools and stations by name; a
    /// missing one is a hole in the counter.
    @Test(arguments: PlanetCatalog.all.map(\.id))
    func everyCounterPictureExists(planet: Planet.ID) {
        let counter = PlanetCatalog.planet(planet).kitchen.counter
        let stations = [counter.mainStationImage, counter.dessertStationImage]
        let rimMasks = stations.compactMap { KitchenArt.interior(of: $0)?.maskImage }
        let names = stations + rimMasks + counter.tools.map(KitchenArt.image(of:))
        for name in names {
            #expect(UIImage(named: name) != nil, "missing counter art '\(name)' on \(planet)")
        }
    }

    /// Pictures of the pot or the bowl with food in it are drawn straight
    /// over the counter's, so each family is cut to one frame: the pot's to
    /// the empty pot's own, the bowl's to one around the bowl. A picture cut
    /// differently would jump off its station.
    @Test(arguments: [
        ["KitchenPot", "PotNoodlesCooking", "PotNoodlesCooked"],
        [
            "NoodlesBoiled", "PremiumNoodlesInBowl", "CoralNoodles", "UrchinNoodles", "ClamNoodles",
            "PremiumCoralNoodles", "PremiumUrchinNoodles", "PremiumClamNoodles",
        ],
    ])
    func wholeStationPicturesShareOneFrame(names: [String]) {
        let sizes = Set(names.compactMap { UIImage(named: $0).map { "\($0.size)" } })

        #expect(sizes.count == 1, "frames differ: \(sizes)")
    }

    /// Every alien in every mood is drawn by name as patience runs out; a
    /// missing one is an empty seat.
    @Test(arguments: AlienSpecies.allCases)
    func everyAlienMoodExists(species: AlienSpecies) {
        for zone in [KitchenRules.PatienceZone.green, .yellow, .red] {
            #expect(UIImage(named: species.imageName(in: zone)) != nil, "missing '\(species.imageName(in: zone))'")
        }
    }

    /// Every alien picture is on one canvas with its moods lined up, so a
    /// customer doesn't jump in their seat when their mood changes. A new
    /// picture cropped differently would bring the jump back.
    @Test func everyAlienPictureSharesOneCanvas() {
        let names = AlienSpecies.allCases.flatMap { species in
            [KitchenRules.PatienceZone.green, .yellow, .red].map(species.imageName(in:))
        }
        let sizes = Set(names.compactMap { UIImage(named: $0).map { "\($0.size)" } })

        #expect(sizes.count == 1, "alien canvases differ: \(sizes)")
    }

    /// Each planet's landscape layers and galaxy-map picture are named in its
    /// definition; a missing one leaves a hole in the landscape.
    @Test(arguments: PlanetCatalog.all.map(\.id))
    func everyPlanetBackdropLayerExists(planet: Planet.ID) {
        let backdrop = PlanetCatalog.planet(planet).backdrop
        for layer in backdrop.layers {
            #expect(UIImage(named: layer.imageName) != nil, "missing layer '\(layer.imageName)' on \(planet)")
        }
        #expect(UIImage(named: backdrop.galaxyImageName) != nil)
    }

    /// The kitchen's truck is drawn as layers cut into bands on the art's own
    /// 1366×1024 grid; a missing or re-cropped layer leaves a hole in the
    /// walls or a counter out of line with the props on it.
    @Test(arguments: ["TruckWall", "TruckCounter", "TruckChains"])
    func everyTruckLayerExistsOnTheArtsCanvas(layer: String) throws {
        let image = try #require(UIImage(named: layer), "missing truck layer '\(layer)'")

        #expect(image.size.width / image.size.height == KitchenLayout.artSize.width / KitchenLayout.artSize.height)
    }

    /// The galaxy map draws every planet at one size, so their pictures must
    /// share one canvas; a planet cropped tighter would look bigger.
    @Test func everyGalaxyPlanetSharesOneCanvas() {
        let sizes = Set(PlanetCatalog.all.compactMap { planet in
            UIImage(named: planet.backdrop.galaxyImageName).map { "\($0.size)" }
        })

        #expect(sizes.count == 1, "galaxy planet canvases differ: \(sizes)")
    }

    /// Every picture of a filled glass shares one canvas centred on the
    /// counter glass, so it lies exactly over the empty glass it stands on.
    @Test func everyFilledGlassSharesTheCounterGlassCanvas() {
        let sizes = Set(KitchenArt.glassStateImages.compactMap { UIImage(named: $0)?.size }.map { "\($0)" })
        #expect(sizes.count == 1)
    }

    /// The source art sits on 1920×1080 canvases with the subject filling as
    /// little as 28% of the width. If trimming regresses, every bubble silently
    /// renders a fraction of its intended size.
    @Test func trimmingRemovesCanvasPadding() {
        for ingredient in Ingredient.allCases {
            guard let image = TrimmedArt.image(named: ingredient.imageName) else { continue }
            #expect(image.size.width < 1900,
                    "\(ingredient.imageName) still \(image.size.width)pt wide — padding not trimmed")
        }
    }

    /// The bubble is drawn round, so its trimmed art must be close to square —
    /// a lopsided result means the crop picked up stray pixels.
    @Test func trimmedBubbleIsSquare() throws {
        let bubble = try #require(TrimmedArt.image(named: GameArt.bubble))
        let ratio = bubble.size.width / bubble.size.height
        #expect(abs(ratio - 1) < 0.1, "bubble aspect \(ratio) is not square")
    }

    /// Repeated lookups must hand back the identical cached instance; the trim
    /// scans pixels and would otherwise rerun for every bubble spawned.
    @Test func repeatedLookupsAreCached() throws {
        let first = try #require(TrimmedArt.image(named: GameArt.bubble))
        let second = try #require(TrimmedArt.image(named: GameArt.bubble))
        #expect(first === second)
    }
}
