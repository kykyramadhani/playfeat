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

    @Test func anItemLetGoInMidAirFalls() {
        let scene = makeScene()

        let node = letGo("duskMushroom", atArtPoint: CGPoint(x: 683, y: 400), in: scene)

        #expect(node.fallingSince != nil)
        #expect(scene.bubbles.contains { $0 === node })
    }
}
