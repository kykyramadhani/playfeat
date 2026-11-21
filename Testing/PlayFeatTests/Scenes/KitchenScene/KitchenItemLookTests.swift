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

    @Test func upgradedSlimeFillsTheGlassWithPremiumSlime() {
        let premium = KitchenArt.placedImage(of: KitchenMenu.slime, upgraded: [KitchenMenu.slime])

        #expect(premium == "PremiumSlimeGlass")
        #expect(KitchenArt.glassStateImages.contains(premium))
    }

    /// Ruined food has its own look, no longer the burnt flatbread's.
    @Test func mushyNoodlesAndABurntClamHaveTheirOwnArt() {
        #expect(KitchenArt.image(of: KitchenMenu.mushyNoodles) == "NoodlesMushy")
        #expect(KitchenArt.image(of: KitchenMenu.burntClam) == "ClamBurnt")
    }

    /// The cookie and its sugar lie at the plate's angle once put down.
    @Test func theSeaCookieLiesAtThePlatesAngle() {
        #expect(KitchenArt.placedImage(of: KitchenMenu.seaCookie) == "SeaCookiePlated")
        #expect(KitchenArt.placedImage(of: KitchenMenu.starfishSugar) == "StarfishSugarTopping")
        #expect(KitchenArt.placedImage(of: KitchenMenu.starCookie) == "StarCookie")
    }

    @Test func anUpgradedSeaCookieIsPremiumOnThePlateAndInTheStarCookie() {
        let upgraded: Set<String> = [KitchenMenu.seaCookie]

        #expect(KitchenArt.placedImage(of: KitchenMenu.seaCookie, upgraded: upgraded) == "PremiumSeaCookiePlated")
        #expect(KitchenArt.placedImage(of: KitchenMenu.starCookie, upgraded: upgraded) == "PremiumStarCookiePlated")
        #expect(KitchenArt.image(of: KitchenMenu.starCookie, upgraded: upgraded) == "PremiumStarCookie")
    }

    /// Premium starfish sugar keeps its premium look on the plate.
    @Test func upgradedStarfishSugarStaysPremiumOnThePlate() {
        let upgraded: Set<String> = [KitchenMenu.starfishSugar]

        #expect(KitchenArt.placedImage(of: KitchenMenu.starfishSugar, upgraded: upgraded) == "PremiumStarfishSugar")
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

    // MARK: - Planet 2

    /// Noodles boil in the pot: drawn as the whole pot with them in it,
    /// first cooking, then cooked.
    @Test func noodlesInThePotAreDrawnAsTheWholePot() {
        let cooking = KitchenArt.image(of: KitchenMenu.rawNoodles, cookingOn: .pot)
        let cooked = KitchenArt.image(of: KitchenMenu.boiledNoodles, cookingOn: .pot)

        #expect(cooking == "PotNoodlesCooking")
        #expect(cooked == "PotNoodlesCooked")
        #expect(KitchenArt.wholeStationScale(of: cooking) != nil)
    }

    @Test func theClamLooksTheSameOnTheGrillAsAnywhere() {
        let onTheGrill = KitchenArt.image(of: KitchenMenu.rawClam, cookingOn: .grill)

        #expect(onTheGrill == KitchenArt.image(of: KitchenMenu.rawClam))
    }

    /// Each noodle dish is drawn as the whole bowl; a topping alone is just itself.
    @Test(arguments: [KitchenMenu.coralNoodles, KitchenMenu.urchinNoodles, KitchenMenu.clamNoodles])
    func aNoodleDishIsDrawnAsTheWholeBowl(dish: String) {
        #expect(KitchenArt.wholeStationScale(of: KitchenArt.placedImage(of: dish)) != nil)
    }

    @Test func aToppingOnTheBowlIsJustItself() {
        let urchin = KitchenArt.placedImage(of: KitchenMenu.urchin)

        #expect(urchin == KitchenArt.image(of: KitchenMenu.urchin))
        #expect(KitchenArt.wholeStationScale(of: urchin) == nil)
    }

    /// Premium noodles glow in the bowl, and so does every dish made with them.
    @Test func premiumNoodlesGlowInTheBowlAndInTheirDishes() {
        let upgraded: Set<String> = [KitchenMenu.rawNoodles]

        #expect(KitchenArt.placedImage(of: KitchenMenu.boiledNoodles, upgraded: upgraded) == "PremiumNoodlesInBowl")
        #expect(KitchenArt.image(of: KitchenMenu.clamNoodles, upgraded: upgraded) == "PremiumClamNoodles")
    }
}
