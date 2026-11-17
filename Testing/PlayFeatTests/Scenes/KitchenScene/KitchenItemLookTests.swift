//
//  KitchenItemLookTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//
//  Items that change look once put down, as the assets page draws them.
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
            .map(KitchenArt.image(of:))

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
}
