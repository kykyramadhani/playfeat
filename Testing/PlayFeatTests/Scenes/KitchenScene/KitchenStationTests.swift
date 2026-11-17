//
//  KitchenStationTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  Letting items go over the grill, plate and glass, by the prototype's
//  rules: what each takes, what a refused item does, the grill cooking and
//  swapping flatbreads, and a finished recipe turning into one dish.
//  Driven through `settle` and `updateGrill`, so no camera or hands are needed.
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

        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        #expect(flatbread.placement == .grill(0))
        #expect(flatbread.fallingSince == nil)
    }

    /// Bakes at 6 s, glows 8 s after that, burns 12 s after that.
    @Test func theGrillBakesThenGlowsThenBurns() throws {
        let (scene, _) = try makeScene()
        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        scene.updateGrill(now: 6)
        #expect(flatbread.ingredient == Menu.bakedFlatbread)

        scene.updateGrill(now: 14)
        #expect(scene.grill.doneness(onSlot: 0, at: 14) == .overcooking)

        scene.updateGrill(now: 18)
        #expect(flatbread.ingredient == Menu.burntFlatbread)
    }

    @Test func aFlatbreadOnATakenSlotKnocksTheOldOneOff() throws {
        let (scene, _) = try makeScene()
        let first = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        let second = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        #expect(second.placement == .grill(0))
        #expect(first.placement == nil)
        #expect(first.fallingSince != nil)
    }

    /// A refused item hangs where it was let go for a moment, then falls.
    @Test func aPepperLetGoOverTheGrillIsRefused() throws {
        let (scene, day) = try makeScene()

        let pepper = letGo(Menu.pepper, over: KitchenLayout.grill, in: scene)

        #expect(pepper.placement == nil)
        #expect(pepper.isRefused(at: day.elapsed))
        #expect(!pepper.isRefused(at: day.elapsed + KitchenRules.refuseHoldSec))
    }

    @Test func takingTheFlatbreadOffFreesTheGrill() throws {
        let (scene, _) = try makeScene()
        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        scene.unpark(flatbread)

        #expect(!scene.grill.isTaken(0))
        #expect(flatbread.placement == nil)
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

        letGo(Menu.slime, over: scene.artRect(of: .glass(0)), in: scene)
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

    /// The second plate goes in on the far left, so a dish already on the
    /// first plate counts one further along.
    @Test func aSecondPlateKeepsWhatIsOnTheFirst() throws {
        let (scene, day) = try makeScene()
        let pepper = letGo(Menu.pepper, over: scene.artRect(of: .plate(0)), in: scene)

        day.tools = KitchenTools(plates: 2, glasses: 1)
        scene.syncTools()

        #expect(scene.plates.count == 2)
        #expect(pepper.placement == .plate(1))
        #expect(scene.plates[1].contents == [Menu.pepper])
    }
}

// MARK: - Size on the counter

extension KitchenStationTests {

    /// Food on the grill and plate is drawn big enough to fill the grill's
    /// hot ring; what's in a glass is drawn as the whole glass, already at its size.
    @Test func foodOnTheGrillAndPlateIsDrawnToFillTheCookware() {
        let onCookware = KitchenScene.placedScale(on: .grill(0)) * KitchenScene.bubbleArtRadius * 2
            * KitchenBubbleNode.foodFill

        #expect(abs(onCookware - KitchenScene.cookwareFoodWidth) < 0.001)
        #expect(KitchenScene.placedScale(on: .plate(0)) == KitchenScene.placedScale(on: .grill(0)))
        #expect(KitchenScene.placedScale(on: .glass(0)) == 1)
    }
}
