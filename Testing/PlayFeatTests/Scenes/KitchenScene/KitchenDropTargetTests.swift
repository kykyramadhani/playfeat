//
//  KitchenDropTargetTests.swift
//  PlayFeatTests
//  Created by kyky on 13/11/26.
//
//  The green glow on the tool a carried item would land on, and loose items
//  being lost once they reach the table. Hands are set up by hand, so no
//  camera is needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenDropTargetTests {

    private func makeScene(ownedPlates: Int = 1) -> (KitchenScene, KitchenDay) {
        makeKitchenScene(ownedPlates: ownedPlates)
    }

    /// Puts `item` in hand 1, at `point` on the art, and lights what it's over.
    private func carry(_ item: String, atArtPoint point: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: item, radius: scene.bubbleRadius)
        node.position = scene.layout.scenePoint(point)
        node.heldBy = 1
        scene.addChild(node)
        scene.bubbles.append(node)
        scene.hands[1] = KitchenHand(held: node)
        scene.updateDropGlows()
        return node
    }

    // MARK: - Glow

    @Test func aToolGlowsWhileACarriedItemIsOverItsHitArea() {
        let (scene, _) = makeScene()

        _ = carry(KitchenMenu.bakedFlatbread, atArtPoint: scene.artRect(of: .plate(0)).center, in: scene)

        #expect(scene.litTargets == [.station(.plate(0))])
    }

    /// With a second plate bought, each plate lights on its own.
    @Test func withTwoPlatesOnlyTheOneUnderTheItemGlows() {
        let (scene, _) = makeScene(ownedPlates: 2)

        _ = carry(KitchenMenu.bakedFlatbread, atArtPoint: scene.artRect(of: .plate(0)).center, in: scene)
        #expect(scene.litTargets == [.station(.plate(0))])

        scene.hands[1]?.held?.position = scene.layout.sceneRect(scene.artRect(of: .plate(1))).center
        scene.updateDropGlows()
        #expect(scene.litTargets == [.station(.plate(1))])
    }

    /// No glow where the item wouldn't be taken: mid-air, or a tool that refuses it.
    @Test func nothingGlowsWhereTheItemWouldNotLand() {
        let (scene, _) = makeScene()

        _ = carry(KitchenMenu.pepper, atArtPoint: CGPoint(x: 683, y: 400), in: scene)
        #expect(scene.litTargets.isEmpty)

        scene.hands[1]?.held?.position = scene.layout.sceneRect(scene.artRect(of: .cooker(.grill, slot: 0))).center
        scene.updateDropGlows()
        #expect(scene.litTargets.isEmpty)
    }

    /// Customers' serve areas stay invisible: a dish there is served, but nothing lights up.
    @Test func aCustomersServeAreaNeverGlows() throws {
        let (scene, day) = makeScene()
        let seat = try #require(day.presentCustomers.first?.seat)

        let dish = carry(KitchenMenu.pepperFlatbread, atArtPoint: KitchenLayout.seats[seat].alien.center, in: scene)

        #expect(scene.dropTarget(for: dish) == .customer(seat: seat))
        #expect(scene.litTargets.isEmpty)
    }

    @Test func theGlowGoesOutOnceTheHandLetsGo() {
        let (scene, _) = makeScene()
        _ = carry(KitchenMenu.bakedFlatbread, atArtPoint: scene.artRect(of: .plate(0)).center, in: scene)

        scene.hands.removeAll()
        scene.updateDropGlows()

        #expect(scene.litTargets.isEmpty)
    }

    // MARK: - The table

    /// A drifting bubble whose bottom reaches the table goes behind it and is lost.
    @Test func aBubbleThatReachesTheTableIsLost() {
        let (scene, day) = makeScene()
        let node = KitchenBubbleNode(ingredient: KitchenMenu.pepper, radius: scene.bubbleRadius)
        let tableEdge = scene.layout.sceneRect(KitchenLayout.window).minY
        node.position = CGPoint(x: 683, y: tableEdge + node.radius + 1)
        scene.addChild(node)
        scene.bubbles.append(node)

        scene.update(10)
        day.start()
        scene.update(10.2)

        #expect(!scene.bubbles.contains { $0 === node })
    }
}
