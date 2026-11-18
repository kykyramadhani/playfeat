//
//  KitchenItemLookTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//
//  Items that change look once put down, as the assets page draws them, and
//  the premium look an upgraded ingredient gets.
//

import Testing
@testable import PlayFeat

struct KitchenItemLookTests {

    @Test func theMushroomIsWholeInItsBubbleAndChoppedOnThePlate() {
        #expect(KitchenArt.image(of: KitchenMenu.mushroom) == "GlowyMushroom")
        #expect(KitchenArt.placedImage(of: KitchenMenu.mushroom) == "MushroomTopping")
    }

    @Test func thePepperLooksTheSameEverywhere() {
        #expect(KitchenArt.placedImage(of: KitchenMenu.pepper) == KitchenArt.image(of: KitchenMenu.pepper))
    }

    @Test func theFlatbreadHasARawABakedAndABurntLook() {
        let looks = [KitchenMenu.rawFlatbread, KitchenMenu.bakedFlatbread, KitchenMenu.burntFlatbread]
            .map { KitchenArt.image(of: $0) }

        #expect(looks == ["FlatbreadRaw", "FlatbreadBaked", "FlatbreadBurnt"])
    }

    /// In the glass the tentacle shows as the glass before the slime, and the
    /// finished dessert as the glass after it; both are drawn over the glass.
    @Test func whatsInTheGlassIsDrawnAsTheWholeGlass() {
        let tentacle = KitchenArt.placedImage(of: KitchenMenu.tentacle)
        let dessert = KitchenArt.placedImage(of: KitchenMenu.slimyTentacles)

        #expect(tentacle == "TentacleGlass")
        #expect(dessert == "SlimyTentaclesGlass")
        #expect(KitchenArt.glassStateImages.isSuperset(of: [tentacle, dessert]))
    }

    /// Slime poured in first shows as the glass filled with slime.
    @Test func slimeInTheGlassIsTheGlassOfSlime() {
        #expect(KitchenArt.image(of: KitchenMenu.slime) == "Slime")
        #expect(KitchenArt.placedImage(of: KitchenMenu.slime) == "SlimeGlass")
        #expect(KitchenArt.glassStateImages.contains("SlimeGlass"))
    }

    // MARK: - Premium

    /// The flatbread upgrade makes every flatbread look premium, whatever the grill did to it.
    @Test func anUpgradedFlatbreadIsPremiumRawBakedAndBurnt() {
        let looks = [KitchenMenu.rawFlatbread, KitchenMenu.bakedFlatbread, KitchenMenu.burntFlatbread]
            .map { KitchenArt.image(of: $0, upgraded: [KitchenMenu.rawFlatbread]) }

        #expect(looks == ["PremiumFlatbreadRaw", "PremiumFlatbreadBaked", "PremiumFlatbreadBurnt"])
    }

    @Test func anUpgradedMushroomIsPremiumInItsBubbleAndOnThePlate() {
        let upgraded: Set = [KitchenMenu.mushroom]

        #expect(KitchenArt.image(of: KitchenMenu.mushroom, upgraded: upgraded) == "PremiumGlowyMushroom")
        #expect(KitchenArt.placedImage(of: KitchenMenu.mushroom, upgraded: upgraded) == "PremiumMushroomTopping")
    }

    /// Only the upgraded ingredient changes: the pepper stays plain.
    @Test func anotherIngredientsUpgradeLeavesAnItemPlain() {
        #expect(KitchenArt.image(of: KitchenMenu.pepper, upgraded: [KitchenMenu.mushroom]) == "Pepper")
    }

    /// The tentacle upgrade shows in the glass and in the finished dessert.
    @Test func anUpgradedTentacleMakesThePremiumDessert() {
        let upgraded: Set = [KitchenMenu.tentacle]

        #expect(KitchenArt.placedImage(of: KitchenMenu.tentacle, upgraded: upgraded) == "PremiumTentacleGlass")
        #expect(KitchenArt.placedImage(of: KitchenMenu.slimyTentacles, upgraded: upgraded)
            == "PremiumSlimyTentaclesGlass")
    }

    @Test func onlyIngredientsWorthMoreThanTheirBaseValueAreUpgraded() {
        let pricing = DishPricing.unupgraded.upgrading([KitchenMenu.mushroom: 24, KitchenMenu.pepper: 10])

        #expect(pricing.upgradedIngredients == [KitchenMenu.mushroom])
    }
}
