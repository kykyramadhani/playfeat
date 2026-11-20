//
//  KitchenSceneTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//
//  Where a let-go ingredient ends up: a station, behind the table, or falling
//  from mid-air. Driven straight through `settle`, so no camera or hands are
//  needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenSceneTests {

    private func makeScene(ownedPlates: Int = 1) -> KitchenScene {
        makeKitchenScene(ownedPlates: ownedPlates).scene
    }

    /// The scene holds its day weakly, so the test keeps the day alive too.
    private func makeFlippedGravityKitchen() -> (scene: KitchenScene, day: KitchenDay) {
        makeKitchenScene(level: makeLevel(gravity: .up))
    }

    private func letGo(_ ingredient: String, atArtPoint point: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: ingredient, radius: 80)
        node.position = scene.layout.scenePoint(point)
        scene.addChild(node)
        scene.bubbles.append(node)
        scene.settle(node)
        return node
    }

    /// There is no bin: an unwanted item let go over the bare table goes
    /// behind it and is thrown away.
    @Test func anItemLetGoOverTheBareTableIsThrownAway() {
        let scene = makeScene()

        _ = letGo("emberPepper", atArtPoint: CGPoint(x: 1200, y: 950), in: scene)

        #expect(scene.bubbles.isEmpty)
    }

    /// With two plates, an item goes on the one it was let go over.
    @Test func withTwoPlatesAnItemGoesOnTheOneItWasLetGoOver() {
        let scene = makeScene(ownedPlates: 2)

        let node = letGo(KitchenMenu.bakedFlatbread, atArtPoint: scene.artRect(of: .plate(0)).center, in: scene)

        #expect(node.placement == .plate(0))
        #expect(scene.plates[0].contents == [KitchenMenu.bakedFlatbread])
        #expect(scene.plates[1].contents.isEmpty)
    }

    /// It falls behind the table, which hides it bit by bit.
    @Test func anItemLetGoInMidAirFallsBehindTheTable() {
        let scene = makeScene()

        let node = letGo("duskMushroom", atArtPoint: CGPoint(x: 683, y: 400), in: scene)

        #expect(node.fallingSince != nil)
        #expect(node.parent === scene.behindTable)
        #expect(scene.bubbles.contains { $0 === node })
    }

    /// Under flipped gravity an item let go over the table floats up and
    /// away instead of going behind the table.
    @Test func underFlippedGravityAnItemLetGoOverTheTableFloatsAway() {
        let (scene, day) = makeFlippedGravityKitchen()
        defer { withExtendedLifetime(day) {} }

        let node = letGo("emberPepper", atArtPoint: CGPoint(x: 1200, y: 950), in: scene)

        #expect(node.fallingSince != nil)
        #expect(scene.bubbles.contains { $0 === node })
    }

    // MARK: - Play stopping mid-carry

    /// An item in hand 0 at `point` (art points).
    private func held(_ ingredient: String, atArtPoint point: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: ingredient, radius: 80)
        node.position = scene.layout.scenePoint(point)
        node.heldBy = 0
        scene.addChild(node)
        scene.bubbles.append(node)
        scene.hands[0] = KitchenHand(held: node)
        return node
    }

    /// When a marathon round ends mid-carry, the item hangs where it was
    /// while the player picks a card, ready to be grabbed again.
    @Test func whatIsHeldWhenARoundEndsHangsWhereItIs() {
        let (scene, day) = makeKitchenScene()
        let point = CGPoint(x: 683, y: 400)
        let pepper = held(KitchenMenu.pepper, atArtPoint: point, in: scene)
        day.roundEndsAt = 0

        scene.letGoOfEverythingHeld()

        #expect(pepper.isFrozenInAir)
        #expect(pepper.heldBy == nil)
        #expect(pepper.fallingSince == nil)
        #expect(pepper.position == scene.layout.scenePoint(point))
        #expect(scene.bubbles.contains { $0 === pepper })
        #expect(scene.hands.isEmpty)
    }

    /// Any other stop (a pause, the day ending) lets go of it as usual.
    @Test func whatIsHeldWhenPlayStopsOtherwiseIsLetGo() {
        let (scene, day) = makeKitchenScene()
        defer { withExtendedLifetime(day) {} }
        let pepper = held(KitchenMenu.pepper, atArtPoint: CGPoint(x: 683, y: 400), in: scene)

        scene.letGoOfEverythingHeld()

        #expect(!pepper.isFrozenInAir)
        #expect(pepper.fallingSince != nil)
    }

    /// Next round, a frozen item stays put until a hand takes it.
    @Test func aFrozenItemStaysPutOncePlayCarriesOn() {
        let (scene, day) = makeKitchenScene()
        let pepper = held(KitchenMenu.pepper, atArtPoint: CGPoint(x: 683, y: 400), in: scene)
        day.roundEndsAt = 0
        scene.letGoOfEverythingHeld()
        let frozenAt = pepper.position
        day.roundEndsAt = nil

        day.start()
        scene.update(10)
        scene.update(11)

        #expect(day.elapsed > 0)
        #expect(pepper.position == frozenAt)
    }

    /// On 2-1 the first bubble comes in just above the counter and rises,
    /// instead of being lost behind the table the moment it appears.
    @Test func onTheFirstPlanetTwoDayBubblesRiseFromTheCounter() throws {
        let (scene, day) = makeKitchenScene(level: try LevelLoader.load("2-1"))
        let tableEdge = scene.layout.sceneRect(KitchenLayout.window).minY
        scene.update(10)
        day.start()
        scene.update(10.1)
        let bubble = try #require(scene.bubbles.first)
        let startY = bubble.position.y

        for frame in 1...60 { scene.update(10.1 + Double(frame) / 60) }

        #expect(startY > tableEdge)
        #expect(scene.bubbles.contains { $0 === bubble })
        #expect(bubble.position.y > startY)
    }

    /// A bubble rising from the counter is in play, not lost behind the table.
    @Test func underFlippedGravityABubbleAtTheTableEdgeIsNotBehindIt() {
        let (scene, day) = makeFlippedGravityKitchen()
        defer { withExtendedLifetime(day) {} }
        let node = KitchenBubbleNode(ingredient: KitchenMenu.rawFlatbread, radius: 80)
        node.position = CGPoint(x: 400, y: scene.layout.sceneRect(KitchenLayout.window).minY)

        #expect(scene.isOverTable(node) == false)
    }

    /// A falling item that has reached the table carries on down behind it,
    /// and is only gone once it is out of sight.
    @Test func aFallingItemIsGoneOnlyOnceHiddenBehindTheTable() {
        let (scene, day) = makeKitchenScene()
        let node = letGo("duskMushroom", atArtPoint: CGPoint(x: 683, y: 400), in: scene)
        day.start()
        scene.update(10)

        node.position.y = scene.tableEdge
        scene.update(10.02)
        let halfHiddenIsStillThere = scene.bubbles.contains { $0 === node }
        node.position.y = scene.tableEdge - node.radius * 1.5
        scene.update(10.04)

        #expect(halfHiddenIsStillThere)
        #expect(!scene.bubbles.contains { $0 === node })
    }
}
