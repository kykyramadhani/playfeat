//
//  KitchenStationTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  Letting items go over the grill, plate and glass, by the prototype's
//  rules: what each takes, what a refused item does, the grill cooking and
//  swapping flatbreads, and a finished recipe turning into one dish.
//  Driven through `settle` and `updateCookers`, so no camera or hands are needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenStationTests {

    private typealias Menu = KitchenMenu

    private func makeScene() throws -> (scene: KitchenScene, day: KitchenDay) {
        makeKitchenScene(level: try LevelLoader.load("1-4"))
    }

    @discardableResult
    private func letGo(_ item: String, over station: CGRect, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: item, radius: scene.bubbleRadius)
        node.position = scene.layout.sceneRect(station).center
        scene.addChild(node)
        scene.bubbles.append(node)
        scene.settle(node)
        return node
    }

    private func items(on placement: KitchenBubbleNode.Placement, in scene: KitchenScene) -> [String] {
        scene.bubbles.filter { $0.placement == placement }.map(\.ingredient)
    }

    // MARK: - Grill

    @Test func aRawFlatbreadLetGoOverTheGrillGoesOnIt() throws {
        let (scene, _) = try makeScene()

        let flatbread = letGo(Menu.rawFlatbread, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)

        #expect(flatbread.placement == .cooker(.grill, slot: 0))
        #expect(flatbread.fallingSince == nil)
    }

    /// Bakes at 6 s, glows 8 s after that, burns 12 s after that.
    @Test func theGrillBakesThenGlowsThenBurns() throws {
        let (scene, _) = try makeScene()
        let flatbread = letGo(Menu.rawFlatbread, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)

        scene.updateCookers(now: 6)
        #expect(flatbread.ingredient == Menu.bakedFlatbread)

        scene.updateCookers(now: 14)
        #expect(scene.cookers[.grill]?.doneness(onSlot: 0, at: 14) == .overcooking)

        scene.updateCookers(now: 18)
        #expect(flatbread.ingredient == Menu.burntFlatbread)
    }

    @Test func aFlatbreadOnATakenSlotKnocksTheOldOneOff() throws {
        let (scene, _) = try makeScene()
        let first = letGo(Menu.rawFlatbread, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)

        let second = letGo(Menu.rawFlatbread, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)

        #expect(second.placement == .cooker(.grill, slot: 0))
        #expect(first.placement == nil)
        #expect(first.fallingSince != nil)
    }

    /// A refused item hangs where it was let go for a moment, then falls.
    @Test func aPepperLetGoOverTheGrillIsRefused() throws {
        let (scene, day) = try makeScene()

        let pepper = letGo(Menu.pepper, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)

        #expect(pepper.placement == nil)
        #expect(pepper.isRefused(at: day.elapsed))
        #expect(!pepper.isRefused(at: day.elapsed + KitchenRules.refuseHoldSec))
    }

    @Test func takingTheFlatbreadOffFreesTheGrill() throws {
        let (scene, _) = try makeScene()
        let flatbread = letGo(Menu.rawFlatbread, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)

        scene.unpark(flatbread)

        #expect(scene.cookers[.grill]?.isTaken(0) == false)
        #expect(flatbread.placement == nil)
    }

    /// Taken off half-baked and put back, a flatbread finishes baking in the
    /// time it had left rather than starting over.
    @Test func aHalfBakedFlatbreadPutBackFinishesFromWhereItWas() throws {
        let (scene, day) = try makeScene()
        day.start()
        day.tick(at: 0)
        let flatbread = letGo(Menu.rawFlatbread, over: scene.artRect(of: .cooker(.grill, slot: 0)), in: scene)
        // Frame by frame: the day's clock credits at most a short step per tick.
        for frame in 1...40 { day.tick(at: Double(frame) * 0.1) }
        scene.unpark(flatbread)

        flatbread.position = scene.layout.sceneRect(scene.artRect(of: .cooker(.grill, slot: 0))).center
        scene.settle(flatbread)
        scene.updateCookers(now: day.elapsed + 2)

        #expect(flatbread.ingredient == Menu.bakedFlatbread)
    }

    // MARK: - Plate

    @Test func breadAndPepperOnThePlateBecomeOneDish() throws {
        let (scene, _) = try makeScene()

        letGo(Menu.bakedFlatbread, over: scene.artRect(of: .plate(0)), in: scene)
        letGo(Menu.pepper, over: scene.artRect(of: .plate(0)), in: scene)

        #expect(items(on: .plate(0), in: scene) == [Menu.pepperFlatbread])
    }

    @Test func theToppingCanGoOnThePlateFirst() throws {
        let (scene, _) = try makeScene()

        letGo(Menu.mushroom, over: scene.artRect(of: .plate(0)), in: scene)
        letGo(Menu.bakedFlatbread, over: scene.artRect(of: .plate(0)), in: scene)

        #expect(items(on: .plate(0), in: scene) == [Menu.mushroomFlatbread])
    }

    /// As in the prototype, a raw flatbread may sit on an empty plate.
    @Test func aRawFlatbreadCanSitOnAnEmptyPlate() throws {
        let (scene, _) = try makeScene()

        let flatbread = letGo(Menu.rawFlatbread, over: scene.artRect(of: .plate(0)), in: scene)

        #expect(flatbread.placement == .plate(0))
    }

    @Test func liftingTheDishOffEmptiesThePlate() throws {
        let (scene, _) = try makeScene()
        letGo(Menu.bakedFlatbread, over: scene.artRect(of: .plate(0)), in: scene)
        letGo(Menu.mushroom, over: scene.artRect(of: .plate(0)), in: scene)
        let dish = try #require(scene.bubbles.first { $0.placement == .plate(0) })

        scene.unpark(dish)

        #expect(scene.plates[0].contents.isEmpty)
    }

    // MARK: - Glass

    @Test func aTentacleThenSlimeInTheGlassBecomeTheSlimyTentacles() throws {
        let (scene, _) = try makeScene()

        letGo(Menu.tentacle, over: scene.artRect(of: .glass(0)), in: scene)
        letGo(Menu.slime, over: scene.artRect(of: .glass(0)), in: scene)

        #expect(items(on: .glass(0), in: scene) == [Menu.slimyTentacles])
    }

    @Test func slimeFirstThenTheTentacleMakeTheDessertToo() throws {
        let (scene, _) = try makeScene()

        let slime = letGo(Menu.slime, over: scene.artRect(of: .glass(0)), in: scene)
        #expect(slime.placement == .glass(0))
        #expect(slime.isDrawnAsWholeStation)
        #expect(items(on: .glass(0), in: scene) == [Menu.slime])

        letGo(Menu.tentacle, over: scene.artRect(of: .glass(0)), in: scene)

        #expect(items(on: .glass(0), in: scene) == [Menu.slimyTentacles])
    }

    @Test func aPepperLetGoOverTheGlassIsRefused() throws {
        let (scene, day) = try makeScene()

        let pepper = letGo(Menu.pepper, over: scene.artRect(of: .glass(0)), in: scene)

        #expect(pepper.placement != .glass(0))
        #expect(pepper.isRefused(at: day.elapsed))
    }

    // MARK: - A plate added mid-run

    /// The second plate goes in on its own spot, so what is on the first
    /// stays there.
    @Test func aSecondPlateKeepsWhatIsOnTheFirst() throws {
        let (scene, day) = try makeScene()
        let firstPlate = scene.artRect(of: .plate(0))
        let pepper = letGo(Menu.pepper, over: firstPlate, in: scene)

        day.tools = KitchenTools(plates: 2, glasses: 1)
        scene.syncTools()

        #expect(scene.plates.count == 2)
        #expect(pepper.placement == .plate(0))
        #expect(scene.plates[0].contents == [Menu.pepper])
        #expect(scene.artRect(of: .plate(0)) == firstPlate)
    }

    // MARK: - A dish let go away from the customers

    /// Mid-air, clear of every station and serve area.
    private static let midAir = CGPoint(x: 683, y: 400)

    /// Makes a mushroom flatbread on the first plate and lifts it off, as a
    /// hand picking it up would.
    private func liftedDish(in scene: KitchenScene) throws -> KitchenBubbleNode {
        letGo(Menu.bakedFlatbread, over: scene.artRect(of: .plate(0)), in: scene)
        letGo(Menu.mushroom, over: scene.artRect(of: .plate(0)), in: scene)
        let dish = try #require(scene.bubbles.first { $0.placement == .plate(0) })
        dish.liftedFrom = dish.placement
        scene.unpark(dish)
        dish.position = scene.layout.scenePoint(Self.midAir)
        return dish
    }

    /// A finished dish takes a while to make, so a missed release doesn't
    /// lose it.
    @Test func aDishLetGoInMidAirGoesBackToItsPlate() throws {
        let (scene, _) = try makeScene()
        let dish = try liftedDish(in: scene)

        scene.settle(dish)

        #expect(dish.placement == .plate(0))
        #expect(dish.fallingSince == nil)
        #expect(scene.plates[0].contents == [Menu.mushroomFlatbread])
    }

    @Test func aDishLetGoOverTheGrillGoesBackToItsPlate() throws {
        let (scene, _) = try makeScene()
        let dish = try liftedDish(in: scene)
        dish.position = scene.layout.sceneRect(scene.artRect(of: .cooker(.grill, slot: 0))).center

        scene.settle(dish)

        #expect(dish.placement == .plate(0))
    }

    /// Its own plate has been used since, so it goes to another that takes it.
    @Test func aDishWhosePlateIsTakenGoesToAnotherPlate() throws {
        let (scene, day) = try makeScene()
        day.tools = KitchenTools(plates: 2, glasses: 1)
        scene.syncTools()
        let dish = try liftedDish(in: scene)
        letGo(Menu.pepper, over: scene.artRect(of: .plate(0)), in: scene)

        scene.settle(dish)

        #expect(dish.placement == .plate(1))
    }

    @Test func aDishWithNoFreePlateFalls() throws {
        let (scene, _) = try makeScene()
        let dish = try liftedDish(in: scene)
        letGo(Menu.pepper, over: scene.artRect(of: .plate(0)), in: scene)

        scene.settle(dish)

        #expect(dish.placement == nil)
        #expect(dish.fallingSince != nil)
    }

    /// Only finished dishes go back: an ingredient off the plate still falls.
    @Test func anIngredientLetGoInMidAirStillFalls() throws {
        let (scene, _) = try makeScene()
        let pepper = letGo(Menu.pepper, over: scene.artRect(of: .plate(0)), in: scene)
        pepper.liftedFrom = pepper.placement
        scene.unpark(pepper)
        pepper.position = scene.layout.scenePoint(Self.midAir)

        scene.settle(pepper)

        #expect(pepper.placement == nil)
        #expect(pepper.fallingSince != nil)
    }
}

// MARK: - Size on the counter

extension KitchenStationTests {

    /// Food on the grill and plate is drawn big enough to fill the grill's
    /// hot ring.
    @Test func foodOnTheCookwareIsDrawnToFillIt() {
        let onCookware = KitchenScene.cookwareFoodScale * KitchenScene.bubbleArtRadius * 2 * KitchenBubbleNode.foodFill

        #expect(abs(onCookware - KitchenScene.cookwareFoodWidth) < 0.001)
    }

    @Test func foodPutOnAPlateGrowsToFillIt() {
        let pepper = KitchenBubbleNode(ingredient: Menu.pepper, radius: KitchenScene.bubbleArtRadius)
        pepper.placement = .plate(0)

        #expect(pepper.placedScale == KitchenScene.cookwareFoodScale)
    }

    /// What's in a glass is drawn as the whole glass, already at its size.
    @Test func whatsInAGlassIsAlreadyItsSize() {
        let tentacle = KitchenBubbleNode(ingredient: Menu.tentacle, radius: KitchenScene.bubbleArtRadius)
        tentacle.placement = .glass(0)

        #expect(tentacle.isDrawnAsWholeStation)
        #expect(tentacle.placedScale == 1)
    }
}

// MARK: - Planet 2

extension KitchenStationTests {

    /// Planet 2's counter has spots for two bowls but one cookie plate, so a
    /// player owning two of each gets two bowls and one cookie plate.
    @Test func planetTwoSetsOutTwoBowlsButOneCookiePlate() throws {
        let (scene, _) = makeKitchenScene(level: try LevelLoader.load("2-4"), ownedPlates: 2, ownedGlasses: 2)

        #expect(scene.plates.count == 2)
        #expect(scene.glasses.count == 1)
    }

    /// A topping put in the bowl sits down inside it, cut off at the rim;
    /// on Planet 1's plate food just sits on top.
    @Test func aToppingInTheBowlSitsInsideIt() throws {
        let (scene, _) = makeKitchenScene(level: try LevelLoader.load("2-1"))

        let coral = letGo(Menu.coral, over: scene.artRect(of: .plate(0)), in: scene)

        #expect(coral.placement == .plate(0))
        #expect(coral.interior?.maskImage == "NoodleBowlRimMask")
    }

    @Test func foodOnAPlateSitsOnTop() throws {
        let (scene, _) = try makeScene()

        let pepper = letGo(Menu.pepper, over: scene.artRect(of: .plate(0)), in: scene)

        #expect(pepper.placement == .plate(0))
        #expect(pepper.interior == nil)
    }

    @Test func aToppingLiftedOutOfTheBowlIsWholeAgain() throws {
        let (scene, _) = makeKitchenScene(level: try LevelLoader.load("2-1"))
        let coral = letGo(Menu.coral, over: scene.artRect(of: .plate(0)), in: scene)

        scene.unpark(coral)

        #expect(coral.interior == nil)
    }

    @Test func noodlesLetGoOverThePotBoilThereDrawnAsTheWholePot() throws {
        let (scene, _) = makeKitchenScene(level: try LevelLoader.load("2-1"))

        let noodles = letGo(Menu.rawNoodles, over: scene.artRect(of: .cooker(.pot, slot: 0)), in: scene)

        #expect(noodles.placement == .cooker(.pot, slot: 0))
        #expect(noodles.isDrawnAsWholeStation)
        #expect(noodles.placedScale == 1)
    }

    /// Let go from the hand, still drawn bigger, the whole-pot picture lands
    /// at the pot's own size straight away instead of shrinking into it.
    @Test func noodlesLetGoOverThePotLandAtThePotsSizeAtOnce() throws {
        let (scene, _) = makeKitchenScene(level: try LevelLoader.load("2-1"))
        let pot = scene.artRect(of: .cooker(.pot, slot: 0))
        let noodles = KitchenBubbleNode(ingredient: Menu.rawNoodles, radius: scene.bubbleRadius)
        noodles.setScale(KitchenScene.heldScale)
        noodles.position = scene.layout.sceneRect(pot).center
        scene.addChild(noodles)
        scene.bubbles.append(noodles)

        scene.settle(noodles)

        #expect(noodles.xScale == 1)
        #expect(!noodles.hasActions())
    }

    @Test func aNoodleDishMadeInTheBowlIsDrawnAsTheWholeBowl() throws {
        let (scene, _) = makeKitchenScene(level: try LevelLoader.load("2-1"))
        let bowl = scene.artRect(of: .plate(0))

        letGo(Menu.boiledNoodles, over: bowl, in: scene)
        letGo(Menu.coral, over: bowl, in: scene)
        let dish = try #require(scene.bubbles.first { $0.ingredient == Menu.coralNoodles })

        #expect(dish.isDrawnAsWholeStation)
        #expect(dish.xScale == 1)
    }
}
