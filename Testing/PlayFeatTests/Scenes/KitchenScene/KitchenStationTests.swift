//
//  KitchenStationTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  Letting items go over the grill, plate and glass: what each takes, the
//  grill cooking, and a finished recipe turning into one dish. Driven through
//  `settle` and `updateGrill`, so no camera or hands are needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenStationTests {

    private typealias Menu = KitchenMenu

    private func makeScene() throws -> KitchenScene {
        let scene = KitchenScene(size: KitchenLayout.artSize)
        var generator = SeededGenerator(state: 1)
        let day = KitchenDay(level: try LevelLoader.load("1-4"), seatCount: 2, using: &generator)
        scene.prepare(for: day, pantry: Planet.kepler186f.pantry)
        return scene
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
        let scene = try makeScene()

        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        #expect(flatbread.placement == .grill)
        #expect(flatbread.fallingSince == nil)
    }

    @Test func theGrillBakesThenWarnsThenBurns() throws {
        let scene = try makeScene()
        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        scene.updateGrill(now: 6)
        #expect(flatbread.ingredient == Menu.bakedFlatbread)

        scene.updateGrill(now: 12)
        #expect(flatbread.ingredient == Menu.burntFlatbread)
    }

    @Test func aPepperLetGoOverTheGrillFalls() throws {
        let scene = try makeScene()

        let pepper = letGo(Menu.pepper, over: KitchenLayout.grill, in: scene)

        #expect(pepper.placement == nil)
        #expect(pepper.fallingSince != nil)
    }

    @Test func takingTheFlatbreadOffFreesTheGrill() throws {
        let scene = try makeScene()
        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.grill, in: scene)

        scene.unpark(flatbread)

        #expect(scene.grill.isEmpty)
        #expect(flatbread.placement == nil)
    }

    // MARK: - Plate

    @Test func breadAndPepperOnThePlateBecomeOneDish() throws {
        let scene = try makeScene()

        letGo(Menu.bakedFlatbread, over: KitchenLayout.plate, in: scene)
        letGo(Menu.pepper, over: KitchenLayout.plate, in: scene)

        #expect(items(on: .plate, in: scene) == [Menu.pepperFlatbread])
    }

    @Test func rawFlatbreadLetGoOverThePlateFalls() throws {
        let scene = try makeScene()

        let flatbread = letGo(Menu.rawFlatbread, over: KitchenLayout.plate, in: scene)

        #expect(flatbread.fallingSince != nil)
    }

    @Test func liftingTheDishOffEmptiesThePlate() throws {
        let scene = try makeScene()
        letGo(Menu.bakedFlatbread, over: KitchenLayout.plate, in: scene)
        letGo(Menu.mushroom, over: KitchenLayout.plate, in: scene)
        let dish = try #require(scene.bubbles.first { $0.placement == .plate })

        scene.unpark(dish)

        #expect(scene.plate.contents.isEmpty)
    }

    // MARK: - Glass

    @Test func slimeAndTentacleInTheGlassBecomeTheSorbet() throws {
        let scene = try makeScene()

        letGo(Menu.slime, over: KitchenLayout.glass, in: scene)
        letGo(Menu.tentacle, over: KitchenLayout.glass, in: scene)

        #expect(items(on: .glass, in: scene) == [Menu.sunsetSorbet])
    }

    /// The glass overlaps the first storage box; a drink ingredient goes in
    /// the glass, anything else in the box.
    @Test func aPepperLetGoOverTheGlassIsNotPutInIt() throws {
        let scene = try makeScene()

        let pepper = letGo(Menu.pepper, over: KitchenLayout.glass, in: scene)

        #expect(pepper.placement != .glass)
    }
}
